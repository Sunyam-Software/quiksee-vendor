import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:quiksee/utill/dimensions.dart';

class OrderDetailsShimmer extends StatelessWidget {
  const OrderDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).disabledColor.withValues(alpha:0.15);

    return Shimmer.fromColors(
      baseColor: Theme.of(context).disabledColor.withValues(alpha:0.3),
      highlightColor: Theme.of(context).hintColor.withValues(alpha:0.2),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        children: [
          // 2. SellerInfoWidget placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: Row(
              children: [
                Container(height: 50, width: 50, color: Theme.of(context).hintColor.withValues(alpha:0.5), margin: EdgeInsets.only(right: Dimensions.paddingSizeSmall)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 15, width: 120, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Container(height: 10, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 3. OrderInfoWidget placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: Column(children: List.generate(5, (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(children: [
                Container(height: 12, width: 200, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                const Spacer(),

                Container(height: 12, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
              ]),
            ))),
          ),

          // 4. DeliveryInfoWidget placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: Column(children: List.generate(5, (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(children: [
                Container(height: 12, width: 150, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                const Spacer(),

                Container(height: 12, width: 120, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
              ]),
            ))),
          ),

          // 5. PaymentInfoWidget placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(height: 12, width: 140, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    const Spacer(),

                    Container(height: 20, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),
                ...List.generate(6, (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(height: 12, width: 150, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                      const Spacer(),

                      Container(height: 12, width: 70, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    ],
                  ),
                )),
                SizedBox(height: Dimensions.paddingSizeSmall),
                Container(height: 15, width: double.infinity, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
              ],
            ),
          ),

          // 6. ChangeAmountWidget placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            ),
            child: Container(height: 15, width: 180, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
          ),

          // 7. Additional delivery charge container placeholder
          Container(
            margin: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 5,
                spreadRadius: 1,
              )],
            ),
            child: Row(
              children: [
                Expanded(child: Container(height: 12, width: 160, color: Theme.of(context).hintColor.withValues(alpha:0.5))),
                SizedBox(width: Dimensions.paddingSizeSmall),
                DottedBorder(
                  options: RoundedRectDottedBorderOptions (
                    color: Theme.of(context).hintColor.withValues(alpha:0.5),
                    radius: const Radius.circular(50),
                  ),
                  child: const SizedBox(
                    height: 30,
                    width: 90,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeLarge), // padding before bottom button

          // 9. Bottom button placeholder
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            ),
          ),
        ],
      ),
    );
  }
}
