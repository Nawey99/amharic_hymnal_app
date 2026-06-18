// lib/core/widgets/settings_tiles.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Reusable settings tile widget with icon, title, and description
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool showTrailingIcon;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap ?? () {},
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (showTrailingIcon)
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}

/// Reusable settings switch tile widget
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Reusable settings dropdown tile widget with Material 3 MenuAnchor
/// Provides modern, consistent dropdown UI with smooth animations
class SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final menuWidth = compact ? constraints.maxWidth - 32 : 190.0;

        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        );

        final dropdown = Theme(
          data: Theme.of(context).copyWith(
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.surface),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                elevation: WidgetStateProperty.all(8),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          child: DropdownMenu<String>(
            initialSelection: value,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(AppColors.surface),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevation: WidgetStateProperty.all(8),
              maximumSize: WidgetStateProperty.all(
                const Size(
                    double.infinity, 300), // Prevent overflow on small screens
              ),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
              fontFamily: 'NotoSansEthiopic',
            ),
            dropdownMenuEntries: items.map((item) {
              // Extract text from child widget if it exists
              String itemText;
              if (item.child is Text) {
                itemText = (item.child as Text).data ?? item.value ?? '';
              } else {
                itemText = item.value ?? '';
              }

              return DropdownMenuEntry<String>(
                value: item.value ?? '',
                label: itemText,
                style: MenuItemButton.styleFrom(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: item.value == value
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: item.value == value
                        ? AppColors.accentGreen
                        : AppColors.primaryText,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                ),
              );
            }).toList(),
            onSelected: onChanged,
            width: menuWidth.clamp(150.0, 220.0),
            leadingIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.accentGreen,
              size: 24,
            ),
          ),
        );

        return GlassContainer(
          borderRadius: 16,
          blurSigma: 12,
          opacity: 0.12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: 12),
                    dropdown,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: label),
                    const SizedBox(width: 16),
                    dropdown,
                  ],
                ),
        );
      },
    );
  }
}

/// Reusable settings slider tile widget
class SettingsSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String? highlight;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.highlight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Clamp value BEFORE any widget construction to prevent Slider assertion errors
    // Handle NaN, infinity, and out-of-range cases with maximum defensive programming

    double safeValue;

    // First, handle non-finite values
    if (!value.isFinite || value.isNaN) {
      safeValue = min;
    } else if (value < min) {
      safeValue = min;
    } else if (value > max) {
      safeValue = max;
    } else {
      safeValue = value;
    }

    // Double-clamp to be absolutely sure
    final clampedValue = safeValue.clamp(min, max);

    // Final validation with explicit range check
    double finalValue;
    if (clampedValue >= min && clampedValue <= max && clampedValue.isFinite) {
      finalValue = clampedValue;
    } else {
      // Fallback to min if anything is wrong
      finalValue = min;
    }

    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (highlight != null)
                Text(
                  finalValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: finalValue,
            min: min,
            max: max,
            activeColor: AppColors.accentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
