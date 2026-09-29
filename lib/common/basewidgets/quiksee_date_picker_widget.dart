import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class QuikseeDatePickerWidget extends StatelessWidget {
  final String? text;
  final String? image;
  final bool requiredField;
  final Function? selectDate;
  final Color? iconColor;
  final Color? textColor;
  const QuikseeDatePickerWidget({super.key, this.text,this.image, this.requiredField = false, this.selectDate, this.iconColor, this.textColor,});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectDate != null ? ()=> selectDate!() : null,
      child: Container(
        margin: EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
        child: Container(
          height: 40,
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeExtraSmall,
            Dimensions.paddingSizeExtraSmall,
            0,
            Dimensions.paddingSizeExtraSmall,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SizedBox(
              width: Dimensions.iconSizeMenu,
              height: Dimensions.iconSizeMenu,
              child: Image.asset(image!, color: iconColor ?? (Get.isDarkMode ? null : Theme.of(context).cardColor)),
            ),
            SizedBox(width: Dimensions.paddingSizeSmall),

            Text(text!, style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: textColor ?? (text == 'yyyy-mm-dd' ?
              Theme.of(context).hintColor
                  : Get.isDarkMode
                  ? Theme.of(context).hintColor.withValues(alpha:.5)
                  : Theme.of(context).cardColor),
            )),
          ]),
        ),
      ),
    );
  }
}


