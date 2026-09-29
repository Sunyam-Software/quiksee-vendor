import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee/utill/dimensions.dart';

class EarningStatementShimmerWidget extends StatelessWidget {
  const EarningStatementShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha:0.30);
    final Color highlight = Theme.of(context).hintColor.withValues(alpha:0.25);

    return  ListView.builder(
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
            0,
          ),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              ),
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                // Order ID and Payment Row
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(height: 14, width: 100, color: Theme.of(context).hintColor.withValues(alpha:0.5)),

                  Row(children: [
                    Container(height: 20, width: 20, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    SizedBox(width: Dimensions.paddingSizeSmall),

                    Container(height: 12, width: 50, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                  ]),
                ]),
                SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Date and Amount Row
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(height: 20, width: 20, color: Theme.of(context).hintColor.withValues(alpha:0.5),),
                    SizedBox(width: Dimensions.paddingSizeDefault),

                    Container(height: 12, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5),),
                  ]),
                  Container(height: 12, width: 60, color: Theme.of(context).hintColor.withValues(alpha:0.5),),
                ]),
                SizedBox(height: Dimensions.paddingSizeDefault),

                // View details button
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 30,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
