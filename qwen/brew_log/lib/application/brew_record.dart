import '../data/models.dart';
import 'brew_session.dart';

/// タイマーの実測ログから抽出記録を作る。
///
/// 豆が途中で削除されても履歴が読めるよう、豆名と数値はこの時点で写し込む。
Extraction buildExtraction({
  required BrewSession session,
  required Bean? bean,
  required int rating,
  required TasteProfile taste,
  required String note,
  required DateTime brewedAt,
  String? id,
}) {
  return Extraction(
    id: id ?? newId(),
    brewedAt: brewedAt,
    beanId: session.recipe.beanId ?? bean?.id,
    beanName: bean?.name ?? '（豆未選択）',
    recipeName: session.recipe.name,
    rating: rating.clamp(1, 5),
    beanAmountG: session.recipe.beanAmountG,
    waterMl: session.recipe.waterMl,
    tempC: session.recipe.tempC,
    taste: taste,
    note: note.trim(),
    pours: session.marks,
  );
}
