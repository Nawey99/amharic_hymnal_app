import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Chooses light or dark, and which colour family, and shows the choice
/// taking effect on the page underneath as it is made.
class AppearanceSettings extends StatelessWidget {
  final ThemeService? service;

  const AppearanceSettings({super.key, this.service});

  static const _modes = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'ብርሃን', Icons.light_mode_outlined),
    (ThemeMode.dark, 'ጨለማ', Icons.dark_mode_outlined),
    (ThemeMode.system, 'የስልኩ', Icons.phone_android_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = service ?? ThemeService();
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => GlassContainer(
        borderRadius: 16,
        blurSigma: 12,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ገጽታ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'የመተግበሪያውን ብርሃን እና ቀለም ይምረጡ',
              style: TextStyle(
                fontSize: 12,
                color: colors.secondaryText,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
            const SizedBox(height: 12),
            _ModeRow(theme: theme),
            if (AppPalette.values.length > 1) ...[
              const SizedBox(height: 14),
              _PaletteRow(theme: theme),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final ThemeService theme;

  const _ModeRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        for (final (mode, label, icon) in AppearanceSettings._modes)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ModeButton(
                key: ValueKey('theme-mode-${mode.name}'),
                label: label,
                icon: icon,
                selected: theme.themeMode == mode,
                colors: colors,
                onTap: () => theme.setThemeMode(mode),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  const _ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? colors.accent.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.accent : colors.divider,
                width: selected ? 1.4 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? colors.accent : colors.secondaryText,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.accent : colors.primaryText,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final ThemeService theme;

  const _PaletteRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppPalette.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final palette = AppPalette.values[index];
          final selected = theme.palette == palette;
          return Semantics(
            button: true,
            selected: selected,
            label: palette.label,
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('theme-palette-${palette.name}'),
              onTap: () => theme.setPalette(palette),
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colors.primaryText : colors.divider,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    palette.label,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          selected ? colors.primaryText : colors.secondaryText,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
