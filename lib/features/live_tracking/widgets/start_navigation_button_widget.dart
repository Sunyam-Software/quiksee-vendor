import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class StartNavigationButtonWidget extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const StartNavigationButtonWidget({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Theme.of(context).cardColor,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        icon: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).cardColor,
                ),
              )
            : const Icon(Icons.navigation_rounded, size: 16),
        label: Text(
          loading ? 'opening_maps'.tr : 'start_navigation'.tr,
          style: rubikMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }
}
