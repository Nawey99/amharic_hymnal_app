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

/// Reusable settings dropdown tile widget.
/// Uses a true dropdown selector so the value is not editable text.
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
        final menuWidth = compact ? constraints.maxWidth : 220.0;
        final dropdownWidth = compact
            ? constraints.maxWidth
            : menuWidth.clamp(160.0, constraints.maxWidth);
        final values =
            items.map((item) => item.value).whereType<String>().toSet();
        final selectedValue = values.contains(value)
            ? value
            : (values.isEmpty ? null : values.first);

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

        final dropdown = SizedBox(
          width: dropdownWidth,
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            menuMaxHeight: 320,
            icon: const Icon(
              Icons.expand_more,
              color: AppColors.accentGreen,
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              fontFamily: 'NotoSansEthiopic',
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.72),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentGreen,
                  width: 1.4,
                ),
              ),
            ),
            selectedItemBuilder: (context) {
              return items.map((item) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _labelForItem(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                );
              }).toList();
            },
            items: items.map((item) {
              final isSelected = item.value == selectedValue;
              return DropdownMenuItem<String>(
                value: item.value,
                child: Text(
                  _labelForItem(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
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

  String _labelForItem(DropdownMenuItem<String> item) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? item.value ?? '';
    }
    return item.value ?? '';
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
