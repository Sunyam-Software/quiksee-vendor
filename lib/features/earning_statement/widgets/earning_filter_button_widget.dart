import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/features/earning_statement/widgets/earning_filter_type_button_widget.dart';
import 'package:get/get.dart';


class EarningFilterButtonWidget extends StatefulWidget {
  const EarningFilterButtonWidget({super.key});

  @override
  State<EarningFilterButtonWidget> createState() => _EarningFilterButtonWidgetState();
}

class _EarningFilterButtonWidgetState extends State<EarningFilterButtonWidget> {

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
        child: Container(height: 60, decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha: .075), borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat)),
            child: Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeMin),
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal, children: [
                EarningFilterTypeButtonWidget(text: 'all_order'.tr, index: 0),

                EarningFilterTypeButtonWidget(text: 'todays'.tr, index: 1),

                EarningFilterTypeButtonWidget(text: 'this_week'.tr, index: 2),

                EarningFilterTypeButtonWidget(text: 'this_month'.tr, index: 3),
              ],
              ),
            )),
      ),
    );
  }
}
