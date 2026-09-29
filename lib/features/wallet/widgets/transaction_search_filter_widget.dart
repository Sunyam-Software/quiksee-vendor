import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/common/basewidgets/quiksee_calender_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_date_picker_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';


class DeliverySearchFilterWidget extends StatelessWidget {
  final bool fromOrderHistory;
  const DeliverySearchFilterWidget({super.key, this.fromOrderHistory = false});

  @override
  Widget build(BuildContext context) {
    final double widthSize = MediaQuery.of(context).size.width;

    return GetBuilder<WalletController>(
      builder: (walletController) {
        return InkWell(
          onTap: () => Get.dialog(SizedBox(height: 400,
            child: QuikseeCalendarWidget(onSubmit: (PickerDateRange? range){
              walletController.selectDate(startDate: DateConverter.dateStringMonthYear(range?.startDate), endDate: DateConverter.dateStringMonthYear(range?.endDate));
              applyTransactionFilter(walletController, fromOrderHistory);
            }),
          )),
          child: Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            child: Row(children:  [
              Expanded(child: Container(
                height: widthSize / 8,
                padding:  EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                    ? Theme.of(context).dividerColor
                    : ColorHelper.darken(Theme.of(context).primaryColor, 0.03),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  FittedBox(
                    child: InkWell(
                      onTap: () => Get.dialog(QuikseeCalendarWidget(onSubmit: (PickerDateRange? range){
                        walletController.selectDate(startDate: DateConverter.dateStringMonthYear(range?.startDate), endDate: DateConverter.dateStringMonthYear(range?.endDate));
                        applyTransactionFilter(walletController, fromOrderHistory);
                      })),
                      child: QuikseeDatePickerWidget(text: walletController.startDate,
                        image: Images.calenderIcon,
                        selectDate:(){},
                      ),
                    ),
                  ),

                  Icon(Icons.arrow_forward_rounded, size: Dimensions.iconSizeMedium,
                      color: Get.isDarkMode ? ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9)  : Theme.of(context).cardColor),

                  FittedBox(
                    child: InkWell(
                      onTap: () => Get.dialog(QuikseeCalendarWidget(onSubmit: (PickerDateRange? range){
                        walletController.selectDate(startDate: DateConverter.dateStringMonthYear(range?.startDate), endDate: DateConverter.dateStringMonthYear(range?.endDate));
                        applyTransactionFilter(walletController, fromOrderHistory);
                      })),
                      child: QuikseeDatePickerWidget(text: walletController.endDate,
                          image: Images.calenderIcon),
                    ),
                  ),
                ]),
              )),
            ]),
          ),
        );
      }
    );
  }

}


void applyTransactionFilter(WalletController walletController, bool fromHistory){

  if(walletController.startDate == 'dd-mm-yyyy'){
    showQuikseeSnackBarWidget('select_start_date_first'.tr);
  }else if(walletController.endDate == 'dd-mm-yyyy'){
    showQuikseeSnackBarWidget('select_end_date_first'.tr);
  }else{
    if(fromHistory){
      Get.find<OrderController>().setOrderTypeIndex(Get.find<OrderController>().orderTypeIndex,
          startDate: walletController.startDate, endDate: walletController.endDate);
    }else{
      walletController.selectedItemForFilter(walletController.selectedItem);
    }
  }
}


