import 'package:material_ui/material_ui.dart';

import '../../features/settings/settings_screen.dart';

/// 各タブの AppBar 右上に置く設定ボタン。
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '設定',
    icon: const Icon(Icons.tune_rounded),
    onPressed: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
  );
}
