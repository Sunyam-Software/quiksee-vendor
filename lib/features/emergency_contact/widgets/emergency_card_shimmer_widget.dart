import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee/utill/dimensions.dart';

class EmergencyContactCardShimmer extends StatelessWidget {
  const EmergencyContactCardShimmer({super.key});

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
          padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              color: Theme.of(context).hintColor.withValues(alpha:0.15),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha:0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Container(
                        height: 14,
                        width: 100,
                        color: Theme.of(context).hintColor.withValues(alpha:0.5),
                      ),
                    ),
                    SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(
                      children: [
                        Container(
                          height: 16,
                          width: 16,
                          color: Theme.of(context).hintColor.withValues(alpha:0.5),
                        ),
                        SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Shimmer.fromColors(
                          baseColor: base,
                          highlightColor: highlight,
                          child: Container(
                            height: 12,
                            width: 120,
                            color: Theme.of(context).hintColor.withValues(alpha:0.5),
                          ),
                        ),
                      ],
                    )
                  ],
                ),

                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
    
  }
}
