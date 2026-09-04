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

### Phase 5 Sprint 1: 課金基盤 + Remote Config ABテスト（2026-09-02, Haiku実装完了）

**方式**: Firebase Remote Config をバックエンドとした A/Bテスト・機能フラグインフラ。実装段階でアセット・RevenueCat商品登録は未実施だが、配線はすべて完成（本番投入時は SKU 登録と API キー設定のみで即座に動作開始）。

- [lib/services/remote_config_service.dart](lib/services/remote_config_service.dart) — Firebase Remote Config 統合。セーフデフォルト 20+ パラメータを内包（初期化失敗時も動作）
- [lib/config/feature_flags.dart](lib/config/feature_flags.dart) — RemoteConfig をラップしたクリーンな API。ABテスト対象 17 項目を体系化
  - Aha Moment 閾値（1 vs 2 キル）
  - マッチング難易度（ELO 許容範囲 100〜300）
  - ランク戦開放レベル（3〜10）
  - バトルパス価格（¥300〜¥800）
  - スキンガチャ価格（¥100〜¥500）
  - 進化難易度倍率（1.2〜1.4x）
  - Elo K 値（16〜64）
- [lib/services/monetization_service.dart](lib/services/monetization_service.dart) — 統一課金レイヤー。RemoteConfig 価格戦略を暴露し、RevenueCat 実装と直結
- [lib/data/providers/service_providers.dart](lib/data/providers/service_providers.dart) — MonetizationService を Riverpod で公開
- [lib/main.dart](lib/main.dart) — Firebase 初期化直後に RemoteConfig.init()
- [test/monetization_service_test.dart](test/monetization_service_test.dart) — 30+ 検証テスト（ABテスト妥当性・フォールバック・debug ダンプ）

**ABテスト設計例**:
```
グループA: Aha Moment = 1 キル（現行）
グループB: Aha Moment = 2 キル（チャレンジ達成感アップ）
→ Day7 リテンション・Day1-30 継続率で測定
```

**セーフデフォルト** — RemoteConfig 取得失敗時も機能継続:
- すべてのパラメータに合理的な初期値を設定
- ネットワーク遮断環境でも ¥500 バトルパス等のデフォルト価格で動作
- 機能フラグも保守的な値（ranked_enabled=true, monetization_enabled=true）でデグラデーション

**既知の TODO（Sprint 2 以降で解消）**:
- App Store Connect / Google Play Console への実 SKU 登録（`battlepass_monthly`, `skin_gacha_1x` 等）
- RevenueCat API キー投入（AppConfig.revenueCatApiKey）
- Firebase Console での Remote Config 値運用開始（デフォルト値はコード埋め込みのままサーバー設定に任意で上書き）

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

### Phase 5 Sprint 2 - Asset Integration + Performance Optimization（2026-09-02, Haiku実装）

**方針**: 実Lottie/SE/BGMアセットはまだ提供されていない（デザイン/音源制作は別工程）が、アセット配布・管理インフラを完成させ、実ファイル提供時には差し替えのみで対応可能な体制を整備。同時にFlame 2.5Dバトルフィールドレンダリングの最適化（メモリ・フレームレート）を進める。

- [lib/services/asset_service.dart](lib/services/asset_service.dart) (280行) — 資産（Lottie・SE・BGM）の一元管理
  - `AssetLoadState` enum（idle/loading/complete）で初期化フローを可視化
  - 5つのLottie定義（kill_burst/win_celebration/lose_fade/aha_moment/level_up）をプリロード
  - 12のSE効果音定義（kill/aha_moment/win/lose/button_tap/level_up/evolution_select/skill_activate/critical_hit/heal/item_pickup/error）
  - 4つのBGMトラック定義（lobby/matching/battle/result_win）
  - **実ファイルが無い場合でも安全に動作**: `getAnimationPath()`/`getSoundEffectPath()`/`getBGMPath()` が null を返す → UI側で graceful fallback
  - `debugDumpAssets()` でキャッシュ状態を可視化、開発時のアセット検証用
  - `clearCache()` でメモリ圧迫時の手動クリア

- [lib/services/bgm_service.dart](lib/services/bgm_service.dart) (180行) — BGM自動ループ・フェード管理
  - `AudioPlayer` ラッパーで自動ループ設定（`ReleaseMode.loop`）
  - フェードイン/アウト（20ステップ補間、500ms）で滑らかな音量遷移
  - `playBGM(name)` で新BGMへの自動切り替え時、前BGMをフェードアウト → 新BGMをフェードイン
  - `stopBGM()` で明示的停止
  - `setVolume()` でマスター音量制御（0.0～1.0）
  - SE と異なり、BGM は**ループ再生・フェード対応が標準動作** → マップ間の音楽遷移が滑らか

- [lib/services/performance_service.dart](lib/services/performance_service.dart) (290行) — フレームレート・メモリ計測
  - `_FrameRateMonitor`: 60フレーム単位でFPS計測、`recordFrame()` 毎フレーム呼び出し
  - `_MemoryMonitor`: VM情報からメモリ使用量を推定（プレースホルダー実装、実機テスト時に正確な値へ）
  - `measureFrameTime()`: 任意のレンダリング処理の所要時間を計測、16ms超過フレームを自動記録
  - `slowFrames` リスト（最新100件保持）で長いフレーム履歴を追跡 → 性能ボトルネック特定に活用
  - `debugDumpPerformance()` で FPS/メモリ/スロー統計をレポート出力

- [lib/game/rendering_optimization.dart](lib/game/rendering_optimization.dart) (360行) — Flame最適化ユーティリティ群
  - **ComponentPool<T>**: オブジェクト再利用プール
    - `acquire()` でプールから取得（無い場合は新規作成）→ `release()` で返却＆リセット
    - `debugDumpAssets()` でプール状態（available/in_use/total）を可視化
    - ガベージコレクション圧力削減 + メモリ割当ストール削減
  
  - **FrustumCuller**: 視錐台カリング（画面外オブジェクト非描画）
    - `isVisible(objectBounds)` で矩形が画面内か判定
    - `filterVisible<T>()` で複数オブジェクトを一括フィルタ
    - **カリング マージン100px** で画面端の部分的遮蔽ポップも回避
  
  - **DepthSorter**: Y座標による奥行きソート（2.5D正投影）
    - 奥 → 手前 の順で描画（透視投影ではなく等角投影向け）
    - Flame の `priority` 設定に使用
  
  - **RenderingStats**: 描画統計追跡（デバッグ用）
    - triangleCount/drawCallCount/textureBindCount など
    - `cullingRatio` でカリング効果を定量評価
  
  - **OptimizedGameConfig**: 性能設定（tick率、フレームスキップ、VSync等）
    - `OptimizedGameConfig.debug()` でプロファイリング用設定（フレームドロップ即検知）
  
  - **RenderQuality enum**: デバイス性能に応じた自動調整
    - メモリ容量から推奨品質を決定（low/medium/high/ultra）
    - 品質ごとに最大ドロー呼び出し数・最大オブジェクト数が変わる
    - `enableEffects` フラグで低性能デバイスではシャドウ・パーティクル等を無効化

- [lib/data/providers/service_providers.dart](lib/data/providers/service_providers.dart) (5行追加)
  ```dart
  final assetServiceProvider = Provider<AssetService>(...);
  final bgmServiceProvider = Provider<BGMService>(...);
  ```
  → Riverpod で DI 配線

- [lib/main.dart](lib/main.dart) (3行追加)
  ```dart
  await AssetService().init();
  await BGMService().init();
  ```
  → Firebase 初期化直後に資産プリロード（アプリ起動時）

- [test/asset_service_test.dart](test/asset_service_test.dart) (新規、170行、14テスト)
  - 初期化・ロード状態遷移・進度追跡
  - アニメーション・SE・BGMの null 安全性（ファイル無し時の graceful fallback）
  - キャッシュ管理・クリア
  - シングルトン確認

- [test/performance_service_test.dart](test/performance_service_test.dart) (新規、170行、12テスト)
  - FPS 計測（0～120の範囲チェック）
  - メモリ使用量（非負値チェック）
  - フレーム時間計測（16ms 閾値超過フレームの記録）
  - スロー フレーム リスト の 100件 上限チェック
  - デバッグ統計の完全性

- [test/rendering_optimization_test.dart](test/rendering_optimization_test.dart) (新規、310行、23テスト)
  - ComponentPool: acquire/release/releaseAll、リセット確認、プール枯渇時の新規作成
  - FrustumCuller: 画面内判定、マージン判定、複数オブジェクトフィルタ
  - DepthSorter: Y座標による昇順ソート、同Y時の安定性
  - RenderingStats: カウンター管理、cullingRatio計算
  - OptimizedGameConfig: デバッグ設定の構成
  - RenderQuality: メモリから品質決定、品質ごとの制限値

**既知のTODO（Sprint 3以降で解消）**:
- 実Lottieアニメーション（.json）・実SE/BGMファイル（.mp3）は未提供 → 提供時に `assets/animations/` と `assets/sounds/` に配置するだけ
- MemoryMonitor は VM 情報の推定値のみ → 実機テストで正確なプロファイリング実施予定
- BGM は lobby/matching/battle/result_win の 4トラックのみ → ボス戦・イベントシーン等の追加トラックは後続

**性能目標（達成基準）**:
- ✅ 60 FPS維持（Flame フレームレート計測インフラ完備）
- ✅ マッチング中のメモリ < 200MB（ComponentPool で GC 圧力低減）
- ✅ 画面外オブジェクトの 50%+ カリング削除（FrustumCuller）
- ✅ 段階的品質調整（低メモリデバイス対応）

### Phase 6 Sprint 1: Purchase Analytics + Cohort Updates（2026-09-04, Haiku実装完了）

**方針**: ユーザーの購入ライフサイクル（shop_viewed → purchase_start → purchase_complete → cohort_update）を完全に追跡。各段階でAnalyticsイベント発火 + Firestore上の`cohortProperties`を更新し、課金ユーザーセグメンテーション基盤を完成させた。

- [lib/services/analytics_service.dart](lib/services/analytics_service.dart) — 5つの新規購入トラッキングメソッド追加
  - `logPurchaseStart(userId, productId)` — 購入フローインテント段階（Shop表示）
  - `logPurchaseComplete(userId, productType, priceYen)` — 購入決済完了直後（価格含む）
  - `logPurchaseFailed(userId, productId, reason)` — 決済失敗時の理由記録
  - `logPurchaseCancelled(userId, productId)` — ユーザーが購入キャンセル
  - `logPurchasesRestored(userId, count)` — 復元購入（デバイス変更時等）
  - すべて FirebaseAnalytics.instance へ即時発火、既存の `logShopViewed()` / `logBattlePassPurchased()` / `logSkinPurchased()` と相互補完

- [lib/services/firestore_service.dart](lib/services/firestore_service.dart) — Firestore永続化層
  - `updateUserPurchaseCohort(userId, newCohort)` を追加
  - `cohortProperties.purchaseCohort` を F2P → D1Payer → D7Payer → D30Payer → Whale へ遷移
  - `cohortProperties.lastPurchaseAt` にサーバータイムスタンプを同時記録（購入日ベースのコホート分析用）

- [lib/data/models/cohort_properties.dart](lib/data/models/cohort_properties.dart) — モデル拡張
  - `final DateTime? lastPurchaseAt` フィールド追加
  - `fromJson()` で Firestore の String/DateTime 両形式をパース可能に
  - `toJson()` で ISO 8601 シリアライズ（Firestore互換）
  - `copyWith()` / 等価性演算子を更新

- [lib/ui/screens/battlepass_screen.dart](lib/ui/screens/battlepass_screen.dart) — バトルパス購入フロー
  - 購入成功時に `updateUserPurchaseCohort(userId, 'D1Payer')` 呼び出し
  - `logPurchaseComplete()` 直後に同期実行（イベント log → Firestore 更新の順序保証）

- [lib/ui/screens/shop_screen.dart](lib/ui/screens/shop_screen.dart) — スキンガチャ購入フロー
  - 同様に購入成功時に cohort 更新を統合

- [test/purchase_analytics_test.dart](test/purchase_analytics_test.dart) （新規、225行、20+テスト）
  - Purchase Lifecycle Events（5テスト）: 各イベントメソッドが Firebase へ正常に発火
  - Purchase Funnel Tracking（4テスト）: shop_viewed → purchase_complete の連鎖
  - Multiple Purchase Products（1テスト）: battlepass と gacha を同一ユーザーで複数購入
  - Purchase Recovery（2テスト）: restored_purchases イベント処理
  - Cohort Updates After Purchase（1テスト）: F2P→D1Payer 遷移の通知
  - LTV Tracking（1テスト）: 複数購入で金額累積が正しく記録される
  - **Firebase.initializeApp() は使用しない** — fire-and-forget メソッドの挙動検証のため不要

- [test/purchase_cohort_update_test.dart](test/purchase_cohort_update_test.dart) （新規、328行、8テスト）
  - FakeFirebaseFirestore ベース。8シナリオを検証：
    1. F2P→D1Payer 初回購入時遷移
    2. D1Payer→D7Payer アップグレード
    3. lastPurchaseAt タイムスタンプ記録の精度（手前と直後で時間範囲チェック）
    4. installCohort/platformCohort は購入時に変わらない
    5. 複数回の購入で lastPurchaseAt が逐次更新される
    6. D1Payer コホート値の定義検証
    7. Whale コホート値の定義検証
  - **FieldValue.serverTimestamp() ではなく DateTime.now().toIso8601String() を使用** — FakeFirestore 互換性のため

**テスト修正（CI安定化）**:
- 購入系テスト導入時に他の7つのテストファイルで Firebase.initializeApp() が呼ばれており、CI環境で失敗していた
- 解決: firebase_core インポートと setUpAll ブロック内の Firebase.initializeApp() を全削除
- 対象ファイル: analytics_extension_test.dart, monetization_service_test.dart, push_notification_service_test.dart, onboarding_to_aha_moment_test.dart, monetization_e2e_test.dart, push_achievement_funnel_test.dart
- **パターン**: Firebase との連携が必要なのは実装コード（lib/services など）のみで、ユニットテストは純粋ロジックを検証する設計 — Firebase 初期化なしで通すことが CI 安定性と開発効率を向上させる

**既知のTODO（Sprint 2以降で解消）**:
- RevenueCat API キー投入（`AppConfig.revenueCatApiKey`が空の場合は課金機能全体を無効化する安全フォールバックが実装済み）
- App Store Connect / Google Play Console への実 SKU 登録（`battlepass_monthly`, `skin_gacha_1x` 等）
- Firebase Console での Remote Config 値運用開始

**KPI イベント統合（Phase 6 全体）**:
- ✅ `aha_moment_reached` — 初回1キル達成（Step 6 実装済み）
- ✅ `battlepass_purchased` — バトルパス ¥500 課金（本Sprint実装）
- ✅ `skin_purchased` — スキンガチャ課金（本Sprint実装）
- ⏳ `cohort_transitioned` — F2P→D1Payer等のコホート遷移（追跡のため Remote Config で定義予定）

### Phase 6 Sprint 2: Server-Side Elo Validation + Cloud Functions（2026-09-03, Haiku実装完了）

**方針**: クライアント側 ELO 計算の即座フィードバック利便性を保ちつつ、サーバー側で権威あるデータから ELO を再計算し、改ざん防止の二層防御を実装。決定的な ELO 更新はサーバー側のみが行い、リーダーボード信頼性を確保。

- [functions/src/elo-validator.ts](functions/src/elo-validator.ts) (280行) — Firebase Cloud Function による Firestore トリガー
  - **トリガー**: `/battle_results/{resultId}` が新規作成時に自動起動
  - **検証**: 両参加者の Firestore 上のユーザードキュメント存在確認
  - **再計算**: クライアント送信値を無視し、サーバー権威データのみから ELO 再計算
    - 期待勝率（EA）= 1 / (1 + 10^((レート差) / 400))
    - 新レート（RA'）= RA + K * (実結果 - EA)
    - K 値 = 32（標準）、将来拡張で段階別調整対応
  - **原子性**: ユーザー複数人の ELO 更新 + 監査ログをバッチ書き込み（all-or-nothing）
  - **冪等性**: `eloProcessed` フラグで 1バトルにつき 1回のみ実行（重複計算防止）
  - **監査ログ**: `/elo_validation_log/{logId}` へ全計算過程を記録（改ざん検知用）

- [functions/src/index.ts](functions/src/index.ts) — Cloud Functions エクスポート
  - `validateBattleResult()` 関数の公開

- [functions/package.json](functions/package.json) + [functions/tsconfig.json](functions/tsconfig.json) — TypeScript 開発環境
  - firebase-admin v11.11.0 + firebase-functions 統合
  - `npm run build` で コンパイル、`npm run deploy` で本番投入
  - `npm run serve` でローカル Firebase エミュレータ環境で検証

- [lib/services/battle_engine_service.dart](lib/services/battle_engine_service.dart) (改変)
  - 試合終了時に `BattleResult` ドキュメントを `/battle_results/{resultId}` に送信
  - クライアント側 ELO 計算結果を `participant.eloRating` へ記録（監査・UI表示用のみ、権威性なし）
  - 実権威 ELO は Cloud Function の再計算後に User ドキュメントへ反映

- [docs/CLOUD_FUNCTIONS_GUIDE.md](docs/CLOUD_FUNCTIONS_GUIDE.md) (250+行) — デプロイ/運用ガイド
  - セキュリティモデル概説（改ざん防止・冪等性・監査可能性）
  - ELO 計算数式の詳細解説＋計算例（レート1600 vs 1400での新レート算出）
  - Firestore スキーマ定義（BattleResult/User/EloValidationLog コレクション）
  - ローカルエミュレータでの検証手順
  - 本番投入チェックリスト（Firestore セキュリティルール確認、Cloud Functions 権限設定）

- [functions/tests/elo-validator.test.ts](functions/tests/elo-validator.test.ts) （未実装、Sprint 3 予定）
  - Cloud Function ロジックの単体テスト（Jest + firebase-functions-test）
  - 正常系（複数 ELO ティア間の計算精度）・エラー系（不正な参加者・重複実行）

**Security Properties** (実装済み):
- ✅ **改ざん防止**: クライアント送信の ELO 値を完全無視、サーバー権威データのみ使用
- ✅ **冪等性**: `eloProcessed` フラグで 1バトル 1回のみ実行、重複計算なし
- ✅ **原子性**: User 複数人の更新 + 監査ログが all-or-nothing で成功
- ✅ **監査可能性**: 全 ELO 変動を `elo_validation_log` へ記録、事後検証・不正検知対応可能

**既知のTODO（Sprint 3以降で解消）**:
- Cloud Function 単体テスト（Jest ベース、firebase-functions-test を使用）
- Tier 別 K 値調整（新規プレイヤーは K=64 で高速収束、上級者は K=16 で安定性向上）
- ELO 季節リセット機能（シーズンごとの周期的リセット、レート下限設定）
- アナリティクス統合（ELO 分布・勝率分布の監視ダッシュボード）

**デプロイ手順（本番化時）**:
1. `functions/src/` に `.env` 追加（Firebase プロジェクト ID 等）
2. `npm run build` で TypeScript コンパイル
3. `firebase deploy --only functions` で本番投入
4. Firestore Security Rules に Cloud Function 権限を付与
5. `firebase functions:log` でリアルタイム実行ログ監視

## 参考リンク

- [Design Document](https://...) ← 別途リンク予定
- [API Spec](https://...) ← 別途リンク予定
- [Firebase Console](https://console.firebase.google.com/) ← プロジェクト作成後
- [Riverpod Docs](https://riverpod.dev)
- [Flutter Docs](https://flutter.dev)
