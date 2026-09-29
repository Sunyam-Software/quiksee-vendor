import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee/utill/dimensions.dart';

class ReviewCardShimmerWidget extends StatelessWidget {
  const ReviewCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Color base = Theme.of(context).disabledColor.withValues(alpha:0.40);
    Color highlight = Theme.of(context).disabledColor.withValues(alpha:0.10);

    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                color: Theme.of(context).hintColor.withValues(alpha: 0.15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Order ID + Date
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(height: 14, width: 80, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    Row(children: [
                      Container(height: 14, width: 14, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                      SizedBox(width: Dimensions.paddingSizeSmall),

                      Container(height: 14, width: 70, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    ]),
                  ]),
                  SizedBox(height: Dimensions.paddingSizeDefault),

                  /// Customer row
                  Row(children: [
                    Container(height: 30, width: 30, decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Theme.of(context).hintColor.withValues(alpha:0.5),
                    )),
                    SizedBox(width: Dimensions.paddingSizeSmall),

                    Container(height: 14, width: 100, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                  ]),
                  SizedBox(height: Dimensions.paddingSizeDefault),

                  /// Comment block
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Column(
                      children: List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(height: 10, width: double.infinity, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                      )),
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),

                  /// Rating and bookmark row
                  Row(children: [
                    Container(height: 14, width: 120, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                    const Spacer(),

                    Container(height: 20, width: 20, color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
