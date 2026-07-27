# 神獣リーグ — Code Handover Document

**Status**: v1.0 Design Complete → Phase 0 Project Init (2026-07-05)  
**Vision**: 「気軽な5分で本気のチーム戦。神獣の力で自分らしい戦い方を極める」

---

## Quick Reference

| 項目 | 内容 |
|-----|-----|
| ゲーム | 5v5 MOBA（2レーン・5分） |
| スタック | Dart 3.x + Flutter + Riverpod + Firebase |
| Org | `com.petit.works` |
| **優先KR** | Day7 リテンション 40% / Aha Moment（初回1キル） |
| **Phase 優先度** | Phase 6（Aha Moment 最短動線）← 全て優先 |

---

## 実装戦略（Haiku vs Sonnet）

### Haiku の責務（簡単な部分）
1. ステップ1-5：初期設定、データモデル、Service層、計測、ViewModel
2. ステップ7：各画面 View（ロビー・ランク・フレンド）
3. ステップ9：画面遷移・ナビゲーション
4. ステップ13-16：エラーハンドリング、テスト、CI/CD、リリース

### Sonnet の責務（複雑な部分）
1. ステップ6（Phase 6 の複雑なロジック）：Aha Moment への最短動線（バトルエンジン・マッチングロジック）
2. ステップ8：複雑なアニメーション演出（Lottie + Screen Effects）
3. ステップ11：リプレイ生成・シェア機能（Video Encoding）
4. ステップ12：フレンド・ギルド機能（複雑なソーシャル機能）

---

## 実装順序（16ステップ）

```
1. 初期設定 + pubspec.yaml ✅ 完了
2. データモデル定義（Firestore schema） ✅ 完了
3. Service層（認証・DB・課金・API） ✅ 完了（Auth/Firestore/Analytics）
4. 計測3点セット（Analytics/Crashlytics/Remote Config） ✅ 完了（Analytics/Crashlytics実装、Remote Configは未着手）
5. Riverpod ViewModel（User/Matching/Battle） ✅ 完了
6. [★ PHASE 6] Aha Moment への最短動線 ✅ 完了（BattleEngine + Elo + Matchmaking）
7. 各画面View（ロビー・ランク・フレンド等） ✅ 完了（8画面 + go_router）
8. アニメーション・SE/BGM（複雑な部分はSonnet） ✅ 完了（ハプティクス・ネイティブパーティクル演出・SE骨組み）
9. 画面遷移・ナビゲーション ✅ 完了（全ルートにフェード+スライド遷移）
10. ペイウォール（BattlePass・スキンガチャ） ✅ 完了（RevenueCat配線、未設定時は安全にフォールバック）
11. リプレイ生成・シェア ✅ 完了（Wordle方式のテキストシェア）
12. フレンド・ギルド ✅ 完了（Firestoreバックエンド + UI）
13. エラーハンドリング（スケルトンUI・ネットワーク） ✅ 完了（Crashlyticsグローバル捕捉・再試行UI）
14. テスト（unit/widget/integration） ✅ 完了（26件、Widgetテストで重大バグ発見・修正）
15. CI/CD設定（GitHub Actions） ✅ 完了
16. リリース準備（審査対応・段階公開） ⏳ 未着手（機能未完成のため時期尚早）

【Step 16後の追加実装】Mecha選択画面 ✅ 完了（バトル参加者の実ステータス反映）
```

### Step 6 実装内容（2026-07-05, Sonnet実装済み）

**方式**: マルチプレイ専用サーバーは未構築のため、クライアント側の決定論的でないリアルタイムシミュレーションで Aha Moment 導線を成立させている（将来的に専用ゲームサーバー化する場合はこの `BattleEngine` をサーバー側ロジックに移植する）。

- [lib/services/elo_service.dart](lib/services/elo_service.dart) — Elo計算（期待値・レーティング変動）。サーバー側検証は battle/end 相当の処理で別途必須
- [lib/services/matchmaking_service.dart](lib/services/matchmaking_service.dart) — ELO範囲内で実プレイヤーを検索、揃わない場合はBotで即座に埋めてマッチング<30秒を保証。lane自動割当で初心者を救済
- [lib/services/battle_engine_service.dart](lib/services/battle_engine_service.dart) — 1秒ごとのTimer.periodicで交戦を解決。キルイベントは`sync: true`のStreamで即時配信 → Aha Moment（初回1キル）をバトル終了を待たず即検知
- [lib/viewmodels/battle_viewmodel.dart](lib/viewmodels/battle_viewmodel.dart) — `ahaMomentReached`をkillFeed受信と同フレームでtrueにし、Analyticsへ即送信
- [lib/viewmodels/matching_viewmodel.dart](lib/viewmodels/matching_viewmodel.dart) — マッチング状態管理（検索中カウンター・タイムアウト処理）
- [lib/viewmodels/user_viewmodel.dart](lib/viewmodels/user_viewmodel.dart) — 試合結果反映（Elo・勝率・戦績更新）
- [lib/data/providers/service_providers.dart](lib/data/providers/service_providers.dart) — 全体のRiverpod配線
- [test/battle_engine_test.dart](test/battle_engine_test.dart) — Aha Moment即時発火・進化ステータス倍率・勝敗判定・Elo計算の単体テスト（5件、全通過）

**既知のTODO（Step 8以降で解消）**:
- 参加者のBaseStatsが固定値（`mecha_default_01`のダミー値）→ Mecha選択画面実装後にFirestoreから実データ取得
- Remote Config未実装（Aha Moment定義のABテスト・BattlePass価格ABテストは今後）
- windows/linux フォルダは削除済み（対象OSはiOS/Androidのみのため、Google Drive上でのsymlink作成エラー回避も兼ねる）

### Step 7 実装内容（2026-07-05, Sonnet実装済み）

**8画面 + go_router によるナビゲーション構築**:
- [lib/config/app_routes.dart](lib/config/app_routes.dart) — go_router定義。Battle/MatchResult等の複雑なオブジェクトは`extra`パラメータで受け渡し
- [lib/config/theme.dart](lib/config/theme.dart) — 東西神獣テーマのカラーパレット（AppColors）+ ライト/ダーク両対応ThemeData
- [lib/ui/screens/splash_screen.dart](lib/ui/screens/splash_screen.dart) — 認証状態を見てonboarding/lobbyへ自動遷移
- [lib/ui/screens/onboarding_screen.dart](lib/ui/screens/onboarding_screen.dart) — 3ページ説明 → 匿名サインイン → Userドキュメント作成
- [lib/ui/screens/lobby_screen.dart](lib/ui/screens/lobby_screen.dart) — プロフィール表示、クイック/ランクマッチ起動
- [lib/ui/screens/matching_screen.dart](lib/ui/screens/matching_screen.dart) — スケルトンUI + 経過秒数、マッチ成立で自動遷移
- [lib/ui/screens/evolution_select_screen.dart](lib/ui/screens/evolution_select_screen.dart) — 3択進化選択、10秒タイムアウトで自動選択（攻撃）
- [lib/ui/screens/battle_screen.dart](lib/ui/screens/battle_screen.dart) — 2レーン表示、K/D/Aチップ、Aha Momentバナー、キルフィード
- [lib/ui/screens/result_screen.dart](lib/ui/screens/result_screen.dart) — 勝敗・Elo変動表示、UserViewModelへ結果反映
- [lib/ui/screens/rank_screen.dart](lib/ui/screens/rank_screen.dart) — リーダーボード（自分をハイライト）
- [lib/ui/screens/friends_screen.dart](lib/ui/screens/friends_screen.dart) — フレンド/ギルドは今後実装のプレースホルダー（Step 12はSonnet担当）
- [lib/ui/widgets/custom_button.dart](lib/ui/widgets/custom_button.dart) / [loading_skeleton.dart](lib/ui/widgets/loading_skeleton.dart) — 共通ウィジェット（44pt+ボタン、スケルトンUI）

**設計上の重要な修正**: `BattleViewModel.startBattle`を`prepareBattle`（エンジン準備のみ）+`beginCombat`（交戦開始）に分割。進化選択画面でロックしてから交戦を開始することで、進化ステータスが初手ティックから確実に反映されるようにした（試合前進化選択の仕様を正しく実装するための必須修正）。

**テスト安定性の修正**: `BattleEngine`に`Random`注入をサポート（テストでシード固定）。当初のAha Moment単体テストは「最初の交戦イベント全体」を検証していたが、`winChance`が15-85%にクランプされる設計上、1vs1では相手が先に勝つ確率が無視できず不安定だった。「自分が撃破した最初のイベント」を追跡する検証に修正し、5回連続実行で安定を確認。

**未実装（Step 8以降）**:
- Mecha選択画面（現状は固定神獣のみ）

### Step 8 実装内容（2026-07-05, Sonnet実装済み）

**方針**: Lottieの実アセット（.json）・SE/BGMの実音声ファイル（.mp3）はまだ用意できていない（デザイン/音源制作は別工程）。そのため、実アセットが届くまでの代替として **ネイティブFlutterアニメーション** で演出を作り込み、SE再生は **配線だけ先に実装**（アセット未配置時は無音でスキップする安全設計）とした。実アセット追加時は各Serviceのファイルパスを差し替えるだけで済む。

- [lib/services/haptic_service.dart](lib/services/haptic_service.dart) — キル＝軽(lightImpact) / Aha Moment＝mediumImpact / 勝利＝3段パターン / 敗北＝vibrate / ボタン＝selectionClick
- [lib/services/audio_service.dart](lib/services/audio_service.dart) — audioplayers経由のSE再生。`assets/sounds/*.mp3`参照だが**実ファイルは未同梱**、再生失敗は握りつぶしクラッシュしない設計
- [lib/ui/widgets/particle_burst.dart](lib/ui/widgets/particle_burst.dart) — CustomPainterによる放射状パーティクルバースト。`trigger`値の変化で再生（キル演出・勝利のスター爆発に共用）
- [lib/ui/widgets/custom_button.dart](lib/ui/widgets/custom_button.dart) — タップ時に6%スケールダウンするバウンス演出 + ハプティクス + SE再生を追加（既存呼び出し側の変更は不要、API互換）
- [lib/ui/screens/battle_screen.dart](lib/ui/screens/battle_screen.dart) — 自キルで`ParticleBurst`再生+ハプティクス+SE、Aha Moment達成時にバナーがAnimatedSwitcherでフェードイン+ハプティクス+SE
- [lib/ui/screens/result_screen.dart](lib/ui/screens/result_screen.dart) — 勝利時：ゴールドのスター爆発+3段ハプティクス+勝利SE、MVP判定（`playerStats`最高スコア）してChip表示。敗北時：vibrate+敗北SE
- `assets/sounds/`・`assets/animations/`フォルダを作成しpubspec.yamlに登録済み（中身は`.gitkeep`のみ）

**未実装（Step 9以降）**:
- 実際のLottieアニメーションファイル・実音声ファイルの調達/制作（デザイン/サウンド制作の別工程が必要）
- BGM再生（現状SEのみ配線、BGMループ再生は未実装）

### Step 9-15 実装内容（2026-07-06, Sonnet実装済み）

**Step 9（画面遷移）**: [lib/config/app_routes.dart](lib/config/app_routes.dart) 全ルートを`CustomTransitionPage`化し、フェード+わずかな上スライドで統一。

**Step 10（ペイウォール）**: [lib/services/purchases_service.dart](lib/services/purchases_service.dart) — RevenueCat実配線。App Store Connect/Google Play Console側の商品登録・APIキー発行は未実施のため、`AppConfig.revenueCatApiKey`が空の間は課金機能全体を安全に無効化（「現在準備中です」表示、クラッシュしない）。[battlepass_screen.dart](lib/ui/screens/battlepass_screen.dart)（¥500）・[shop_screen.dart](lib/ui/screens/shop_screen.dart)（スキンガチャ¥300、性能差なしを明示）を実装。報酬/スキンカタログは表示用プレースホルダー（実データはFirestore運用投入待ち）。

**Step 11（リプレイ・シェア）**: [lib/services/replay_service.dart](lib/services/replay_service.dart) — 差別化軸「Wordle方式」に準拠し、動画エンコードではなくテキスト要約シェア（`share_plus`）。試合終了直後に自動生成しノーストレスでシェア可能。

**Step 12（フレンド・ギルド）**: FirestoreService拡張（friend_requests/guildsコレクション）+ [friend_viewmodel.dart](lib/viewmodels/friend_viewmodel.dart) / [guild_viewmodel.dart](lib/viewmodels/guild_viewmodel.dart)。ユーザー検索→申請→承認、ギルド作成→簡易掲示板まで実動作。`User.guildId`はcopyWithでnull化できないため`updateUserGuildId()`で直接更新する設計。

**Step 13（エラーハンドリング）**: `firebase_crashlytics`がStep3から依存関係にあったが**一度もグローバルエラー捕捉に配線されていなかった**バグを発見・修正（`main.dart`に`FlutterError.onError`/`PlatformDispatcher.onError`追加）。[error_retry_view.dart](lib/ui/widgets/error_retry_view.dart)を全画面のエラー表示に統一、`ref.invalidate()`で再試行可能に。

**Step 14（テスト拡充）**: `fake_cloud_firestore`導入。MatchmakingService/ReplayServiceの単体テスト、CustomButton/ErrorRetryViewのWidgetテストを追加（計19件）。**この過程で2件の実バグを発見・修正**:
1. **重大**: `CustomButton`の`GestureDetector`が`IgnorePointer`配下の子に依存する`deferToChild`（デフォルト）挙動のため、**アプリ全体であらゆるボタンタップが機能しない**状態だった（Step 8のバウンス演出追加時に混入、`dart analyze`+ロジックテストのみでは検出不可）。`HitTestBehavior.opaque`で修正。
2. `ReplayService`のコンストラクタが`FirestoreService()`（Firebase必須シングルトン）を即座に生成しており、純粋関数のテストがFirebase初期化なしでは実行不可だった。遅延初期化に変更。

**Step 15（CI/CD）**: [.github/workflows/ci.yml](.github/workflows/ci.yml) — push/PR時に`dart format`チェック→`flutter analyze`→`flutter test`を実行。導入前に全コードへ`dart format`を適用済み。

**Step 16（リリース準備）は意図的に未着手**: 実アセット（Lottie/SE/BGM）・実RevenueCat商品登録など、ユーザー向けに完成していない機能が複数残っているため時期尚早と判断。

### Mecha選択画面 実装内容（2026-07-06, Sonnet実装済み）

Step 6以来のTODOだった「参加者のBaseStatsが固定ダミー値」を解消。実Firebaseプロジェクトが未接続のため、Firestoreへ実データを投入する代わりに**コード内静的カタログ**を正とする設計にした（将来Firestore化する際は参照元を差し替えるだけで済む）。

- [lib/data/mecha_catalog.dart](lib/data/mecha_catalog.dart) — 神獣6体（東西×3体、COMMON〜LEGEND）の静的マスタデータ。`mechaById()`は未知IDに対して安全にフォールバック
- [lib/ui/screens/mecha_select_screen.dart](lib/ui/screens/mecha_select_screen.dart) — グリッドで神獣を選択、レアリティ別カラー表示、ステータスプレビュー
- `User.selectedMechaId`を追加し、`UserViewModel.selectMecha()`で永続化
- [lib/services/matchmaking_service.dart](lib/services/matchmaking_service.dart) — 自分は選択中の神獣、Botはカタログからランダムに割当（対戦の多様性向上）
- [lib/viewmodels/battle_viewmodel.dart](lib/viewmodels/battle_viewmodel.dart) — 参加者ごとに`mechaById(mp.mechaId).baseStats`で実ステータスを反映（固定ダミー値のTODOを解消）
- [test/mecha_catalog_test.dart](test/mecha_catalog_test.dart) — カタログのデータ整合性を機械検証（ID重複・不正なrarity/origin・空文字・非正値ステータス）。手動データは目視確認せず必ずスクリプトで検証する方針に準拠

**副次的に発見・修正したバグ**: `User.copyWith()`が`guildId`を明示的に引き継いでおらず、`applyBattleResult`や`updateOwnedSkins`など**あらゆるcopyWith呼び出しでギルド所属情報が意図せずnullにリセットされる**潜在バグがあった（Step 12実装時から存在）。`guildId: guildId`（`this.guildId`を保持）を追加して修正。

### バトル画面2.5D化（2026-07-13, Sonnet実装済み）

ユーザー要望「2.5Dへリアルに」に応え、バトル画面のレーン表示（テキストのキル/デス数リスト）をFlameゲームエンジンによる等角投影バトルフィールドへ置き換え。実キャラクター素材は未着手のため、円+属性アイコン（東=🔥/西=❄）+影で「浮いた」質感を出すプレースホルダー方針（ユーザー選択：Flame導入 + 図形/アイコンで質感表現）。

- [lib/game/isometric_projection.dart](lib/game/isometric_projection.dart) — グリッド座標→スクリーン座標の等角投影変換（`screenX=(gridX-gridY)*tileWidth/2`, `screenY=(gridX+gridY)*tileHeight/2`）
- [lib/game/mecha_token.dart](lib/game/mecha_token.dart) — 参加者1人分のトークン。生死状態を`update()`内でopacity/scaleを補間して滑らかに反映、キル時は白リングフラッシュ演出
- [lib/game/lane_floor.dart](lib/game/lane_floor.dart) — レーン地面を菱形パネルとして描画
- [lib/game/battlefield_game.dart](lib/game/battlefield_game.dart) — `FlameGame`本体。**シミュレーションロジックは一切持たず**、`BattleEngine`から渡された参加者状態を描画するだけのレンダラーに徹する設計（`sync(participants)`で位置確定・生死反映、`onKillEvent()`でキルフラッシュ発火）

**迫力強化の追加実装（2026-07-13同日、1回目）**: ユーザーから「迫力ふやす」と指示があり、キル演出を強化。
- `MechaToken`: キルフラッシュを金色の二重リング+自己スケールパンチに強化、被弾側に赤フラッシュ演出を追加、死亡時に「沈み込む」オフセットを追加（単純なopacity低下から、より物理的な手応えのある表現へ）
- `BattlefieldGame.onKillEvent(attackerId, victimId)`: 引数をvictimId込みに変更し、被弾側トークンへの赤フラッシュ発火 + カメラシェイク（`update()`内でランダムジッターを減衰させながら適用）を追加
- トークンサイズを36→42に拡大、外周グロー（ぼかしストローク）を追加して存在感を強化

**迫力強化の追加実装（2026-07-13同日、2回目）**: ユーザーから再度「より迫力だす」と指示があり、さらに演出をエスカレーション。
- [lib/game/kill_burst.dart](lib/game/kill_burst.dart) — 撃破位置から10本の破片が放射状に飛び散る演出。寿命(0.45秒)が尽きると`removeFromParent()`で自動消滅
- [lib/game/impact_line.dart](lib/game/impact_line.dart) — 攻撃側→被弾側を結ぶ稲妻状の衝撃線。0.18秒で自動消滅
- `MechaToken.triggerHitFlash(knockbackDirection:)` — 被弾方向にノックバック（弾き飛ばされる動き）を追加。ゼロベクトル・null安全
- `BattlefieldGame.onKillEvent()` — カメラシェイクの振幅を8→14に強化、`render()`をオーバーライドして白フラッシュ（画面全体を覆う半透明矩形）を追加。攻撃側・被弾側トークンの位置からKillBurst/ImpactLineを動的に生成
- テスト12件追加（計44件）。KillBurst/ImpactLineは寿命切れ時の`removeFromParent()`が未マウント状態でも例外を投げないことを確認

**リアルな2.5D質感化（2026-07-13同日、3回目）**: ユーザーから「2.5D、リアルに」と指示があり、演出の強度ではなく**トークンと地面の質感**を上げる方向で対応（前回までの派手なエフェクトとは別軸の改善）。
- `MechaToken`: 平坦な単色円 → **球体シェーディング**（左上光源の放射状グラデ light→base→dark）+ リムライト（右下の暗い縁取り）+ ハイライトスポット（光沢）で立体的な玉に。さらに**浮遊ボブ**（生存中は上下にゆっくり揺れる、個体ごとに位相をずらして群れ感）と、本体の高さに応じて薄く・大きくなる**接地影の分離**（影は接地点に固定、本体だけが浮く）を追加。サイズ42→46
- [lib/game/lane_floor.dart](lib/game/lane_floor.dart): 単色菱形 → 奥（暗）から手前（明）への**奥行きグラデーション** + 内部グリッド線（等角マス目でスケール感）+ 縁ハイライト
- `BattlefieldGame.sync()`: トークンに`priority = screenPos.y.round()`を設定し、**奥のトークンを先に描き手前を上に重ねる正しい前後関係**（Y座標による深度ソート）を実現
- 既存44件のテストは全てパスしたまま（質感変更はロジックに影響しないため既存テストで担保）
- [lib/ui/screens/battle_screen.dart](lib/ui/screens/battle_screen.dart) — `ConsumerWidget`→`ConsumerStatefulWidget`化（`BattlefieldGame`インスタンスをbuild間で保持する必要があるため）。テキストベースの`_LaneView`/`_ParticipantRow`は`GameWidget`に置き換えて削除
- テスト: [test/game/isometric_projection_test.dart](test/game/isometric_projection_test.dart)（投影の対称性検証）、[test/game/mecha_token_test.dart](test/game/mecha_token_test.dart)（生死遷移・update/render が例外を投げないことを検証）。実装当時はFirebase未接続のため実機/ブラウザ検証できず、純粋ロジック部分のみ単体テストで代替検証していた（→ 後日Firebase接続完了により解消、下記参照）

### Firebase本設定完了（2026-07-21）

ユーザーがFirebaseコンソールでAndroidアプリを登録し`google-services.json`を提供。**登録パッケージ名がプロジェクトの既存applicationIdと不一致**だったため（`com.petitworksapps.shinjukuleague` vs 旧`com.petit.works.shinjuu_league`、"shinjuku"と"shinjuu"のスペル差異あり）、AskUserQuestionで確認の上、**プロジェクト側のapplicationId/namespaceをFirebase登録済みの値に合わせる**方針で統一。

- `android/app/build.gradle.kts`: `namespace`/`applicationId`を`com.petitworksapps.shinjukuleague`に変更
- `MainActivity.kt`を`android/app/src/main/kotlin/com/petitworksapps/shinjukuleague/`に再配置（パッケージ宣言込み）、旧`com/petit/`ディレクトリは削除
- `android/settings.gradle.kts`に`com.google.gms.google-services`プラグインを追加、`android/app/build.gradle.kts`のpluginsブロックにも適用（**このプラグイン適用が漏れているとgoogle-services.jsonを配置してもFirebaseが初期化されない**ので必須）
- `google-services.json`を`android/app/`に配置（Firebaseプロジェクト`apps2-752cb` — nitesaki/senjoshogiと共有の複数アプリ収容プロジェクト）
- `lib/firebase_options.dart`をプレースホルダーから実データに更新（apiKey/appId/messagingSenderId/projectId/storageBucket）。iOSアプリは未登録のため、iOSビルド時は別途Firebaseコンソールでの登録が必要
- **ブラウザでのスモークテスト実施**: `flutter build web --release`→静的配信でFirebase Core/Firestore/Analytics/Auth/Remote Configの初期化ログを確認、エラーなし、Flutterエンジンも正常にアタッチ（`flt-glass-pane`確認）。**ただしスクリーンショット取得ツール自体がタイムアウトし、実際のピクセル単位の見た目は依然未確認**（環境側のCanvasKit/WebGLキャプチャ制約の可能性、アプリ側の不具合ではない）
- `.claude/launch.json`に`shinjuu-league-web`（ポート8772、`build2/web`を配信）を追加

**技術的判断**: Flameの`GameWidget`はウィジェット再構築のたびに再生成すると状態が失われるため、`BattleScreen`をStatefulにして`BattlefieldGame`インスタンスを保持。カメラは`onGameResize`でウィジェットサイズに応じて動的にズーム調整し、画面サイズが変わっても両レーンが収まるようにしている。

### APKビルド + ジョイスティック操作（Pokémon UNITE風）実装（2026-07-21）

**APKビルド**: 実機確認のため`build-flutter-apk`スキルでビルド。このホストは物理RAM約4GBしかなく、初期状態のGradleデーモン設定（`-Xmx8G`）ではOOMクラッシュした。`android/gradle.properties`のJVMヒープを`-Xmx1536M`に縮小して解決（**このホスト固有の制約**、他の潤沢なマシンでは元の設定で問題ない可能性が高い）。desugar/minSdk設定もこの機会に追加（`build-flutter-apk`スキルの前提条件）。実機テストは、このセッションが物理USB接続を持たないクラウド環境のため`adb`実行自体が不可能（`STATUS_DLL_NOT_FOUND`）と判明 → ユーザー自身の端末での確認に切り替え。

**ゲーム性リッチ化「ポケモンユナイトのようなゲーム感」（AskUserQuestionで実装規模を確認 → 最大規模の「プレイヤーがJoystickでキャラを直接操作」を選択）**:

現状のバトルは1秒毎の自動シミュレーション（`BattleEngine.tick()`）のみで、プレイヤーが戦闘中に操作できる要素がゼロだった。これに対し、既存の「BattlefieldGameは描画専用、シミュレーションロジックを持たない」設計原則を維持しつつ、**自キャラのみ**フリー移動できる層を追加：

- [lib/game/battlefield_game.dart](lib/game/battlefield_game.dart): Flame標準の`JoystickComponent`を`camera.viewport`（HUD空間、カメラシェイクの影響を受けない）に追加。自トークンのみ`update()`毎フレームでジョイスティック入力方向に移動（速度90px/秒、プレイフィールド範囲内にクランプ）。移動に応じて`priority`（描画順）もリアルタイム更新。射程46px以内の最も近い敵（別チーム・生存中のみ）を`ValueNotifier<String?> attackTargetId`で公開
- [lib/services/battle_engine_service.dart](lib/services/battle_engine_service.dart): `manualDuel(attackerId, victimId)`を追加。範囲判定はUI層が担当し、ここではチーム・生死のみ検証して既存の`_resolveDuel`（自動交戦と同じロジック）を再利用 — 勝敗ロジックを二重管理しない設計
- [lib/viewmodels/battle_viewmodel.dart](lib/viewmodels/battle_viewmodel.dart): `attemptManualAttack(targetUserId)`を追加。900msのクールダウンで連打を防止。`manualDuel`が発火する`CombatEvent`は既存の`_onCombatEvent`パイプラインにそのまま乗るため、**キルフラッシュ・ハプティクス・SE・カメラシェイク・パーティクル等の演出は追加配線なしで手動攻撃にもそのまま適用される**（自動交戦と手動攻撃でイベント発火経路が共通なため）
- [lib/ui/screens/battle_screen.dart](lib/ui/screens/battle_screen.dart): `GameWidget`をStackで包み、右下に攻撃ボタン（`ValueListenableBuilder`で射程内判定に応じて有効/無効・光彩演出）を追加

テスト: `battle_engine_test.dart`に`manualDuel`のテスト4件（成功/同チーム拒否/不正ID/死亡対象拒否）、`test/game/battlefield_game_test.dart`を新規作成し攻撃対象検出の挙動を3件検証（味方は距離が近くても対象外になることを確認 — チームフィルタが実際に効いていることの証明）。計51件全通過。

### ゲーム性さらにリッチ化（2026-07-21同日、4項目一括実装）

ユーザーから「ポケモンユナイトのようなゲーム感」を再度指示され、実機で確認したが「さらに要素を追加したい」との回答。AskUserQuestion（複数選択）で4項目を確認：①スキル発動（クールタイム付き範囲攻撃）②マップ全体を自由に歩き回れるようにする③味方/BotもAI移動④HPを削っていくタイプにする。全て選択されたため一括実装。

**設計方針**: 前回実装した「BattlefieldGameは描画専用、BattleEngineが唯一のシミュレーション正」という原則を維持しつつ、④（HP削り）だけは自動交戦（`_resolveEngagements`）自体の内部ロジック変更が必要だったため、既存47件のテストへの影響を精査しながら慎重に置き換えた。

- **HP削り合い（既存の即死コインフリップを廃止）**: `BattleParticipantState.currentHp`を追加（構築時に`effectiveHp`で初期化、進化ロック時・リスポーン時に再充填）。`_resolveDuel`（勝敗確率で即死）を`_applyDamage` + `_computeDamage`（素早さによる被弾軽減付き）に置き換え、**自動交戦・手動攻撃・スキル発動すべてが同じダメージ計算を共有**。撃破に至らない被弾は新設の`hitEvents`ストリームでのみ通知し、`killFeed`/Aha Momentには影響させない設計。既存のAha Momentテスト（atk=9999で即死級ダメージを与える設計だったため、新ダメージ式でも実質的に一撃圏内に収まり）は無改修で通過
- **プレイフィールド拡張**: `_playfieldHalfWidth/Height`を230/140→900/560に拡大。[lib/game/open_field.dart](lib/game/open_field.dart)を新設し、レーン外が真っ暗な虚空に見えないよう単色の地面プレートを追加。カメラはマップ全体を映す固定ズームから**自キャラに追従する方式**に変更（`_cameraFollowPos`を`update()`毎フレームでlerp）
- **味方/BotのAI移動（視覚レイヤーのみ）**: `_updateBotWander()`で各Bot/味方トークンが1.5秒毎に最寄りの生存中の敵を再探索し、緩やかに近づく（速度22px/秒、自キャラの90px/秒より控えめ）。**BattleEngineの撃破判定・勝敗ロジックには一切影響しない**、純粋な描画位置更新
- **スキル発動**: [lib/game/skill_burst.dart](lib/game/skill_burst.dart)（拡大するリング演出）を新設。`BattleEngine.manualSkill(attackerId, targetIdsInRange)`で範囲内の敵全員に通常攻撃の2.2倍ダメージ。`BattlefieldGame.enemiesWithinSkillRadius()`（半径90px）で対象を都度計算。UIはクールタイム6秒のスキルボタンを攻撃ボタンの隣に追加（ローカルの`ValueNotifier<bool>`でクールダウン管理、サーバー側はBattleViewModelの`isSkillOnCooldown`で二重に強制）

テスト追加: HPダメージ蓄積の専用テスト3件（弱攻撃は一撃で倒せない/累積で撃破しcombatEvents発火/リスポーンでHP全回復）。リスポーンテストでは自動交戦との干渉を避けるため`_participant()`ヘルパーに`lane`パラメータを追加し、self/enemyを異なるレーンに配置して決定性を確保。**計54件全通過**。

### バグ調査 + 修正（2026-07-21同日）

ユーザーから「バグ調査」の指示。まず手動でコードレビューし2件（リスポーン位置未リセット、射程判定の等角投影歪み）を発見・報告。ユーザーから「修正、さらに全体バグ調査」の指示があり、上記2件を修正した上でExploreエージェントに全体バグ調査を依頼し、追加で2件（高優先度: 手動攻撃/スキルのレーン判定欠落、中優先度: 進化選択画面のレースコンディション）を発見・修正。

**修正1: リスポーン時に位置がリセットされない**
- `MechaToken`に`spawnPosition`（出撃時の固定位置）を追加
- `BattlefieldGame.sync()`で`isAlive`が false→true に遷移した瞬間を検知し、`token.position`を`spawnPosition`へ戻す（Bot徘徊の目標もクリア）。これがないと死んだ場所（敵陣のど真ん中等）でそのまま復活してしまっていた

**修正2: 射程判定が等角投影の歪んだ楕円になっていた**
- [lib/game/isometric_projection.dart](lib/game/isometric_projection.dart)に`toGrid()`（`toScreen()`の逆変換）を追加。tileWidth(96)とtileHeight(48)の比率が2:1のため、画面座標上の円形距離判定は実際のグリッド空間では2:1の楕円に歪んでいた（特異値分解で確認: 67.88/33.94の2:1比）
- `BattlefieldGame`の`_findNearestAliveEnemy`/`_updateAttackTarget`/`enemiesWithinSkillRadius`をすべて`_gridDistance()`（グリッド空間での真の距離）ベースに変更。攻撃射程=1.0グリッド単位、スキル半径=2.0グリッド単位で再定義

**修正3（高優先度・Explore調査で発見）: 手動攻撃/スキルにレーン判定が皆無で2レーン制設計が崩れていた**
- 自動交戦`_resolveEngagements()`は`p.lane == lane`で厳密にレーンごとに交戦相手を絞っているのに対し、`manualDuel`/`manualSkill`はチームチェックのみでレーン一致を検証していなかった。マップ全体を自由に歩き回れる機能により、反対レーンまで歩けば本来交戦してはいけない敵を直接キルできる実害あるバグだった
- `BattleEngine.manualDuel`/`manualSkill`に`attacker.lane != victim.lane`のチェックを追加（サーバー側/エンジン側の防御）
- `MechaToken`に`lane`フィールドを追加し、`BattlefieldGame`の対象検出（`_findNearestAliveEnemy`/`enemiesWithinSkillRadius`）にも`lane`一致条件を追加（UI側の防御、二重の安全策）
- 副次効果: Bot徘徊AIも`_findNearestAliveEnemy`を共有しているため、この修正で「Botがレーンを無視して反対側まで歩いていく」不自然な挙動も同時に解消

**修正4（中優先度・Explore調査で発見）: 進化選択画面の非同期初期化とカウントダウンのレースコンディション**
- [lib/ui/screens/evolution_select_screen.dart](lib/ui/screens/evolution_select_screen.dart): `_countdownTimer`は`initState()`で同期的に即座に開始される一方、`prepareBattle()`（engineをセットする処理）は`addPostFrameCallback`で1フレーム遅延実行されていた。ごく短いタイミングで進化カードをタップすると`state.engine`がまだnullで`lockEvolution`/`beginCombat`が無言でno-opし、その後engineが用意されても二度と`start()`が呼ばれず**試合が永久に進行しない**状態になり得た
- `Completer<void> _prepareCompleter`を追加し、`_select()`が`lockEvolution`/`beginCombat`を呼ぶ前に必ず`_prepareCompleter.future`を待つよう変更。これでタイミングに依存せず安全に

テスト追加: レーン判定のテスト4件（manualDuel/manualSkil双方でレーン不一致を拒否することを検証）、`toGrid()`の往復変換・歪み検証テスト2件、BattlefieldGame層のレーン除外テスト1件。既存のリスポーンHP全回復テストは`manualDuel`経由の撃破がレーン判定で不発になったため、死亡状態を直接構築する方式に修正。**計62件全通過**。

---

## Project Structure

```
shinjuu-league/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   ├── app_config.dart       # App constants
│   │   ├── app_routes.dart       # GoRouter setup
│   │   └── theme.dart            # Color/Typography
│   ├── data/
│   │   ├── models/               # Data classes (freezed/json_serializable)
│   │   │   ├── user_model.dart
│   │   │   ├── mecha_model.dart
│   │   │   ├── battle_model.dart
│   │   │   ├── evolution_model.dart
│   │   │   └── replay_model.dart
│   │   └── providers/            # Riverpod data providers
│   │       └── firebase_provider.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── purchases_service.dart
│   │   ├── analytics_service.dart
│   │   └── api_service.dart
│   ├── viewmodels/
│   │   ├── user_viewmodel.dart
│   │   ├── matching_viewmodel.dart
│   │   ├── battle_viewmodel.dart
│   │   └── replay_viewmodel.dart
│   └── ui/
│       ├── screens/
│       │   ├── onboarding_screen.dart
│       │   ├── lobby_screen.dart
│       │   ├── matching_screen.dart
│       │   ├── evolution_select_screen.dart
│       │   ├── battle_screen.dart
│       │   ├── result_screen.dart
│       │   ├── rank_screen.dart
│       │   └── friends_screen.dart
│       └── widgets/
│           ├── custom_button.dart
│           ├── battle_ui_widget.dart
│           └── loading_skeleton.dart
├── test/
├── android/
├── ios/
├── pubspec.yaml ✅
└── CLAUDE.md (this file)
```

---

## 重点チェック項目

### Vision 直結
- ✅ **Aha Moment（初回1キル）は最優先実装**
- ✅ 試合前進化選択の UI/UX は丁寧に
- ✅ リプレイ自動生成 → SNSシェア までノーストレス

### 公平性
- ✅ スキンのみ課金（性能格差なし）
- ✅ ロール自動割当で初心者も競争可能
- ✅ Elo計算は透明性高く

### パフォーマンス
- ✅ バトル中 60fps 維持
- ✅ マッチング < 30秒
- ✅ リプレイ動画圧縮・ストリーミング

### UI/UXクオリティ
- ✅ キル演出: Lottie + Screen Effects
- ✅ リザルト: スター爆発 + MVP表示
- ✅ ボタン: 44pt + バウンス + SE
- ✅ ハプティクス: キル＝軽 / 勝利＝パターン
- ✅ ダークモード対応必須
- ✅ スケルトンUI（マッチング中）

### セキュリティ
- ✅ Elo改ざん防止（サーバー側検証）
- ✅ API キー環境変数
- ✅ JWT トークン Keychain 保管

---

## KPI イベント（5個・最重要）

| イベント | 定義 | 対応KR |
|---------|------|--------|
| `aha_moment_reached` | 初回で1キル達成 | Day7 リテンション |
| `first_ranked_entry` | ランク戦進出 | Activation |
| `battle_win_streak` | 連勝数 | Day1/7/30 |
| `battlepass_purchased` | ¥500課金 | コンバージョン |
| `skin_purchased` | スキンガチャ課金 | LTV |

### Firebaseイベント仕込み
Step 4（計測3点セット）で以下を設定：
- Analytics イベント（5個）
- Remote Config（Aha Moment定義・ABテスト）
- Crashlytics 自動統合

---

## Firebase Setup（簡単な部分のみ）

### 1. Environment Variables
```bash
# .env.local (Gitignore)
FIREBASE_PROJECT_ID=shinjuu-league-xxxxx
FIREBASE_API_KEY=AIzaSy...
FIREBASE_APP_ID=1:123456:android:...
```

### 2. Firestore Security Rules
- ユーザー認証 → own data only
- Elo改ざん防止：write は Cloud Functions のみ
- リプレイシェア：public read (replay_id)

### 3. Firebase Console Tasks
- [🔴 Sonnet待ち] Authentication Methods (Email/Anonymous/Google)
- [🔴 Sonnet待ち] Firestore Database Setup
- [🔴 Sonnet待ち] Remote Config Values
- [🔴 Sonnet待ち] Analytics Event Tracking

---

## 開発ルール

### Git Workflow
```bash
git init
git add .
git commit -m "🎮 Initial Flutter setup: pubspec + project structure"
```

### Haiku の実装チェックリスト
- [ ] ステップ1-2：モデル定義（freezed）
- [ ] ステップ3-4：Service + Analytics
- [ ] ステップ5：ViewModel（Riverpod）
- [ ] ステップ7-9：UI + Navigation
- [ ] ステップ13-16：Test + CI/CD

### Sonnet に委譲するタイミング
- ステップ6 開始前に Sonnet に「複雑なバトルロジック・マッチング」を説明
- ステップ8/11/12 で複雑なアニメ・リプレイ・ソーシャル機能を統合

---

## Tips

### Firebase Local Emulator
```bash
firebase emulators:start --only firestore,auth
# test 実行時に使用
```

### Riverpod Codegen
```bash
dart run build_runner watch
```

### Lottie Asset Path
```
assets/animations/
├── kill_burst.json
├── win_celebration.json
└── level_up.json
```

---

## 次のステップ

1. **Haiku**: ステップ2-5 実装開始（データモデル → Service → ViewModel）
2. **Sonnet**: ステップ6（Aha Moment バトルロジック・マッチング）を設計・実装
3. 並行：ステップ7（各画面View）を UI テンプレートで Haiku 先行実装
4. 統合：ステップ8-12 で複雑な部分を Sonnet と協働

---

## 参考リンク

- [Design Document](https://...) ← 別途リンク予定
- [API Spec](https://...) ← 別途リンク予定
- [Firebase Console](https://console.firebase.google.com/) ← プロジェクト作成後
- [Riverpod Docs](https://riverpod.dev)
- [Flutter Docs](https://flutter.dev)
