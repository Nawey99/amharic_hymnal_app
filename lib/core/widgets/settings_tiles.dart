// lib/core/widgets/settings_tiles.dart
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Reusable settings tile widget with icon, title, and description
class SettingsTile extends StatelessWidget {
  /// Shown before the title. Leave it out to line the title up with switch
  /// tiles in the same section.
  final IconData? icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool showTrailingIcon;

  /// Replaces the chevron, for a tile that acts in place (such as a
  /// download) instead of opening a page.
  final IconData? trailingIcon;

  /// From 0 to 1 while work the tile started is under way: shown as a bar
  /// under the description, with [onStop] in place of the trailing icon.
  final double? progress;

  /// Replaces the percentage under the bar, e.g. while waiting to start.
  final String? progressLabel;

  final VoidCallback? onStop;

  const SettingsTile({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.showTrailingIcon = true,
    this.trailingIcon,
    this.progress,
    this.progressLabel,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: context.appColors.glassOpacity,
      padding: EdgeInsets.symmetric(
        horizontal: compactLandscape ? 14 : 16,
        vertical: compactLandscape ? 8 : 12,
      ),
      onTap: progress == null ? (onTap ?? () {}) : null,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: context.appColors.accent,
              size: compactLandscape ? 22 : 24,
            ),
            SizedBox(width: compactLandscape ? 12 : 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.primaryText,
                  ),
                ),
                SizedBox(height: compactLandscape ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.secondaryText,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: context.appColors.accent,
                      backgroundColor:
                          context.appColors.veil.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressLabel ?? '${(progress! * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (progress != null && onStop != null)
            IconButton(
              tooltip: AppLocalizations.of(context)?.stop ?? 'አቁም',
              onPressed: onStop,
              icon: Icon(
                Icons.stop_circle_outlined,
                color: context.appColors.primaryText,
              ),
            )
          else if (trailingIcon != null) ...[
            const SizedBox(width: 12),
            Icon(
              trailingIcon,
              color: context.appColors.accent,
              size: compactLandscape ? 24 : 28,
            ),
          ] else if (showTrailingIcon)
            Icon(Icons.chevron_right, color: context.appColors.secondaryText),
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
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: context.appColors.glassOpacity,
      padding: EdgeInsets.symmetric(
        horizontal: compactLandscape ? 14 : 16,
        vertical: compactLandscape ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.primaryText,
                  ),
                ),
                SizedBox(height: compactLandscape ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// The app's switch. Off is a choice, not a disabled control, so the thumb
/// stays bright and the track visible.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : context.appColors.primaryText.withValues(alpha: 0.9),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? context.appColors.accent
            : context.appColors.veil.withValues(alpha: 0.16),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : context.appColors.veil.withValues(alpha: 0.42),
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
        final stackControls = constraints.maxWidth < 390;
        final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
        final menuWidth = stackControls ? constraints.maxWidth : 220.0;
        final dropdownWidth = stackControls
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appColors.primaryText,
              ),
            ),
            SizedBox(height: compactLandscape ? 2 : 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.secondaryText,
              ),
            ),
          ],
        );

        final dropdown = SizedBox(
          width: dropdownWidth,
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            isExpanded: true,
            dropdownColor: context.appColors.surface,
            borderRadius: BorderRadius.circular(14),
            menuMaxHeight: 320,
            icon: Icon(
              Icons.expand_more,
              color: context.appColors.accent,
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryText,
              fontFamily: 'NotoSansEthiopic',
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.appColors.surface.withValues(alpha: 0.72),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compactLandscape ? 8 : 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: context.appColors.divider.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: context.appColors.divider.withValues(alpha: 0.55),
                  width: 1,
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
                    style: TextStyle(
                      color: context.appColors.primaryText,
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
                        ? context.appColors.accent
                        : context.appColors.primaryText,
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
          opacity: context.appColors.glassOpacity,
          padding: EdgeInsets.symmetric(
            horizontal: compactLandscape ? 14 : 16,
            vertical: compactLandscape ? 8 : 12,
          ),
          child: stackControls
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    SizedBox(height: compactLandscape ? 8 : 12),
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
class SettingsSliderTile extends StatefulWidget {
  final String title;
  final double value;
  final double min;
  final double max;

  /// Whole steps, so the number beside the slider is exactly what the
  /// reader gets.
  final int? divisions;

  /// Shows the number beside the title when it is not null.
  final String? highlight;

  /// Drawn under the slider and rebuilt as it moves: what the reader is
  /// choosing, rather than a number standing for it.
  final Widget Function(BuildContext context, double value)? previewBuilder;

  /// Called when the reader lets go. The value is not written on every
  /// frame of a drag: that was thirty-odd saves and as many rebuilds of
  /// the whole app for one gesture, none of which anyone could see.
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.highlight,
    this.previewBuilder,
    required this.onChanged,
  });

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  /// Where the reader's finger is, while it is down.
  double? _dragging;

  @override
  void didUpdateWidget(SettingsSliderTile old) {
    super.didUpdateWidget(old);
    // The choice has arrived back from the setting it was saved in.
    if (_dragging != null && (widget.value - _dragging!).abs() < 0.01) {
      _dragging = null;
    }
  }

  double get _safeValue {
    final value = _dragging ?? widget.value;
    if (!value.isFinite || value.isNaN) return widget.min;
    return value.clamp(widget.min, widget.max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    final value = _safeValue;

    return GlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      opacity: context.appColors.glassOpacity,
      padding: EdgeInsets.symmetric(
        horizontal: compactLandscape ? 14 : 16,
        vertical: compactLandscape ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.primaryText,
                  ),
                ),
              ),
              if (widget.highlight != null)
                Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.accent,
                  ),
                ),
            ],
          ),
          SizedBox(height: compactLandscape ? 4 : 8),
          Slider(
            value: value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: context.appColors.accent,
            onChanged: (next) => setState(() => _dragging = next),
            onChangeEnd: widget.onChanged,
          ),
          if (widget.previewBuilder != null) ...[
            SizedBox(height: compactLandscape ? 4 : 8),
            widget.previewBuilder!(context, value),
          ],
        ],
      ),
    );
  }
}
