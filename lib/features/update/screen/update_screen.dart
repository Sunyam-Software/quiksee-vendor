import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            Image.asset(
              color: Theme.of(context).primaryColor,
              Images.update,
              width: MediaQuery.of(context).size.height*0.4,
              height: MediaQuery.of(context).size.height*0.4,
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.01),

            Text(
              'update'.tr,
              style: robotoBold.copyWith(fontSize: MediaQuery.of(context).size.height*0.023, color: Theme.of(context).primaryColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.01),

            Text(
              'your_app_is_deprecated'.tr,
              style: robotoRegular.copyWith(fontSize: MediaQuery.of(context).size.height*0.0175, color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.04),

            QuikseeButtonWidget(btnTxt: 'update_now'.tr, onTap: () async {
              String? appUrl = 'https://google.com';
              if(Platform.isAndroid) {
                appUrl = Get.find<SplashController>().configModel?.deliveryManAppVersionControl?.forAndroid.link;
              }else if(Platform.isIOS) {
                appUrl = Provider.of<SplashController>(context, listen: false).configModel?.deliveryManAppVersionControl?.forIos.link;
              }
              if(await canLaunchUrlString(appUrl!)) {
                launchUrlString(appUrl, mode: LaunchMode.externalApplication);
              }else {
                showQuikseeSnackBarWidget('${'can_not_launch'.tr}  $appUrl');
              }
            }),

          ]),
        ),
      ),
    );
  }
}
