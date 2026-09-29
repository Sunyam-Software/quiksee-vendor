
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/utill/dimensions.dart';


class CameraOrGalleryWidget extends StatefulWidget {
  final OrderModel? orderModel;
  final double? totalPrice;

  const CameraOrGalleryWidget({super.key, this.orderModel, this.totalPrice});

  @override
  State<CameraOrGalleryWidget> createState() => _CameraOrGalleryWidgetState();
}

class _CameraOrGalleryWidgetState extends State<CameraOrGalleryWidget> {

  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: GetBuilder<OrderDetailsController>(builder: (orderController) {
        return Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            Container(height: 5, width: 50,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                color: Theme.of(context).disabledColor.withValues(alpha:0.5))),

            Padding(padding:  EdgeInsets.only(bottom: Dimensions.paddingSizeOverLarge, top: 50),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(child: InkWell(onTap: (){
                      orderController.gotoEndOfPage();
                      orderController.pickImage(camera: true);
                      Navigator.of(context).pop();
                    }, child:  Icon(CupertinoIcons.camera_fill, size: 75, color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor,)),
                  ),
                  Expanded(child: InkWell(onTap: (){
                      orderController.gotoEndOfPage();
                      orderController.pickImage();
                      Navigator.of(context).pop();
                    }, child: Icon(CupertinoIcons.photo_fill,  size: 75, color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor)),
                  ),
                ],
              ),
            )

          ]),
        );
      }),
    );
  }
}
