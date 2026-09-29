import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_date_picker_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';

class OrderStatusUpdateDialogWidget extends StatefulWidget {
  final String icon;
  final String? title;
  final Function onYesPressed;
  final bool isReschedule;
  final bool isResume;
  final OrderActionType actionType;
  const OrderStatusUpdateDialogWidget({super.key, required this.icon, this.title, required this.onYesPressed, this.isReschedule = false, this.isResume = false, required this.actionType});

  @override
  State<OrderStatusUpdateDialogWidget> createState() => _OrderStatusUpdateDialogWidgetState();
}

class _OrderStatusUpdateDialogWidgetState extends State<OrderStatusUpdateDialogWidget> {

  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final controller = Get.find<OrderDetailsController>();

    if (widget.isResume && controller.getReason(widget.actionType) == null) {
      controller.setReason(widget.actionType, 'resume');
    }
  }

  @override
  Widget build(BuildContext context) {


    return Dialog(
      surfaceTintColor: Colors.black,
      shadowColor: Theme.of(context).highlightColor.withValues(alpha:.125),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: GetBuilder<OrderDetailsController>(
        builder: (orderController) {
          final selectedReason = orderController.getReason(widget.actionType);

          return Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Container(padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)),
                    child: Image.asset(widget.icon, width: Get.context!.width<= 400? 20 : 50,
                        height:Get.context!.width<= 400? 20 : 50))),

              widget.title != null ? Padding(
                padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Text(widget.title!, textAlign: TextAlign.center,
                  style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeDefault,
                      color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor))) : const SizedBox(),


              if(widget.isReschedule)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,horizontal: Dimensions.paddingSizeDefault),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.25)),
                    ),
                    child: QuikseeDatePickerWidget(
                      text: orderController.startDate != null
                          ? orderController.dateFormat.format(orderController.startDate!).toString()
                          : 'select_date'.tr,
                      image: Images.calenderIcon,
                      requiredField: true,
                      selectDate: () => orderController.selectDate(context),
                      iconColor: Theme.of(context).primaryColor,
                      textColor: orderController.startDate == null ? Theme.of(context).hintColor : Theme.of(context).textTheme.titleSmall?.color,
                    ),
                  ),
                ),


              widget.isResume ? const SizedBox():
              Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                child: Container(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(width: .5, color: Theme.of(context).hintColor.withValues(alpha:.7))),
                  child: DropdownButton<String>( menuMaxHeight: 300,
                      hint: selectedReason == null
                          ? Text('select_reason'.tr, style: rubikRegular)
                          : Text(selectedReason.tr, textAlign: TextAlign.justify, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, height: 1)),


                    items: orderController.reasonList.map((String value) {
                      return DropdownMenuItem<String>(
                        alignment: Alignment.centerLeft,
                          value: value,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(value.tr, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black)),
                              Divider(thickness: .25,color: Theme.of(context).hintColor, height: .1)
                          ]));}).toList(),
                    onChanged: (val) {
                      orderController.setReason(widget.actionType, val);
                      },
                    isExpanded: true,
                    underline: const SizedBox()))),

              orderController.getReason(widget.actionType) == 'other'?
              Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: QuikseeTextFieldWidget(isShowBorder: true,
                  controller: _reasonController)): const SizedBox.shrink(),

               SizedBox(height: Dimensions.paddingSizeLarge),

              QuikseeButtonWidget(btnTxt: 'submit'.tr, onTap: () {
                  if(orderController.getReason(widget.actionType) == null){
                    showQuikseeSnackBarWidget('reason_is_required'.tr);
                  }else{
                    widget.onYesPressed();
                  }
                },
              )
            ]),
          );
        }
      ),
    );
  }
}