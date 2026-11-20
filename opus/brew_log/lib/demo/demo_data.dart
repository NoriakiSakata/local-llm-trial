import 'dart:math';

import '../data/models.dart';

/// 撮影時の「今」
final demoNow = DateTime(2026, 11, 18, 7, 40);

final _beans = [
  Bean(
    id: 'b1',
    name: 'エチオピア グジ',
    origin: 'エチオピア',
    roast: RoastLevel.light,
    roastedOn: DateTime(2026, 11, 8),
    memo: 'ジャスミンとピーチ。湯温低めが合う',
  ),
  Bean(id: 'b2', name: 'ケニア ニエリ', origin: 'ケニア', roast: RoastLevel.medium, roastedOn: DateTime(2026, 11, 2)),
  Bean(id: 'b3', name: 'ブラジル セラード', origin: 'ブラジル', roast: RoastLevel.dark, roastedOn: DateTime(2026, 10, 12)),
];

/// 直近30日に散らばった記録（毎回同じ内容になるよう乱数の種を固定）
AppData demoData() {
  final rnd = Random(7);
  final records = <BrewRecord>[];
  const notes = ['後味にベリー感', '少し渋い。次は湯温を下げる', '甘みがきれい', '', 'バランス良し'];
  var n = 0;
  for (var day = 0; day < 28; day++) {
    final cups = rnd.nextInt(10) < 3 ? 0 : (rnd.nextInt(10) < 7 ? 1 : 2);
    for (var c = 0; c < (day == 0 ? min(cups, 1) : cups); c++) {
      final bean = _beans[rnd.nextInt(_beans.length)];
      final base = switch (bean.id) {
        'b1' => 4,
        'b2' => 4,
        _ => 3,
      };
      records.add(
        BrewRecord(
          id: 'r${n++}',
          brewedAt: DateTime(demoNow.year, demoNow.month, demoNow.day - day, c == 0 ? 6 : 15, 10 + rnd.nextInt(40)),
          beanId: bean.id,
          beanName: bean.name,
          recipe: Recipe(beanGrams: 15, waterMl: 240, waterTempC: bean.roast == RoastLevel.dark ? 85 : 91),
          elapsedSeconds: 165,
          rating: (base + rnd.nextInt(3) - 1).clamp(1, 5),
          acidity: bean.roast == RoastLevel.light ? 4 : 2,
          bitterness: bean.roast == RoastLevel.dark ? 4 : 2,
          sweetness: 3 + rnd.nextInt(2),
          note: notes[rnd.nextInt(notes.length)],
        ),
      );
    }
  }
  records.sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
  return AppData(
    beans: _beans,
    records: records,
    lastRecipe: const Recipe(beanGrams: 15, waterMl: 240, waterTempC: 91),
  );
}
