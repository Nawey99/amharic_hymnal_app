// lib/core/widgets/search_text_field.dart
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/services/amharic_transliteration_service.dart';
import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';
import 'package:amharic_hymnal_app/core/utils/script_detector.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// Pure UI-only search text field widget
///
/// Features:
/// - No debounce logic (handled by SearchStateController)
/// - No submit actions
/// - No search buttons
/// - Preserves Amharic Unicode exactly as typed
/// - No re-encoding
/// - No incorrect lowercasing of Amharic
/// - Proper text direction handling
///
/// Architecture: This widget is purely presentational. It emits text changes
/// to SearchStateController, which handles debouncing and state management.
class SearchTextField extends StatefulWidget {
  final SearchStateController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.focusNode,
    this.autofocus = false,
    this.onClear,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isFocusNodeExternal = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _isFocusNodeExternal = widget.focusNode != null;

    // Listen to text changes and update SearchStateController
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    if (!_isFocusNodeExternal) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    // Emit text changes to SearchStateController (no debounce here)
    widget.controller.updateQuery(_textController.text);
  }

  void _handleClear() {
    _textController.clear();
    widget.controller.clear();
    widget.onClear?.call();
  }

  /// Determine if we should use transliteration formatter
  /// Only use formatter if:
  /// 1. Current text is empty or contains only Latin characters
  /// 2. User is typing Latin (not Amharic)
  bool _shouldUseFormatter() {
    final text = _textController.text;
    if (text.isEmpty) return true; // Allow formatter for new input

    // Check if text contains Amharic characters
    final scriptType = ScriptDetector.detect(text);
    // Only use formatter if text is English (Latin script)
    // If user types Amharic directly, don't interfere
    return scriptType == ScriptType.english;
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepository = sl<SettingsRepository>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: GlassContainer(
          borderRadius: 20.0,
          blurSigma: 18.0,
          opacity: 0.25,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            // Use formatter conditionally - only for transliteration, not direct Amharic
            inputFormatters: _shouldUseFormatter()
                ? [AmharicTransliterationFormatter()]
                : null,
            // Unicode support for Amharic (Ge'ez script)
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            enableSuggestions:
                false, // Prevent keyboard interference with Amharic
            autocorrect: false, // Prevent autocorrect interference
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: settingsRepository.getFontSize(),
              fontFamily: 'NotoSansEthiopic',
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.tertiaryText,
                fontSize: settingsRepository.getFontSize() * 0.9,
                fontFamily: 'NotoSansEthiopic',
              ),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primaryText),
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            // Preserve Amharic Unicode exactly as typed
            // No re-encoding, no incorrect lowercasing
            textDirection: TextDirection.ltr, // Amharic is LTR
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textController,
      builder: (_, value, __) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show clear button (wrapped in Tooltip to prevent ticker issues)
        return Tooltip(
          message: 'Clear search',
          child: IconButton(
            icon: const Icon(Icons.clear, color: AppColors.primaryText),
            onPressed: _handleClear,
          ),
        );
      },
    );
  }
}
