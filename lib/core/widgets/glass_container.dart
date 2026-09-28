// lib/core/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';

/// A reusable glassmorphism container widget with frosted glass effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;

  /// How solid the frost is. Left unset, the palette decides, which is
  /// what lets a light palette use a heavier frost than a dark one.
  final double? opacity;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;

  /// Whether to frost what is behind the panel.
  ///
  /// True for the few panels that float over the page. False where
  /// panels repeat — a list row is a panel, and blurring each one costs
  /// a layer per row on every frame.
  final bool blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.blurSigma =
        8.0, // Reduced default from 10.0 to 8.0 for better performance
    this.opacity,
    this.color,
    this.border,
    this.onTap,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final frost = opacity ?? colors.glassOpacity;
    final radius = BorderRadius.circular(borderRadius);

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (color ?? colors.glassTint).withValues(alpha: frost * 1.5),
          (color ?? colors.glassTint).withValues(alpha: frost * 1.2),
        ],
      ),
      borderRadius: radius,
      border: border ?? Border.all(color: colors.glassBorder, width: 1.5),
      // A drop shadow is a blur of its own. A panel that floats can
      // afford one; a row in a list of three hundred cannot, and its
      // border already lifts it off the page.
      boxShadow: blur
          ? [
              BoxShadow(
                color: colors.glassShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );

    final panel = Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );

    // A panel that does not blur is a decoration and nothing more: no
    // layer to save, no backdrop to read, no clip. That matters where
    // panels are many — a list of hymns had one blur per row, and a
    // phone has to redraw all of them for every frame of a scroll.
    final Widget container = blur
        ? RepaintBoundary(
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      // Eight is as far as the frost is worth paying for.
                      filter: ImageFilter.blur(
                        sigmaX: blurSigma.clamp(0.0, 8.0),
                        sigmaY: blurSigma.clamp(0.0, 8.0),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  panel,
                ],
              ),
            ),
          )
        : panel;

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: context.appColors.veil.withValues(alpha: 0.1),
          highlightColor: context.appColors.veil.withValues(alpha: 0.05),
          child: container,
        ),
      );
    }

    return container;
  }
}

/// A glassmorphism card widget with elevated appearance
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      borderRadius: borderRadius,
      blurSigma: 12.0,
      // A card carries more frost than a plain panel, so its text holds
      // against the photograph behind it.
      opacity: context.appColors.glassOpacityOverPhoto,
      color: context.appColors.glassTint,
      onTap: onTap,
      child: child,
    );
  }
}

/// A glassmorphism button widget
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius = 12.0,
    this.opacity = 0.15,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassContainer(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          borderRadius: widget.borderRadius,
          blurSigma: 12.0,
          opacity: widget.opacity,
          child: widget.child,
        ),
      ),
    );
  }
}
