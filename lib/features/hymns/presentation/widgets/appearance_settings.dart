import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme_spec.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/theme_carousel.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Chooses light or dark, and which colour family, and shows the choice
/// taking effect on the page underneath as it is made.
class AppearanceSettings extends StatelessWidget {
  final ThemeService? service;

  const AppearanceSettings({super.key, this.service});

  static const _modes = <(ThemeMode, IconData)>[
    (ThemeMode.light, Icons.light_mode_outlined),
    (ThemeMode.dark, Icons.dark_mode_outlined),
    (ThemeMode.system, Icons.phone_android_outlined),
  ];

  static String labelFor(BuildContext context, ThemeMode mode) {
    final words = AppLocalizations.of(context);
    return switch (mode) {
      ThemeMode.light => words?.themeModeLight ?? 'ብርሃን',
      ThemeMode.dark => words?.themeModeDark ?? 'ጨለማ',
      ThemeMode.system => words?.followThePhone ?? 'የስልኩ',
    };
  }

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
              AppLocalizations.of(context)?.appearanceLabel ?? 'ገጽታ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)?.appearanceDescription ??
                  'የመተግበሪያውን ብርሃን እና ቀለም ይምረጡ',
              style: TextStyle(
                fontSize: 12,
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            _ModeRow(theme: theme),
            if (AppThemeCatalog.themes.length > 1) ...[
              const SizedBox(height: 14),
              ThemeCarousel(theme: theme),
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
        for (final (mode, icon) in AppearanceSettings._modes)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ModeButton(
                key: ValueKey('theme-mode-${mode.name}'),
                label: AppearanceSettings.labelFor(context, mode),
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
