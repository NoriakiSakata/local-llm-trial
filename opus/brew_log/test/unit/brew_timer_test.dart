import 'package:brew_log/data/models.dart';
import 'package:brew_log/domain/brew_plan.dart';
import 'package:brew_log/state/brew_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late List<BrewProgress> changes;
  late BrewTimer timer;

  setUp(() {
    now = DateTime(2026, 11, 18, 8);
    changes = [];
    timer = BrewTimer(
      BrewPlan.fromRecipe(const Recipe(bloomSeconds: 30, pours: 2)), // 30 + 60 + 45 = 135秒
      clock: () => now,
      onStepChanged: changes.add,
      tickInterval: const Duration(days: 1), // テストでは手動で tick する
    );
  });

  tearDown(() => timer.dispose());

  void advance(Duration d) {
    now = now.add(d);
    timer.tick();
  }

  test('スタート前は ready で経過0', () {
    expect(timer.status, TimerStatus.ready);
    expect(timer.elapsed, Duration.zero);
  });

  test('時計の差分で経過時間を数える', () {
    timer.start();
    advance(const Duration(seconds: 12));
    expect(timer.elapsed, const Duration(seconds: 12));
    expect(timer.progress.step.label, '蒸らし');
  });

  test('一時停止中は進まず、再開すると続きから数える', () {
    timer.start();
    advance(const Duration(seconds: 10));
    timer.pause();
    expect(timer.status, TimerStatus.paused);
    now = now.add(const Duration(minutes: 5));
    expect(timer.elapsed, const Duration(seconds: 10));
    timer.start();
    advance(const Duration(seconds: 5));
    expect(timer.elapsed, const Duration(seconds: 15));
  });

  test('ステップが切り替わったときだけ通知する', () {
    timer.start();
    advance(const Duration(seconds: 10));
    advance(const Duration(seconds: 10));
    expect(changes, isEmpty);
    advance(const Duration(seconds: 15)); // 35秒: 1投目へ
    expect(changes.map((p) => p.step.label), ['1投目']);
  });

  test('tick が間引かれてもステップ変化を取りこぼさず、最後は完了で止まる', () {
    timer.start();
    advance(const Duration(minutes: 10));
    expect(timer.status, TimerStatus.finished);
    expect(timer.elapsed, timer.plan.total);
    expect(changes.single.finished, isTrue);
  });

  test('リセットで最初に戻る', () {
    timer.start();
    advance(const Duration(seconds: 40));
    timer.reset();
    expect(timer.status, TimerStatus.ready);
    expect(timer.elapsed, Duration.zero);
    expect(timer.progress.stepIndex, 0);
  });

  test('完了後の start は無視する', () {
    timer.start();
    advance(const Duration(minutes: 10));
    timer.start();
    expect(timer.status, TimerStatus.finished);
  });
}
