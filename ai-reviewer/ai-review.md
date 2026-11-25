# レビューの観点とプロジェクトのルール

## ディレクトリの役割

| ディレクトリ | 置くもの | 置かないもの |
|---|---|---|
| `lib/app/` | MaterialApp、テーマ、デザイントークン | 画面、ロジック |
| `lib/data/models/` | データの型、JSON 変換と値の検証 | 画面の表示用の整形 |
| `lib/data/storage/` | 保存領域（shared_preferences など）の実装 | |
| `lib/data/repositories/` | 保存・読み込みの窓口。読み込み失敗の扱いもここに集約 | |
| `lib/domain/` | Flutter の UI に依存しない純粋なロジック（計算、集計、状態の判定） | Widget、BuildContext、Riverpod |
| `lib/state/` | Riverpod の Provider / Notifier、端末機能の抽象 | Widget |
| `lib/features/<機能>/` | その機能の画面と、その画面でしか使わない Widget | 純粋なロジック、複数画面で使う部品 |
| `lib/ui/` | 画面をまたいで使う Widget（`ui/widgets/`）と表示用の整形（`ui/format.dart`） | ビジネスロジック |
| `lib/dev/` | デモデータなど開発用のもの | |

## 層のルール

- 画面（`features/`）から `data/repositories/` や `repositoryProvider` を直接呼ばない。保存は必ず `state/` の Notifier を経由する（Notifier の state を更新しないと画面に反映されないため）。
- `domain/` は Flutter の UI に依存させない。`package:flutter/foundation.dart` 以外の Flutter の import は不可。
- 日付の差は `Bean.daysBetween` を使う（夏時間の影響を避けるため）。
- 表示用の文字列の整形は `ui/format.dart` の `Fmt` に集める。

## レビューで重視すること

1. バグ（境界値、null、非同期、状態の不整合、ほかのファイルからの呼び出しへの影響）
2. 関連するイシューの要件を満たしているか（抜け漏れ）
3. 上のディレクトリの役割・層のルールに沿っているか（ファイルの置き場所を含む）
4. テストが必要な変更にテストがあるか

好みの問題、命名の細かい指摘、フォーマットは指摘しない。
