import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class QuikseeAppBrandWidget extends StatelessWidget {
  final double logoSize;
  final double? titleFontSize;
  final bool showAppName;
  final MainAxisAlignment alignment;

  const QuikseeAppBrandWidget({
    super.key,
    this.logoSize = 32,
    this.titleFontSize,
    this.showAppName = true,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(logoSize * 0.2),
          child: Image.asset(
            Images.logo,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
          ),
        ),
        if (showAppName) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Flexible(
            child: Text(
              AppConstants.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(
                fontSize: titleFontSize ?? Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
