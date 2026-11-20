import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models.dart';
import '../../domain/brew_plan.dart';
import '../../state/app_store.dart';
import '../../state/brew_timer.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'record_form_screen.dart';

/// 端末機能（スリープ防止・振動）。テストやプラグインのない環境では何もしない。
class DeviceEffects {
  const DeviceEffects();

  void keepAwake(bool on) => unawaited(WakelockPlus.toggle(enable: on).catchError((Object _) {}));

  void stepChanged() => unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));

  void finished() => unawaited(HapticFeedback.heavyImpact().catchError((Object _) {}));
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.plan,
    required this.bean,
    this.onRecorded,
    this.effects = const DeviceEffects(),
    this.clock,
    this.autoStart = false,
  });

  final BrewPlan plan;
  final Bean? bean;
  final VoidCallback? onRecorded;
  final DeviceEffects effects;
  final Clock? clock;

  /// 開いた直後に開始する（スクリーンショット撮影用）
  final bool autoStart;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final BrewTimer _timer = BrewTimer(
    widget.plan,
    clock: widget.clock ?? AppScope.read(context).clock,
    onStepChanged: (p) => p.finished ? widget.effects.finished() : widget.effects.stepChanged(),
  );

  @override
  void initState() {
    super.initState();
    // この画面にいる間はスリープさせない（一時停止中も手元を見ているため）
    widget.effects.keepAwake(true);
    if (widget.autoStart) _timer.start();
  }

  @override
  void dispose() {
    widget.effects.keepAwake(false);
    _timer.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave() async {
    final ok = await confirm(
      context,
      title: '抽出を中断しますか？',
      message: 'タイマーを止めて前の画面に戻ります。この抽出は記録されません。',
      okLabel: '中断する',
      destructive: true,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  void _record() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecordFormScreen(plan: widget.plan, bean: widget.bean, elapsed: _timer.elapsed, onSaved: widget.onRecorded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _timer,
      builder: (context, _) {
        final status = _timer.status;
        final inProgress = status == TimerStatus.running || status == TimerStatus.paused;
        return PopScope(
          canPop: !inProgress,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(title: Text(widget.bean?.name ?? '抽出')),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Padding(
                      padding: Space.page,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RecipeSummary(recipe: widget.plan.recipe),
                          _Dial(timer: _timer),
                          _StepList(plan: widget.plan, current: _timer.progress),
                          _Controls(timer: _timer, onRecord: _record),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecipeSummary extends StatelessWidget {
  const _RecipeSummary({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Text(
        '${recipe.beanGrams} g ・ ${recipe.waterMl} ml ・ ${recipe.waterTempC} ℃',
        style: theme.textTheme.labelLarge?.tabular.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 中央の円盤。ステップの残り時間と、目標の累計湯量を大きく出す
class _Dial extends StatelessWidget {
  const _Dial({required this.timer});
  final BrewTimer timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = timer.progress;
    final finished = timer.status == TimerStatus.finished;
    final stepFraction = finished ? 1.0 : 1 - p.remainingInStep.inMilliseconds / (p.step.durationSeconds * 1000);
    final totalFraction = timer.elapsed.inMilliseconds / timer.plan.total.inMilliseconds;

    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, 320.0);
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(step: stepFraction, total: totalFraction, scheme: scheme),
            child: Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.short,
                      child: Text(
                        finished ? '完了' : p.step.label,
                        key: ValueKey(finished ? -1 : p.stepIndex),
                        style: theme.textTheme.titleLarge?.copyWith(color: scheme.primary),
                      ),
                    ),
                    Text(
                      finished ? formatClock(timer.elapsed) : formatClock(p.remainingInStep),
                      style: theme.textTheme.displayLarge?.tabular.copyWith(fontSize: 72),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '累計 ', style: theme.textTheme.labelLarge),
                          TextSpan(text: '${p.step.targetTotalMl}', style: theme.textTheme.headlineMedium?.tabular),
                          TextSpan(text: ' ml', style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      '経過 ${formatClock(timer.elapsed)} / ${formatClock(timer.plan.total)}',
                      style: theme.textTheme.labelSmall?.tabular,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.step, required this.total, required this.scheme});

  final double step;
  final double total;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(center, r, Paint()..color = scheme.surfaceContainerLow);

    void arc(double radius, double width, double fraction, Color track, Color fill) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
      if (fraction > 0) {
        canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction.clamp(0, 1), false, base..color = fill);
      }
    }

    arc(r - 10, 12, step, scheme.surfaceContainerHighest, scheme.primary);
    arc(r - 26, 4, total, scheme.surfaceContainerHighest, scheme.tertiary);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.step != step || old.total != total || old.scheme != scheme;
}

class _StepList extends StatelessWidget {
  const _StepList({required this.plan, required this.current});
  final BrewPlan plan;
  final BrewProgress current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (var i = 0; i < plan.steps.length; i++)
          AnimatedContainer(
            duration: Motion.short,
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm - 2),
            decoration: BoxDecoration(
              borderRadius: Corner.all(Corner.sm),
              color: i == current.stepIndex && !current.finished ? scheme.primaryContainer : scheme.surfaceContainerLow,
            ),
            child: Text(
              plan.steps[i].label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: i < current.stepIndex || current.finished
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : i == current.stepIndex
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.timer, required this.onRecord});
  final BrewTimer timer;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final status = timer.status;
    final Widget primary = switch (status) {
      TimerStatus.ready => FilledButton.icon(
        onPressed: timer.start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('スタート'),
      ),
      TimerStatus.running => FilledButton.tonalIcon(
        onPressed: timer.pause,
        icon: const Icon(Icons.pause_rounded),
        label: const Text('一時停止'),
      ),
      TimerStatus.paused => FilledButton.icon(
        onPressed: timer.start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('再開'),
      ),
      TimerStatus.finished => FilledButton.icon(
        onPressed: onRecord,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('記録する'),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: status == TimerStatus.ready ? null : timer.reset,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('リセット'),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.short,
              child: SizedBox(key: ValueKey(status), width: double.infinity, child: primary),
            ),
          ),
        ],
      ),
    );
  }
}
