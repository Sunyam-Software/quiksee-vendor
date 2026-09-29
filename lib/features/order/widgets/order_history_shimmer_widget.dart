import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:shimmer/shimmer.dart';

class OrderHistoryShimmer extends StatelessWidget {
  const OrderHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    Color base = Theme.of(context).disabledColor.withValues(alpha:0.3);
    Color highlight = Theme.of(context).hintColor.withValues(alpha:0.2);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      itemCount: 10,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: Dimensions.paddingSizeLarge,
            right: Dimensions.paddingSizeLarge,
            bottom: Dimensions.paddingSizeSmall,
          ),
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).hintColor.withValues(alpha:0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Order ID and Call & Chat
                  Padding(
                    padding: EdgeInsets.only(left: 7, top: Dimensions.paddingSizeSmall),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            height: 18,
                            width: 120,
                            color: Theme.of(context).hintColor.withValues(alpha:0.5),
                          ),
                        ),
                        SizedBox(width: Dimensions.paddingSizeExtraLarge),

                        Row(children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context).hintColor.withValues(alpha:0.5),
                            ),
                          ),
                          SizedBox(width: Dimensions.paddingSizeSmall),

                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context).hintColor.withValues(alpha:0.5),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  SizedBox(height: Dimensions.paddingSizeDefault),

                  /// Customer Info Section
                  Padding(
                    padding: EdgeInsets.only(
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                      bottom: Dimensions.paddingSizeSmall,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Row(children: [
                        Container(height: 14, width: 14, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                        SizedBox(width: Dimensions.radiusSmall),

                        Container(height: 14, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                      ]),
                      SizedBox(height: Dimensions.paddingSizeSmall),

                      Padding(
                        padding: EdgeInsets.only(left: Dimensions.paddingSizeLarge),
                        child: Row(children: [
                          Container(height: 12, width: 100, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                          SizedBox(width: Dimensions.paddingSizeSmall),

                          Container(height: 20, width: 20, decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).hintColor.withValues(alpha:0.5),
                          )),
                        ]),
                      ),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Container(margin: EdgeInsets.only(left: Dimensions.paddingSizeLarge),height: 10, width: double.infinity, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    ]),
                  ),

                  /// Assigned Date Row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Column(children: [

                      Row(children: [
                        Container(
                          height: 14,
                          width: 14,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                        SizedBox(width: Dimensions.paddingSizeSmall),

                        Container(
                          height: 10,
                          width: 70,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                        SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Container(
                          height: 10,
                          width: 90,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                      ]),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Row(children: [
                        Container(
                          height: 14,
                          width: 14,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                        SizedBox(width: Dimensions.paddingSizeSmall),

                        Container(
                          height: 10,
                          width: 70,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                        SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Container(
                          height: 10,
                          width: 90,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                      ]),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
