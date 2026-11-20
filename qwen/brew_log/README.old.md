# Brew Log — ハンドドリップ珈琲の抽出タイマー＆記録

豆を登録し、レシピに沿ってタイマーで淹れ、味を記録して振り返るだけのアプリ。
通信は一切せず、データはすべて端末内（`shared_preferences`）に保存します。UI は日本語、Material 3 ベース。

```
brew_log/
├── lib/
│   ├── main.dart                  起動（保存データを一回来てから runApp）
│   ├── app_info.dart              表示名・バージョン
│   ├── theme/                     tokens / typography / app_theme
│   ├── data/                      models（Bean, Recipe, Extraction…）+ state_store（JSON永続化）
│   ├── application/               brew_plan / brew_session / stats / app_data / providers
│   ├── presentation/              home_shell + 画面群 + widgets
│   └── demo/                      スクリーンショット生成専用の入口（通常実行には使わない）
├── test/                          unit / widget / helpers
├── tool/shoot.sh                  撮影スクリプト
└── screenshots/                   シミュレータで撮った 12 枚
```

層の分け方は「画面（presentation）→ 状態と振る舞い（application）→ 保存（data）」の一方通行です。
presentation から data を直接読むことはせず、必ず application 経由にしています。

---

## 1. 起動方法

```bash
cd brew_log
fvm flutter pub get
fvm flutter run            # iOS シミュレータ / macOS / Android
```

FVM を使わない場合は `flutter` に読み替えてください。このプロジェクトは `.fvmrc` で **3.47.9** に固定しています。

### 検証に使ったバージョン（実測）

```
Flutter 3.47.9 • channel stable
Framework • revision c197ca5199 (2026-10-29)
Engine • hash 9e025265bef3 (revision 89c39edfdf, 2026-10-27)
Tools • Dart 3.13.7 • DevTools 2.60.0
```

このマシンには既定で Flutter 3.35.3 が入っていたため、**グローバルの SDK は変更せず** FVM で 3.47.9 を追加取得して使っています。

---

## 2. 画面一覧と画面遷移

下部は NavigationBar の4タブ構成です。5番目の項目は作らず、設定は AppBar の歯車から開きます（幅360dpでラベルが詰まるため）。

```
HomeShell（AppBar + NavigationBar）
├── 0 淹れる      BrewScreen
│   ├── （未実行）BrewIdleView … レシピ選択 →「タイマーをスタート」
│   │                 ├── レシピ編集 / 新規 → RecipeEditorScreen（page）
│   │                 └── 豆もレシピも無い → 空状態 →「豆を登録」/「レシピを作る」
│   └── （実行中）BrewRunningView
│                     ├── 一時停止 / 再開 / リセット / ここで完了 / 中断して終了
│                     └── 完了 → RatingSheet（bottom sheet）→ 保存して完了
├── 1 記録        ExtractionsScreen（豆でフィルタ）
│   └── ExtractionDetailScreen（page）─ 削除 → Undo
├── 2 豆          BeansScreen
│   └── BeanEditorScreen（page）─ 登録 / 編集 / 削除 → Undo
├── 3 見返す      StatsScreen（日別グラフ + 豆別ランキング）
└── 設定          SettingsScreen（AppBar の歯車 → page）
```

遷移は `MaterialPageRoute` を素直に使うだけです。タブは `IndexedStack` で保持しているので、行き来してもスクロール位置と実行中のタイマーは消えません。

**タイマーはタブを切り替えても動き続けます**（セッション状態は `brewSessionProvider` にあり、UI より寿命が長い）。

---

## 3. デザイン上の判断

### 3.1 カラー

シードカラーは **`#6F4E37`（中煎りの豆の表面色）**。この1色だけを `ColorScheme.fromSeed` に渡すと生成される neutral はほぼ無彩色に近く、せっかくの「珈琲」の温度感が落ちます。そこで以下を明示的に差し替えました。

| 用途 | ライト | ダーク |
|---|---|---|
| surface | `#FBF7F1`（クリーム） | `#17110D`（焙煎深色） |
| onSurface | `#1E1611` | `#EFE3D6` |
| onSurfaceVariant | `#4F443A` | `#CBB9A6` |
| surfaceContainer 群 | 明度だけ段違いのベージュランプ | 同系の濃い茶ランプ |
| tertiary（★・今日のバー） | `#7A4E14`（琥珀） | `#E9B96B` |

tertiary を手当てした理由: 茶色をシードにすると M3 の調色は三次的特徴色を**オリーブ寄り**に作ります（ライトで `#5F6135`）。評価の★に使うと抹茶のような印象になるので、焙煎した砂糖を連想させる琥珀に固定しました。

**影はほぼ使いません。** elevation は 0 と 1 の2段階だけで、立体は `surfaceContainer` の濃淡（トーン）で表現します。既定の M3 サンプルアプリに見える「浮いたカードの影」を消すための方針で、`AppElevation` に定数化してあります。

コントラストは WCAG の相対輝度で実測し、`test/theme_contrast_test.dart` に閾値として残しました（AA=4.5、AAA=7.0）。

| 組 | ライト | ダーク |
|---|---|---|
| onSurface / surface（本文） | **16.70** | **14.82** |
| onSurface / 入力欄（surfaceContainerHighest） | 13.01 | 10.06 |
| onSurfaceVariant / surface（補助文字） | 8.86 | 9.83 |
| onPrimary / primary（ボタン文字） | 6.46 | 7.74 |
| primary / surface（進行リング） | 6.05 | 11.01 |
| tertiary / surface（★） | 6.72 | 10.35 |
| onTertiaryContainer / tertiaryContainer（焙煎日バッジ） | 11.12 | 7.36 |

本文色は AAA を大きく超え、それ他もすべて AA を満たします。

### 3.2 タイポグラフィ

`TextTheme` を displayLarge から labelSmall まで**全部明示的に**組み直しています（`lib/theme/typography.dart`）。

- 見出し系だけ文字詰め（-0.25 〜 0.1）、本文は詰めない —— 日本語は詰めすぎると読みにくい
- 本文の行送りは **1.55〜1.65**。M3 既定（1.4 前後）は日本語の連文で詰まって見えるため
- 数値は `FontFeature.tabularFigures()` を付ける `AppTypography.numeric()` 経由で描画。タイマーの秒数が桁揺れして見えないようにするためで、`displayLarge` を 68sp・w300 に拡大したものがタイマー数字です
- **フォントは同梱していません。** CJK フォント1書体をバンドルするとアプリが 3〜8MB 重くなり、「依存は必要最小限」「オフライン動作」という要件に対して対価が大きすぎます。iOS / macOS ではそれぞれ PingFang / SF が自然なので、システムフォント採用としました。同梱に切り替えるなら `pubspec.yaml` の `fonts:` に足して `AppTypography` の `ts()` に `fontFamily` を渡すだけで追従します

### 3.3 余白・角丸・モーション

`lib/theme/tokens.dart` に集約してあり、画面側には直値を書きません。

- 間隔: 4 の倍数（xs4 / sm8 / md12 / lg16 / xl24 / xxl32 / xxxl48）、画面左右は 20
- 角丸: chip12 / field14 / button16 / card20 / sheet28
- 時間: fast150 / normal250 / slow360（最長360ms。それを超えると「待たされている」感が出るため）
- 曲線: `easeOutCubic`（通常）と `easeOutQuint`（画面切替）

アニメーションは控えめに限定しています。一覧の出現は `FadeSlideIn`（12dp のスライド＋フェード、index ごとに24msずつ遅延）、タブ切替は `IndexedStack`、ページ遷移は `FadeForwardsPageTransitionsBuilder`、待機ビュー⇄実行中ビューだけ `AnimatedSwitcher`。削除はスワイプ＋Undo スナックバーです。

### 3.4 空状態

データ0件の画面は5パターン用意し、いずれも「何が無い」だけでなく**次に押すべきボタン**を置いています（例: 豆が0件 →「最初の豆を登録」＋補助として「まずは淹れてみる」）。
イラストはアセット同梱を避けるため、ドリッパーとカップの線画を `CustomPaint` で描いた幾何学的なプレースホルダーです（`lib/presentation/widgets/empty_state.dart` の `_DripperPainter`）。差し替えるならこのペインターを `Image` に変えるだけです。

---

## 4. 使用パッケージと選定理由

`pubspec.yaml` の direct dependency は **3つ**（+ Flutter SDK 同梱の localizations）だけです。

| パッケージ | 版 | 選んだ理由 | 代わりに見送ったもの |
|---|---|---|---|
| `flutter_riverpod` | 3.4.3 | Notifier を単位に状態を置け、`ProviderContainer` 生成時に全依存（時計・保存）を override できる。**テストの決定論性**が決め手。画面は `ref.watch` だけで再接続不要 | 素の `ChangeNotifier` + `InheritedWidget` は DI が手書きになり、保存/時計の差し替えが画面側に漏れる。BLoC はこの規模では抽象度が過ぎる |
| `shared_preferences` | 2.5.6 | データは高々数千行のドキュメント。**1キーに JSON を1個**が最も故障が少ない。iOS / macOS は `shared_preferences_foundation`（ネイティブ、通信なし） | drift / sqlite はネイティブDBとスキーマ移行が増えるだけでこの規模では過剰。Hive / objectbox も同じ理由で不要 |
| `wakelock_plus` | 1.8.2 | 「実行中はスリープさせない」を満たす最小の実装。iOS は `isIdleTimerDisabled` のラッパー | platform channel を自前で書くと Android / iOS 両方の保守が増える |
| `flutter_localizations` | (SDK) | 日付ピッカーなどの UI 文言を日本語化。Pub からのダウンロードではない | 既定のままではカレンダーが英語になる |

**グラフもパッケージにしていません。** 棒グラフ（`daily_bar_chart.dart`）と進行リング（`step_dial.dart`）は CustomPaint の自作です。
同様に `intl` も入れていません（日付整形は `presentation/format.dart` の自作関数）。`cupertino_icons` はテンプレ名残で未使用だったので削除しました。

---

## 5. データ保存と「壊れても落とさない」設計

```jsonc
// key: "brew_log.state.v1"
{ "schema": 1, "beans": [...], "recipes": [...], "extractions": [...], "settings": {...} }
```

読み込みは `main()` で**一度だけ**行い、結果を `appBootstrapProvider` としてツリーに流し込みます。画面側はローディング状態を持たなくて済みます。

| 状況 | 挙動 |
|---|---|
| キーが無い（初回） | 失敗なしで空状態 |
| JSON が壊れている / 型が想定外 | 元データを `brew_log.corrupt.<timestamp>` に**退避**してから空状態。全画面上部に閉じられるバナーを出し、設定画面に理由と退避キーを表示。退避は新しい3件だけ保持 |
| `schema` が自分より新しい | データは**消さず**、読み取り専用の警告だけ出す。上書き事故を防ぐため自動保存を停止し、設定画面にもその旨を表示 |
| 保存そのものに失敗 | メモリ上の状態は先に進めたまま、スナックバーで「保存に失敗しました」と伝える（黙って失わせない） |
| 保存領域にアクセスできない | 動作確認用に空状態から起動し、警告を出す |

デコードは `data/json_io.dart` の `JsonMap` 経由で厳密に行い、想定外は `DataShapeException` に集約します。**未知のキーは読み捨てる**ので、将来フィールドを足しても古いアプリが壊れません。
豆を削除しても抽出記録は「記録時点の豆名」をスナップショットとして持つため、履歴が壊れません。

---

## 6. タイマーのステップ計算ルール

レシピにあるのは「豆量・湯量・湯温・蒸らし時間・注湯回数」の5つだけなので、ステップは次の方針で自動設計します（`application/brew_plan.dart`）。

- 蒸らし湯量 = 豆量 × 2 ml（ただし各投与に1mlずつは残す）
- 各投与の湯量 = (総湯量 − 蒸らし) ÷ 注湯回数、端数は最終投与に載せる
- 蒸らしの長さ = レシピの蒸らし時間
- 各投与の長さ = その湯量 ÷ 6 ml/秒（最低8秒）

進行は「`Timer.periodic(200ms)` が時計を読みに行く」だけ。ステップ番号は経過時間から決まる純粋関数なので、リビルドや再開で目標と実測がずれません（停止中の時間は経過から除く）。
ステップが切り替わった瞬間に `HapticFeedback`（蒸らし→注湯は medium、次投与は selection）、実行中は `WakelockPlus` で画面を点けたままにします。

---

## 7. 実際に検証したこと

コマンドはすべてこのリポジトリで実行し、結果を確認しています。

```bash
$ fvm flutter analyze     # → No issues found!（info / warning / error 0件）
$ fvm flutter test        # → +88: All tests passed!
$ fvm flutter build ios --simulator -t lib/demo/demo_main.dart
                          # → ✓ Built build/ios/iphonesimulator/Runner.app
$ fvm flutter build ios --simulator          # 本番の lib/main.dart でもビルド成功
$ xcrun simctl install booted build/ios/iphonesimulator/Runner.app && xcrun simctl launch booted dev.brewlog.brewLog
                          # → iPhone 18 Pro / iOS 27.0 シミュレータで起動確認（異常ログなし）
```

- **88件のテスト**: ステップ計算（境界・端数・極端に少ない湯量）、30日集計（窓の境界・ランキング順序・削除済み豆）、保存の往復と**破損時に退避キーができるまで**、未来スキーマで自動保存が止まること、豆/レシピ/記録の CRUD と Undo、セッションの停止→再開で経過が飛ばないこと、主要4タブ＋設定＋評価シートの widget テスト、コントラスト比
- **テストが機能バグを1件検出しました**: 一時停止ボタンが `paused ? pause() : resume()` と分岐を逆にしていて、どちらを押しても効かない状態でした（`brew_running_view.dart`）。widget テストが「一時停止中」バッジが出ないことで気づかせ、修正後に再テスト済み
- **テストではなく画面確認で気づいたもの**: 日別グラフの X 軸ラベルが右端で重なっていた（`daily_bar_chart.dart`）、空状態のカップの持ち手が内側にめくれていた（`empty_state.dart`）、「システム」選択時にテーマ見本の強調がライト固定だった（`settings_screen.dart`）。いずれもスクリーンショットを実際に見て直しました
- **スクリーンショット**: `screenshots/` の12枚は iPhone 18 Pro シミュレータで実撮影（6画面 × ライト/ダーク）。ダークはアプリ内の「システム」設定で端末の外観を切り替えて撮っているので、システム追従も通っています。`first_run_light.png` はデータ0件で本番エントリポイントを起動した画面です
- **レイアウト**: 400×1200 と 360×780 の2サイズで widget テストを実行。RenderFlex の overflow はテスト中に例外となるため、出ていないことを確認済み

## 8. 未検証・既知の問題

以下は**やっていません**。

- **Android / 実機**: Android SDK はこのマシンにありますがビルドも起動もしていません（`flutter create --platforms=ios,macos` で生成）。iOS 実機でのハプティクスの強さやスリープ防止の体感も未確認です
- **macOS ビルド**: プラットフォームフォルダはありますがビルド検証していません
- **アクセシビリティ**: Dynamic Type（文字サイズ拡大）、VoiceOver の読み上げ順序、`Semantics` ラベルの監査はしていません
- **ランドスケップ・iPad 等大画面**: 縦画面前提のレイアウトです。横長では中央のリングが大きくなりすぎて余白が間延びして見える可能性があります
- **データ量の限界**: 全件をメモリで保持し毎回 JSON にシリアライズするので、記録が数万件を超えると保存が重くなります（想定は多くても数千件）
- **バックアップ/復元**: iCloud やファイル書き出しはありません。退避キーの内容を設定画面から書き出す機能も未実装です
- **時刻の精度**: タイマーは `DateTime.now()` ベースなので、実行中に端末時計をずらすと経過が狂います
- **タイマー完了通知**: アプリを閉じた途中でタイムアップしても通知はしません（セッション自体がメモリ上なので、閉じたら消失します）
- **シミュレータ上での保存の往復**: `SharedPreferencesStore` の読み書きはテストでは plugin 同梱の `setMockInitialValues` 経由で検証していますが、**シミュレータ上で実際にデータを書き、再起動して読み戻すところまでは確認していません**。撮影がデモ用メモリ保存だったことと、タップを自動化できなかったことが理由です（書き出し側は本番コードをそのままで通る経路なので、再現は「豆を1件登録 → アプリを落として起動し直す」だけでできます）

### このマシン特有のハマり所

ビルド時に2つの環境問題に当たったため、`/private/tmp/qw-toolbin/` に回避用シムを置いて対処しました（**グローバルの環境は変更していません**）。

1. `/usr/local/bin/openssl` が Intel 版で `Bad CPU type in executable` → `flutter create` がコード署名探索でこれを呼び出して中断。システム `/usr/bin/openssl` へのシンボリックリンクを PATH 先頭に置いて解決
2. rbenv の CocoaPods が x86_64 ruby を参照していて `pod install` が失敗 → arm64 ruby 3.3.7 の pod を呼ぶラッパを作って解決

自分で作り直す場合は `tool/shoot.sh` を見れば手順が追えますが、普通に `fvm flutter run` する分には不要です。

---

## 9. スクリーンショット

| 画面 | ライト | ダーク |
|---|---|---|
| タイマー（待機） | `brew_light.png` | `brew_dark.png` |
| タイマー（実行中） | `running_light.png` | `running_dark.png` |
| 抽出記録 | `log_light.png` | `log_dark.png` |
| 豆 | `beans_light.png` | `beans_dark.png` |
| ふりかえり | `stats_light.png` | `stats_dark.png` |
| 設定 | `settings_light.png` | `settings_dark.png` |

撮り直し方:

```bash
bash tool/shoot.sh            # 全画面
bash tool/shoot.sh stats      # 1画面だけ
```

`lib/demo/demo_main.dart` は**メモリ上にだけ**ダミーデータを作る撮影専用入口で、保存領域には一切書き込みません。
