import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/online_offline_button_widget.dart';


class QuikseeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  static const Color _appBarLightGreen = Color(0xFFD2E7D7);
  static const Color _appBarGold = Color(0xFFA36A00);
  static const Color _appBarTitleGold = Color(0xFFD4A62A);

  final String? title;
  final bool isBack;
  final Function()? onTap;
  final bool isSwitch;
  final bool isCenterTitle;

  const QuikseeAppBarWidget({super.key, this.title, this.isBack = false, this.onTap, this.isSwitch  = false, this.isCenterTitle = true});

  @override
  Widget build(BuildContext context) {
    return  PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        backgroundColor: Get.isDarkMode ? Theme.of(context).cardColor : _appBarLightGreen,
        surfaceTintColor: Colors.transparent,
        centerTitle: isCenterTitle,
        leadingWidth: isBack ? null : 96,
        leading: isBack ? InkWell(onTap: onTap  ?? () => Get.back(),
            child: Icon(Icons.arrow_back_ios,color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : _appBarGold)) :
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Image.asset(
            Images.quikseeLogo,
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 0,
        elevation: 1,
        title: Text(title!.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikMedium.copyWith(
          color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : _appBarTitleGold, fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w700,)),
        actions:  [
          isSwitch?
          const OnlineOfflineButtonWidget(): const SizedBox(),
           SizedBox(width: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size(1170, 50);
}