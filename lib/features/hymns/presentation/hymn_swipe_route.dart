import 'package:flutter/material.dart';

/// How long a swiped hymn takes to arrive.
///
/// Short, because the reader is turning pages rather than navigating: a
/// full-length push makes a hymnal feel like a website.
const Duration hymnSwipeDuration = Duration(milliseconds: 260);

/// The next or previous hymn, arriving from the side the reader swiped.
///
/// A plain `MaterialPageRoute` animates one way whichever way the hand
/// went, so turning back through the book looked exactly like turning on
/// through it. [forward] is true for the next hymn — swiped leftwards, so
/// the page comes in from the right — and false for the previous one,
/// which comes in from the left.
Route<T> hymnSwipeRoute<T>({
  required Widget page,
  required bool forward,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: hymnSwipeDuration,
    reverseTransitionDuration: hymnSwipeDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      // The hymn being left behind slides the opposite way, so the two
      // move together as one gesture rather than one sliding over a
      // page that is standing still.
      final leaving = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(forward ? -0.25 : 0.25, 0),
        ).animate(leaving),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(forward ? 1 : -1, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}
