import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart' as config;
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final SplashController splashController = Get.find<SplashController>();
      splashController.getConfigData().then((bool isSuccess) {
        if(isSuccess){
          final config = splashController.configModel!;
          if(config.maintenanceModeData?.maintenanceStatus == 0) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen(pageIndex: 0)));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final config.ConfigModel? configModel = Get.find<SplashController>().configModel;

    return Scaffold(
      body: Padding(padding: EdgeInsets.all(MediaQuery.of(context).size.height*0.025),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(Images.maintenance, width: 200, height: 200),

            if(configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage != null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isNotEmpty)...[
              Text(configModel.maintenanceModeData?.maintenanceMessages?.maintenanceMessage ?? '', style: rubikBold.copyWith(
                fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeExtraSmall),
            ],


            if(configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage == null || (configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage == null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isEmpty))...[
              Text('maintenance_title'.tr, style: rubikBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                textAlign: TextAlign.center,
              ),
            ],


           if(configModel?.maintenanceModeData?.maintenanceMessages?.messageBody != null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isNotEmpty)...[
              Text(configModel.maintenanceModeData?.maintenanceMessages?.messageBody ?? '' , textAlign: TextAlign.center, style: rubikRegular),
              SizedBox(height: size.height * 0.07),
            ],


            if(configModel?.maintenanceModeData?.maintenanceMessages?.messageBody == null || (configModel?.maintenanceModeData?.maintenanceMessages?.messageBody == null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isEmpty) )...[
              Text('maintenance_body'.tr, textAlign: TextAlign.justify, style: rubikRegular),
              SizedBox(height: size.height * 0.07),
            ],


            if(configModel?.maintenanceModeData?.maintenanceMessages?.businessEmail == 1 ||
            configModel?.maintenanceModeData?.maintenanceMessages?.businessNumber == 1) ...[

            if( (configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage != null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isNotEmpty) ||
            (configModel?.maintenanceModeData?.maintenanceMessages?.messageBody != null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isNotEmpty)) ...[

              Row(
                children: List.generate(size.width ~/ 10, (index) => Expanded(
                child: Container(
                color: index % 2==0 ? Colors.transparent :Theme.of(context).hintColor.withValues(alpha:0.2), height: 2),
                )),
              ),
              SizedBox(height: Dimensions.paddingSizeExtraLarge),
              ],


              if(configModel?.maintenanceModeData?.maintenanceMessages?.businessNumber == 1 || configModel?.maintenanceModeData?.maintenanceMessages?.businessEmail == 1)...[
                Text('any_query_feel_free_to_call'.tr,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),
              ],


              if (configModel?.maintenanceModeData?.maintenanceMessages?.businessNumber == 1 )...[
                InkWell(
                  onTap: (){
                    launchUrl(Uri.parse(
                      'tel:${Get.find<SplashController>().configModel!.companyPhone}',
                    ), mode: LaunchMode.externalApplication);
                  },
                  child: Text(configModel?.companyPhone ?? "",
                    style: rubikRegular.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeDefault,
                      decoration: TextDecoration.underline,
                      decorationColor:  Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ],


              if(configModel!.maintenanceModeData?.maintenanceMessages?.businessEmail == 1)...[
                InkWell(
                  onTap: (){
                    launchUrl(Uri.parse(
                      'mailto:${Get.find<SplashController>().configModel!.companyEmail}',
                    ), mode: LaunchMode.externalApplication);
                  },

                  child: Text(configModel.companyEmail ?? "",
                    style: rubikRegular.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeDefault,
                      decoration: TextDecoration.underline,
                      decorationColor:  Theme.of(context).primaryColor,
                    ),
                  ),
                )
              ]

            ]
        ]),
        ),
      ),
    );
  }
}
