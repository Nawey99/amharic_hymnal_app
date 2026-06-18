// lib/core/widgets/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/services/amharic_transliteration_service.dart';

/// Reusable search bar widget with consistent styling
///
/// Features:
/// - Single rounded container (no nested boxes)
/// - Consistent padding and styling
/// - Keyboard type support
/// - Clear button
/// - Accessible tap targets (min 48x48)
/// - Platform-consistent appearance
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextInputType? keyboardType;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.keyboardType,
    this.autofocus = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    // Single clean container with Material 3 style - no nested boxes
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassContainer(
        borderRadius: 20.0,
        blurSigma: 12.0, // Reduced for better performance
        opacity: 0.2, // Slightly reduced for cleaner look
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Semantics(
          label: 'Search input',
          textField: true,
          hint: hintText,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            keyboardType: keyboardType ?? TextInputType.text,
            textInputAction:
                TextInputAction.done, // No search action - real-time search
            inputFormatters:
                inputFormatters ?? [AmharicTransliterationFormatter()],
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontFamily: 'NotoSansEthiopic',
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 14,
                fontFamily: 'NotoSansEthiopic',
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primaryText,
                size: 24,
              ),
              suffixIcon: _buildClearButton(),
              // Material 3 style - no borders, clean look
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              isDense: true, // Material 3 compact style
            ),
            onChanged: onChanged,
            // NO onSubmitted - real-time search only (no search button)
            textDirection: TextDirection.ltr, // Amharic is LTR
          ),
        ),
      ),
    );
  }

  Widget? _buildClearButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }

        // Ensure minimum 48x48 tap target for accessibility
        return SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(
              Icons.clear,
              color: AppColors.primaryText,
              size: 20,
            ),
            onPressed: () {
              controller.clear();
              onClear?.call();
            },
            tooltip: 'Clear search',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        );
      },
    );
  }
}
