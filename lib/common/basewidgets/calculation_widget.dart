import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class CalculationWidget extends StatelessWidget {
  final String? title;
  final double? amount;
  final bool isTotalAmount;
  final Function? onTap;
  const CalculationWidget({super.key, this.title, this.amount, this.isTotalAmount = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap as void Function()?,
      child: Padding(
        padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Row(
          children: [
            Container(height: 100, width: MediaQuery.sizeOf(context).width / 3.6,
              padding:  EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Get.find<ThemeController>().darkTheme ? Theme.of(context).primaryColor : Theme.of(context).cardColor.withValues(alpha:.09),
                border: Border.all(color: Get.find<ThemeController>().darkTheme ? Theme.of(context).highlightColor : Theme.of(context).cardColor.withValues(alpha:.09),),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                boxShadow: [
                  BoxShadow(
                    color: Get.find<ThemeController>().darkTheme ? Theme.of(context).highlightColor : Theme.of(context).cardColor.withValues(alpha:.02),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('${Get.find<SplashController>().myCurrency?.symbol ?? ''} ${NumberFormat.compact().format(double.tryParse(PriceConverter.convertPriceWithoutSymbol(context, amount)) ?? 0)}',style:
                    rubikBold.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white,
                        fontSize: Dimensions.fontSizeHeading)),
                     SizedBox(height: Dimensions.paddingSizeMin),

                    Text(title ?? '',maxLines : 2,textAlign: TextAlign.center,
                      style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Colors.white,
                          fontSize: Dimensions.fontSizeExtraSmall, overflow: TextOverflow.ellipsis),),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}