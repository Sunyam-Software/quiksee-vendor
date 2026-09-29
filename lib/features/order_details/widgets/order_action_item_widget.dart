import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:get/get.dart';

class OrderActionItemWidget extends StatelessWidget {
  final String? icon;
  final String? title;
  final Function() onTap;
  const OrderActionItemWidget({super.key, this.icon, this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: ()=> onTap(),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
                width: 50, height:50, decoration: BoxDecoration(
                  color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).cardColor.withValues(alpha:.75),
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                  boxShadow: [BoxShadow(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.125) : Theme.of(context).primaryColor.withValues(alpha:.125),
                      blurRadius: 5, spreadRadius: 1)],
                ),child: SizedBox(width: 20, child: Image.asset(icon!))),
             SizedBox(height: Dimensions.paddingSizeSmall),
            Text(title??''.tr),

          ])),
      ),
    );
  }
}