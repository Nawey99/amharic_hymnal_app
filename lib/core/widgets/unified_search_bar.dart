// lib/core/widgets/unified_search_bar.dart
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/amharic_transliteration_service.dart';
import 'package:amharic_hymnal_app/core/utils/script_detector.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// Unified search bar widget with consistent styling and behavior
///
/// Features:
/// - Consistent glassmorphism design
/// - Proper rounded corners with ClipRRect
/// - Auto-focus support
/// - Clear button
/// - Real-time search (no debounce - handled by SearchStateController)
/// - Unicode-safe Amharic input handling
/// - Smart formatter (only for transliteration, not direct Amharic)
/// 
/// NOTE: This widget is deprecated. Use SearchTextField with SearchStateController instead.
/// This widget is kept for backward compatibility but debounce logic has been removed.
class UnifiedSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enableTransliteration; // Allow transliteration mode

  const UnifiedSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enableTransliteration = true, // Default enabled
  });

  @override
  State<UnifiedSearchBar> createState() => _UnifiedSearchBarState();
}

class _UnifiedSearchBarState extends State<UnifiedSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isControllerExternal = false;
  bool _isFocusNodeExternal = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _isControllerExternal = widget.controller != null;
    _isFocusNodeExternal = widget.focusNode != null;
    
    // Listen to text changes (no debounce - handled by SearchStateController)
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (!_isControllerExternal) {
      _controller.dispose();
    }
    if (!_isFocusNodeExternal) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    // Emit changes immediately (no debounce - use SearchStateController for debouncing)
    widget.onChanged?.call(_controller.text);
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  /// Determine if we should use transliteration formatter
  /// Only use formatter if:
  /// 1. Transliteration is enabled
  /// 2. Current text is empty or contains only Latin characters
  /// 3. User is typing Latin (not Amharic)
  bool _shouldUseFormatter() {
    if (!widget.enableTransliteration) return false;
    
    final text = _controller.text;
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
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            // Use formatter conditionally - only for transliteration, not direct Amharic
            inputFormatters: _shouldUseFormatter()
                ? [AmharicTransliterationFormatter()]
                : null,
            // Unicode support for Amharic (Ge'ez script)
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done, // No search action - real-time search
            enableSuggestions: false, // Prevent keyboard interference with Amharic
            autocorrect: false, // Prevent autocorrect interference
            // NO onSubmitted - real-time search only
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
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryText),
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (_, value, __) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Show clear button (no loading indicator - real-time search)
        return IconButton(
          icon: const Icon(Icons.clear, color: AppColors.primaryText),
          onPressed: _handleClear,
          tooltip: 'Clear search',
        );
      },
    );
  }
}
