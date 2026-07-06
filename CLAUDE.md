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
9. 画面遷移・ナビゲーション
10. ペイウォール（BattlePass・スキンガチャ）
11. リプレイ生成・シェア ← Sonnet
12. フレンド・ギルド ← Sonnet
13. エラーハンドリング（スケルトンUI・ネットワーク）
14. テスト（unit/widget/integration） 🔄 Battle Engine単体テストのみ実装済み
15. CI/CD設定（GitHub Actions）
16. リリース準備（審査対応・段階公開）
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
