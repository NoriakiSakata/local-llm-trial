import 'package:brew_log/application/brew_session.dart';
import 'package:brew_log/application/clock.dart';
import 'package:brew_log/application/providers.dart';
import 'package:brew_log/data/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  late ProviderContainer container;
  late ManualBrewClock clock;

  setUp(() {
    clock = ManualBrewClock(DateTime(2026, 10, 30, 9));
    container = createContainer(clock: clock);
    addTearDown(container.dispose);
  });

  BrewSessionNotifier notifier() =>
      container.read(brewSessionProvider.notifier);

  void start() => notifier().start(recipeA);
  BrewSession? session() => container.read(brewSessionProvider);

  test('start 直後は蒸らし・経過0・マーク1件', () {
    start();
    final s = session()!;
    expect(s.phase, BrewPhase.running);
    expect(s.elapsedMs, 0);
    expect(s.currentIndex, 0);
    expect(s.currentStep.label, '蒸らし');
    expect(s.marks.length, 1);
    expect(s.targetCumMl, 30);
    expect(s.remainingTotal, s.plan.totalDuration);
  });

  test('tick は経過時間を再計算し、ステップ跨ぎでマークを増やす', () {
    start();
    clock.advance(const Duration(seconds: 20));
    notifier().tick();
    expect(session()!.elapsedMs, 20000);
    expect(session()!.marks.length, 1, reason: 'まだ蒸らしの途中');

    clock.advance(const Duration(seconds: 21));
    notifier().tick();
    expect(session()!.currentIndex, 1);
    expect(session()!.currentStep.label, '1投目');
    expect(session()!.marks.length, 2);
    expect(session()!.marks[1].label, '1投目');
    expect(session()!.targetCumMl, 100);
  });

  test('ティックを飛ばしても途中ステップを全てマークする', () {
    start();
    clock.advance(const Duration(seconds: 70));
    notifier().tick();
    final s = session()!;
    expect(s.currentIndex, 3);
    expect(s.marks.map((PourLog l) => l.label).toList(), <String>[
      '蒸らし',
      '1投目',
      '2投目',
      '3投目',
    ]);
  });

  test('pause 中は経過が進まず、resume で続きから進む', () {
    start();
    clock.advance(const Duration(seconds: 10));
    notifier().tick();
    notifier().pause();
    expect(session()!.phase, BrewPhase.paused);
    final int frozen = session()!.elapsedMs;
    expect(frozen, 10000);

    clock.advance(const Duration(minutes: 5));
    notifier().tick();
    expect(session()!.elapsedMs, frozen, reason: '停止中は進めない');

    notifier().resume();
    clock.advance(const Duration(seconds: 5));
    notifier().tick();
    expect(session()!.elapsedMs, 15000);
    expect(session()!.phase, BrewPhase.running);
  });

  test('目標時間に達したら finished になり、全マークが揃う', () {
    start();
    clock.advance(const Duration(seconds: 76));
    notifier().tick();
    final s = session()!;
    expect(s.phase, BrewPhase.finished);
    expect(s.isFinished, isTrue);
    expect(s.elapsedMs, s.plan.totalMs);
    expect(s.marks.length, s.plan.steps.length);
    expect(s.remainingTotal, Duration.zero);
  });

  test('finishManually で任意の地点から完了にできる', () {
    start();
    clock.advance(const Duration(seconds: 3));
    notifier().tick();
    notifier().finishManually();
    final s = session()!;
    expect(s.phase, BrewPhase.finished);
    expect(s.elapsedMs, s.plan.totalMs);
    expect(s.marks.length, s.plan.steps.length);
  });

  test('restart で同じレシピを最初から', () {
    start();
    clock.advance(const Duration(seconds: 50));
    notifier().tick();
    notifier().restart();
    final s = session()!;
    expect(s.elapsedMs, 0);
    expect(s.currentIndex, 0);
    expect(s.marks.length, 1);
  });

  test('discard と completeAndClear でセッションを閉じる', () {
    start();
    notifier().discard();
    expect(session(), isNull);

    start();
    notifier().completeAndClear();
    expect(session(), isNull);
  });

  test('start していない状態で pause/resume/finish しても壊れない', () {
    notifier().pause();
    notifier().resume();
    notifier().finishManually();
    notifier().restart();
    notifier().tick();
    expect(session(), isNull);
  });
}
