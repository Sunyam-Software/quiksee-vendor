import 'package:flutter/material.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/utill/dimensions.dart';

class RoundBorderIconWidget extends StatelessWidget {
  final String image;
  final Color? backgroundColor;
  const RoundBorderIconWidget({
    super.key,
    required this.image,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              offset: const Offset(0, 3),
              color: Theme.of(context).hintColor.withValues(alpha: .08),
            )
          ],
        ),
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: QuikseeAssetImageWidget(image),
      ),
    );
  }
}
