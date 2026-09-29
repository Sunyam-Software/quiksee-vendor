import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee/utill/dimensions.dart';

class WithdrawCardShimmerWidget extends StatelessWidget {
  const WithdrawCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Centralized shimmer colors
    Color base = Theme.of(context).disabledColor.withValues(alpha:0.3);
    Color highlight = Theme.of(context).hintColor.withValues(alpha:0.2);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      itemCount: 10,
      physics: const BouncingScrollPhysics(),
    itemBuilder: (context, index) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
        ),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon, Date and Amount Row
              Row(
                children: [
                  Container(
                    width: Dimensions.iconSizeDefault,
                    height: Dimensions.iconSizeDefault,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Container(
                      height: 12,
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingSizeSmall),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                    ),
                    child: const SizedBox(
                      height: 14,
                      width: 80,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Dimensions.paddingSizeLarge),

              // Divider line
              Container(
                height: 0.5,
                color: Theme.of(context).hintColor.withValues(alpha:0.5),
              ),
            ],
          ),
        ),
      );
    });
  }
}
