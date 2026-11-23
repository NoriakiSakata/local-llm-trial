import 'package:brew_log/data/models/recipe.dart';
import 'package:brew_log/domain/brew_schedule.dart';
import 'package:brew_log/state/brew_timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Duration clock;
  late int stepChanges;
  late int finishes;
  late BrewTimerController timer;

  setUp(() {
    clock = Duration.zero;
    stepChanges = 0;
    finishes = 0;
    timer = BrewTimerController(
      schedule: BrewSchedule.fromRecipe(Recipe.standard),
      clock: () => clock,
      onStepChanged: () => stepChanges++,
      onFinished: () => finishes++,
      // 周期タイマーは使わず tick() を手動で呼ぶ
      tickInterval: const Duration(days: 1),
    );
  });

  tearDown(() => timer.dispose());

  void advance(int seconds) {
    clock += Duration(seconds: seconds);
    timer.tick();
  }

  test('スタート前は ready で経過 0', () {
    expect(timer.status, TimerStatus.ready);
    expect(timer.elapsed, Duration.zero);
    expect(timer.currentStep.label, '蒸らし');
    expect(timer.nextStep!.label, '1投目');
  });

  test('ステップが切り替わるたびに通知が1回ずつ来る', () {
    timer.start();
    advance(10);
    expect(stepChanges, 0);
    advance(25); // 35秒 → 1投目
    expect(timer.currentStep.label, '1投目');
    expect(stepChanges, 1);
    advance(60); // 95秒 → 3投目（2ステップ進んでも通知は1回）
    expect(timer.currentStep.label, '3投目');
    expect(stepChanges, 2);
  });

  test('一時停止中は時間が進まず、再開すると続きから数える', () {
    timer.start();
    advance(20);
    timer.pause();
    expect(timer.status, TimerStatus.paused);
    advance(100);
    expect(timer.elapsed, const Duration(seconds: 20));

    timer.start();
    advance(5);
    expect(timer.elapsed, const Duration(seconds: 25));
    expect(timer.position.remainingInStep, const Duration(seconds: 5));
  });

  test('合計時間に達すると finished になり、完了通知が1回だけ来る', () {
    timer.start();
    advance(149);
    expect(timer.status, TimerStatus.running);
    advance(1);
    expect(timer.status, TimerStatus.finished);
    expect(finishes, 1);
    advance(10);
    expect(finishes, 1);
    expect(timer.elapsed, const Duration(seconds: 150));
    // 完了後に start しても何も起きない
    timer.start();
    expect(timer.status, TimerStatus.finished);
  });

  test('リセットで最初の状態に戻る', () {
    timer.start();
    advance(70);
    timer.reset();
    expect(timer.status, TimerStatus.ready);
    expect(timer.elapsed, Duration.zero);
    expect(timer.position.stepIndex, 0);
  });

  test('バックグラウンドなどで tick が遅れても、正しい位置に追いつく', () {
    timer.start();
    clock += const Duration(seconds: 100); // tick を呼ばずに時間だけ進める
    expect(timer.elapsed, const Duration(seconds: 100));
    timer.tick();
    expect(timer.currentStep.label, '3投目');
  });
}
