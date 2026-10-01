import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/language_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Chooses the language the app speaks in.
///
/// Separate from the hymns' language above it: the words of the app and
/// the words of the book are two different choices, and a reader may want
/// an English interface over an Amharic hymnal.
class LanguageSettings extends StatelessWidget {
  final LanguageService? service;

  const LanguageSettings({super.key, this.service});

  static const _choices = <(AppLanguage, IconData)>[
    (AppLanguage.amharic, Icons.translate_rounded),
    (AppLanguage.english, Icons.abc_rounded),
    (AppLanguage.system, Icons.phone_android_outlined),
  ];

  static String labelFor(BuildContext context, AppLanguage language) {
    final words = AppLocalizations.of(context);
    return switch (language) {
      // Each language names itself, so it can be recognised by someone
      // who cannot read the other.
      // verbatim: a language names itself
      AppLanguage.amharic => 'አማርኛ',
      AppLanguage.english => 'English',
      AppLanguage.system => words?.followThePhone ?? 'የስልኩ',
    };
  }

  @override
  Widget build(BuildContext context) {
    final language = service ?? LanguageService();
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => GlassContainer(
        borderRadius: 16,
        blurSigma: 12,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.appLanguageLabel ?? 'የመተግበሪያ ቋንቋ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)?.appLanguageDescription ??
                  'የመተግበሪያው ጽሑፍ ቋንቋ',
              style: TextStyle(
                fontSize: 12,
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (choice, icon) in _choices)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _LanguageButton(
                        key: ValueKey('app-language-${choice.storageValue}'),
                        label: labelFor(context, choice),
                        icon: icon,
                        selected: language.language == choice,
                        colors: colors,
                        onTap: () => language.setLanguage(choice),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  const _LanguageButton({
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
