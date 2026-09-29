import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:shimmer/shimmer.dart';

class TransactionCardShimmerWidget extends StatelessWidget {
  const TransactionCardShimmerWidget({super.key});

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
              Dimensions.paddingSizeMin,
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
                  // Order # and icon row
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
                      Container(
                        height: 18,
                        width: 120,
                        color: Theme.of(context).hintColor.withValues(alpha:0.5),
                      ),
                    ],
                  ),

                  SizedBox(height: Dimensions.paddingSizeSmall),

                  // Date and delivery man fee container row
                  Padding(
                    padding: EdgeInsets.only(left: Dimensions.paddingSizeOverLarge),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 14,
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
                            color: Theme.of(context).hintColor.withValues(alpha:0.5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                height: 12,
                                width: 80,
                              ),
                              SizedBox(width: Dimensions.paddingSizeSmall),

                              const SizedBox(
                                height: 14,
                                width: 50,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Dimensions.paddingSizeSmall),

                  // Order amount text
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeOverLarge,
                      0,
                      Dimensions.paddingSizeDefault,
                      0,
                    ),
                    child: Container(
                      height: 20,
                      width: 100,
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                    ),
                  ),

                  SizedBox(height: Dimensions.paddingSizeSmall),

                  // Divider
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
