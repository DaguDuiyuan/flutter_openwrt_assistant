import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class SettingPage extends HookConsumerWidget {
  SettingPage({super.key});

  final themeModeTitle = ['跟随系统', '总是开启', '总是关闭'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                "主题",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            ListTile(
              title: Text('主题颜色'),
              subtitle: Text('选择界面配色方案'),
              onTap: () => _showColorPicker(context, ref),
            ),
            ListTile(
              onTap: () => showDayNightPicker(context, ref),
              title: Text('深色模式'),
              subtitle: Text(themeModeTitle[getIndexByThemeMode(themeMode)]),
            ),
          ],
        ),
      ),
    );
  }

  void showDayNightPicker(BuildContext context, WidgetRef ref) {
    var values = [ThemeMode.system, ThemeMode.dark, ThemeMode.light];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('主题颜色'),
          content: RadioGroup<ThemeMode>(
            groupValue: ref.read(themeModeProvider),
            onChanged: (value) {
              if (value != null) {
                _updateThemeMode(ref, value);
              }
              Navigator.of(context).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < themeModeTitle.length; i++)
                  RadioListTile(
                    contentPadding: EdgeInsets.only(left: 0),
                    title: Text(themeModeTitle[i]),
                    value: values[i],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ThemeDialog();
      },
    );
  }

  void _updateThemeMode(WidgetRef ref, ThemeMode mode) {
    ref.read(themeModeProvider.notifier).state = mode;
    prefs.setInt("themeMode", switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.dark => 1,
      ThemeMode.light => 2,
    });
  }

  int getIndexByThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.dark => 1,
      ThemeMode.light => 2,
    };
  }
}

class ThemeDialog extends HookConsumerWidget {
  ThemeDialog({super.key});

  final List<ColorSwatch> materialColors = <ColorSwatch>[
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  final tempColorSelected = StateProvider((ref) => ref.read(colorSeedProvider));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('主题颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < materialColors.length; i += 5)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: buildColorRow(i, ref),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('确定'),
          onPressed: () {
            _updateColorSeed(ref, ref.read(tempColorSelected));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  List<Widget> buildColorRow(int startIndex, WidgetRef ref) {
    List<Widget> rowItems = [];

    for (int i = 0; i < 5; i++) {
      int actualIndex = startIndex + i;

      if (actualIndex < materialColors.length) {
        // 添加实际的颜色项
        rowItems.add(
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(tempColorSelected.notifier).state =
                    materialColors[actualIndex];
              },
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: materialColors[actualIndex],
                      ),
                    ),
                  ),
                  if (ref.watch(tempColorSelected).toARGB32() ==
                      materialColors[actualIndex].toARGB32())
                    Positioned.fill(child: Center(child: Icon(Icons.check))),
                ],
              ),
            ),
          ),
        );
      } else {
        rowItems.add(Expanded(child: SizedBox()));
      }
      if (i < 4) {
        rowItems.add(SizedBox(width: 8));
      }
    }

    return rowItems;
  }

  void _updateColorSeed(WidgetRef ref, Color color) {
    ref.read(colorSeedProvider.notifier).state = color;
    prefs.setInt("colorSeed", color.toARGB32());
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return switch (prefs.getInt("themeMode") ?? 0) {
    0 => ThemeMode.system,
    1 => ThemeMode.dark,
    2 => ThemeMode.light,
    _ => ThemeMode.system,
  };
});

final colorSeedProvider = StateProvider<Color>((ref) {
  return Color(prefs.getInt("colorSeed") ?? Colors.red.toARGB32());
});
