import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class QuikseeButtonWidget extends StatelessWidget {
  final Function? onTap;
  final String btnTxt;
  final bool isShowBorder;
  final bool transparent;
  final bool withIcon;
  final IconData? icon;

  const QuikseeButtonWidget({super.key, this.onTap, required this.btnTxt, this.isShowBorder = false, this.transparent = false, this.withIcon = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final textColor = Get.isDarkMode
        ? Theme.of(context).textTheme.bodyLarge?.color
        : isShowBorder
            ? Theme.of(context).textTheme.bodyLarge!.color
            : Theme.of(context).cardColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap as void Function()?,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          height: 50,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: !isShowBorder
                    ? Get.isDarkMode
                        ? Theme.of(context).primaryColor.withValues(alpha: .5)
                        : Colors.grey.withValues(alpha: 0.2)
                    : Colors.transparent,
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, 1),
              ),
            ],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isShowBorder && !transparent
                  ? ColorHelper.blendColors(
                      Colors.white, Theme.of(context).hintColor, 0.6)
                  : Colors.transparent,
            ),
            color: !isShowBorder
                ? Get.isDarkMode
                    ? ColorHelper.blendColors(
                            Colors.white, Theme.of(context).primaryColor, 0.9)
                        .withValues(alpha: .8)
                    : Theme.of(context).primaryColor
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (withIcon)
                Icon(
                  icon,
                  color: Get.isDarkMode
                      ? Theme.of(context).hintColor.withValues(alpha: .5)
                      : Theme.of(context).cardColor,
                ),
              Text(
                btnTxt,
                style: rubikBold.copyWith(
                  color: textColor,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
