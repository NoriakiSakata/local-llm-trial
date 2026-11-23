import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';
import '../../data/models/recipe.dart';
import '../../domain/brew_schedule.dart';
import '../../state/app_providers.dart';
import '../../state/brew_timer_controller.dart';
import '../../state/device_services.dart';
import '../../ui/format.dart';
import 'record_form_screen.dart';

/// 抽出タイマー画面。ステップごとの残り時間と目標の累計湯量を大きく出す。
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({
    super.key,
    required this.recipe,
    this.bean,
    this.autoStart = false,
  });

  final Recipe recipe;
  final Bean? bean;

  /// 画面を開いた直後にスタートする（デモ・スクリーンショット用）
  final bool autoStart;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late final DeviceServices _device = ref.read(deviceServicesProvider);
  late final BrewTimerController _timer = BrewTimerController(
    schedule: BrewSchedule.fromRecipe(widget.recipe),
    clock: _device.now,
    onStepChanged: _device.stepChanged,
    onFinished: _device.finished,
  );
  TimerStatus _lastStatus = TimerStatus.ready;

  @override
  void initState() {
    super.initState();
    _timer.addListener(_syncWakelock);
    if (widget.autoStart) _timer.start();
  }

  /// 実行中だけ画面スリープを止める
  void _syncWakelock() {
    final status = _timer.status;
    if (status == _lastStatus) return;
    final wasRunning = _lastStatus == TimerStatus.running;
    final isRunning = status == TimerStatus.running;
    _lastStatus = status;
    if (wasRunning != isRunning) _device.keepScreenOn(isRunning);
  }

  @override
  void dispose() {
    _timer.removeListener(_syncWakelock);
    _timer.dispose();
    if (_lastStatus == TimerStatus.running) _device.keepScreenOn(false);
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('抽出を中断しますか？'),
        content: const Text('タイマーは破棄され、記録は保存されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('中断する'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openRecord() {
    _timer.pause();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RecordFormScreen(
          recipe: widget.recipe,
          bean: widget.bean,
          elapsedSec: _timer.elapsed.inSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _timer,
      builder: (context, _) {
        final status = _timer.status;
        final inProgress =
            status == TimerStatus.running || status == TimerStatus.paused;
        return PopScope(
          canPop: !inProgress,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final navigator = Navigator.of(context);
            if (await _confirmLeave() && mounted) navigator.pop();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: '閉じる',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bean?.name ?? '抽出',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.recipe.doseG}g ・ ${widget.recipe.waterMl}ml ・ '
                    '${widget.recipe.tempC}℃',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              child: _TimerBody(timer: _timer, onRecord: _openRecord),
            ),
          ),
        );
      },
    );
  }
}

class _TimerBody extends StatelessWidget {
  const _TimerBody({required this.timer, required this.onRecord});

  final BrewTimerController timer;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final position = timer.position;
    final step = timer.currentStep;
    final next = timer.nextStep;
    final finished = timer.status == TimerStatus.finished;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 幅と高さの両方から大きさを決め、360dp 幅・低い画面でもはみ出さない
        // 円以外の要素が占める高さはおよそ 400dp
        final ring = math.max(
          120.0,
          math.min(
            AppSize.timerRing,
            math.min(
              constraints.maxWidth - AppSpace.xxxl * 2,
              constraints.maxHeight - 400,
            ),
          ),
        );
        return Padding(
          padding: AppSpace.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpace.sm),
              _StepSegments(timer: timer),
              const Spacer(),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  finished ? '抽出完了' : step.label,
                  key: ValueKey(finished ? 'done' : step.label),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox.square(
                dimension: ring,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: position.stepProgress,
                    track: scheme.surfaceContainerHighest,
                    color: finished ? scheme.tertiary : scheme.primary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            finished
                                ? Fmt.mmss(timer.elapsed)
                                : Fmt.mmss(
                                    position.remainingInStep,
                                    ceil: true,
                                  ),
                            key: const ValueKey('remaining'),
                            style: theme.textTheme.displayLarge!.copyWith(
                              fontSize: ring * 0.26,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          finished ? '合計時間' : 'のこり',
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _TargetWater(step: step, finished: finished),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 24,
                child: next != null && !finished
                    ? Text(
                        next.kind == BrewStepKind.drawdown
                            ? '次: 落としきり'
                            : '次: ${next.label}  〜${next.targetTotalMl} ml',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : null,
              ),
              const Spacer(),
              _Controls(timer: timer, onRecord: onRecord),
              const SizedBox(height: AppSpace.xl),
            ],
          ),
        );
      },
    );
  }
}

class _TargetWater extends StatelessWidget {
  const _TargetWater({required this.step, required this.finished});

  final BrewStep step;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          step.kind == BrewStepKind.drawdown || finished ? '注湯量' : '累計の目標湯量',
          style: theme.textTheme.labelLarge!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${step.targetTotalMl}',
                style: theme.textTheme.displayMedium!.copyWith(
                  color: scheme.primary,
                ),
              ),
              TextSpan(
                text: ' ml',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          key: const ValueKey('target-ml'),
        ),
      ],
    );
  }
}

/// 上部のステップ進捗。各セグメントの幅はステップの長さに比例する。
class _StepSegments extends StatelessWidget {
  const _StepSegments({required this.timer});

  final BrewTimerController timer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = timer.schedule.steps;
    final position = timer.position;
    return Semantics(
      label: 'ステップ ${position.stepIndex + 1} / ${steps.length}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                flex: steps[i].duration.inSeconds.clamp(1, 1000),
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == steps.length - 1 ? 0 : AppSpace.xs,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: i < position.stepIndex || position.isFinished
                          ? 1
                          : i == position.stepIndex
                          ? position.stepProgress
                          : 0,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.timer, required this.onRecord});

  final BrewTimerController timer;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final status = timer.status;
    if (status == TimerStatus.finished) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('record-brew'),
              onPressed: onRecord,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('味を記録する'),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(onPressed: timer.reset, child: const Text('もう一度はかる')),
        ],
      );
    }

    final running = status == TimerStatus.running;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.outlined(
          key: const ValueKey('timer-reset'),
          tooltip: 'リセット',
          iconSize: 28,
          onPressed: status == TimerStatus.ready ? null : timer.reset,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
        SizedBox.square(
          dimension: 88,
          child: FilledButton(
            key: const ValueKey('timer-toggle'),
            onPressed: timer.toggle,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.short,
              child: Icon(
                running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(running),
                size: 44,
                semanticLabel: running
                    ? '一時停止'
                    : status == TimerStatus.ready
                    ? 'スタート'
                    : '再開',
              ),
            ),
          ),
        ),
        IconButton.outlined(
          key: const ValueKey('timer-finish'),
          tooltip: 'ここで終えて記録',
          iconSize: 28,
          onPressed: status == TimerStatus.ready ? null : onRecord,
          icon: const Icon(Icons.stop_rounded),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSize.timerRingStroke;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
