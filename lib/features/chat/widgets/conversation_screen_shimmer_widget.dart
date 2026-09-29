import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee/utill/dimensions.dart';

class ConversationScreenShimmerWidget extends StatelessWidget {
  const ConversationScreenShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      itemBuilder: (_, index) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
          padding: EdgeInsets.all(Dimensions.paddingSizeMin).copyWith(right: Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.chatProfileSize),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).disabledColor.withValues(alpha:0.3),
            highlightColor: Theme.of(context).hintColor.withValues(alpha:0.2),
            child: Row(children: [

              Container(height: 50, width: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha:0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha:0.15),
                    width: 1.2,
                  ),
                ),
              ),
              SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [

                  Expanded(
                    child: Container(
                      height: 12,
                      color: Theme.of(context).hintColor.withValues(alpha:0.4),
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingSizeDefault),

                  Container(
                    height: 10,
                    width: 40,
                    color: Theme.of(context).hintColor.withValues(alpha:0.4),
                  ),
                ]),
                SizedBox(height: Dimensions.paddingSizeSmall),

                Container(
                  height: 10,
                  width: double.infinity,
                  color: Theme.of(context).hintColor.withValues(alpha:0.4),
                ),
              ])),
            ]),
          ),
        );
      },
    );
  }
}
