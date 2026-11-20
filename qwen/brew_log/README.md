# Brew Log

ハンドドリップ珈琲の抽出タイマー＆記録アプリ（Flutter / Material 3）。
通信はせず、データは端末内だけに保存します。

## 機能

- **淹れる**：レシピを選んでタイマー開始。蒸らし・注湯のステップと湯量を自動で計算し、切り替わりでバイブ。実行中は画面がスリープしない
- **記録**：淹れ終わったら★・酸味／苦味／甘味・メモを付けて保存。豆で絞り込める。削除は Undo 可
- **豆**：豆（産地・焙煎日など）の登録・編集・削除
- **見返す**：直近30日の日別グラフと、豆別ランキング
- **設定**：ライト／ダーク／システムのテーマ切り替え
- データが壊れていても落ちずに退避して空の状態で起動

## アーキテクチャ

**ライブラリ**（直接の依存は3つだけ）

- `flutter_riverpod`：状態管理。時計や保存先を差し替えてテストできる
- `shared_preferences`：保存。アプリの状態を JSON 1個で保存
- `wakelock_plus`：タイマー実行中のスリープ防止

グラフ・日付の整形・空状態のイラストは自作（`CustomPaint`）で、パッケージを増やしていません。

**層の分け方**：画面（presentation）→ 状態と処理（application）→ 保存（data）の一方通行。画面から保存を直接触らない。

```
lib/
├── main.dart          起動（保存データを読んでから runApp）
├── theme/             色・文字・余白などのデザイン定義
├── data/              モデル（豆・レシピ・記録・設定）と JSON 保存
├── application/       タイマーの計算・進行、集計、Riverpod の provider
├── presentation/      画面（淹れる・記録・豆・見返す・設定）と共通ウィジェット
└── demo/              スクリーンショット撮影用の入口
test/                  unit・widget テスト（88件）
```

## 動かし方

```bash
fvm flutter pub get
fvm flutter run
```

Flutter 3.47.9（`.fvmrc` で固定）。iOS シミュレータで動作確認済み。Android・実機は未確認。

## テスト・撮影で使うデータ例

[`test_data/`](test_data/) に書き出してあります（読み込まれるコードではなく、ドキュメント）。

- `beans.md` / `recipes.md` / `extractions.md` … 豆・レシピ・記録の具体値と、レシピから自動計算されるステップ内訳
- `seed_state.json` … 上のデータをアプリの保存形式（`schema` 付きJSON）にしたもの。シミュレータの保存キーに1本書いて起動し直すと、端末実ファイル経由の読み出しを確認できる
- 裏取り: `fvm flutter test tool/dump_test_data_test.dart` → 実コードから `build/test_data_dump.md` に出る（`test_data/*.md` は上書きしない）

