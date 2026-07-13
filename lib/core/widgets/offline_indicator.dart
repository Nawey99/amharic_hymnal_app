// lib/core/widgets/offline_indicator.dart
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/services/cache_service.dart';

/// Widget to display offline/cache status
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isHealthy = true;
  int _cachedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  Future<void> _checkCacheStatus() async {
    final healthy = await CacheService.isCacheHealthy();
    final count = await CacheService.getCachedHymnCount();
    if (mounted) {
      setState(() {
        _isHealthy = healthy;
        _cachedCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHealthy && _cachedCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentGreen.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.offline_pin,
              size: 14,
              color: AppColors.accentGreen,
            ),
            SizedBox(width: 4),
            Text(
              'Offline Ready',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
