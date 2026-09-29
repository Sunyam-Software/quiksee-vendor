import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_drop_down_item_widget.dart';
import 'package:quiksee_vendor_app/features/delivery_man/controllers/delivery_man_controller.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/features/order/widgets/delivery_man_assign_widget.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/features/order_details/domain/models/order_setup_model.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderSetupBottomSheet extends StatefulWidget {
  final Order? orderModel;
  final bool onlyDigital;
  final BuildContext bottomContext;
  const OrderSetupBottomSheet({super.key, this.orderModel, this.onlyDigital = false, required this.bottomContext});

  @override
  State<OrderSetupBottomSheet> createState() => _OrderSetupBottomSheetState();
}

class _OrderSetupBottomSheetState extends State<OrderSetupBottomSheet> {
  bool isSellerWiseShipping = false;
  bool inHouseShipping = false;
  final List<String> paymentTypeList = ['paid', 'unpaid'];
  String? _selectedOrderStatus;
  String? _selectedPaymentStatus;

  void _clearAllTextField(DeliveryManController deliveryManController) {
    deliveryManController.deliveryManChargeTextEditingController.clear();
    deliveryManController.expectedDeliveryDateTextEditingController.clear();
    deliveryManController.thirdPartyShippingNameTextEditingController.clear();
    deliveryManController.thirdPartyShippingTrackingIdTextEditingController.clear();
  }

  @override
  void initState() {
    final DeliveryManController deliveryManController = Provider.of<DeliveryManController>(Get.context!, listen: false);
    deliveryManController.setDeliveryTypeIndex(_getIndexByDeliveryType(), false);
    deliveryManController.getDeliveryManList(widget.orderModel);
    _clearAllTextField(deliveryManController);

    isSellerWiseShipping = widget.orderModel?.shippingResponsibility == 'sellerwise_shipping';
    _getShippingMethod();

    final OrderDetailsController orderDetailsController = Provider.of<OrderDetailsController>(Get.context!, listen: false);
    orderDetailsController.initializeOrderSetupModel(order: widget.orderModel, notify: false);
    _selectedOrderStatus = widget.orderModel?.orderStatus;
    _selectedPaymentStatus = widget.orderModel?.paymentStatus;

    if (widget.orderModel?.id != null) {

    }

    super.initState();
  }

  int _getIndexByDeliveryType() {
    return widget.orderModel?.deliveryType == 'by_self_delivery_man'
      ? 1 : widget.orderModel?.deliveryType == 'third_party_delivery' ? 2 : 0;
  }

  void _getShippingMethod() {
    String? shipping = widget.orderModel?.shippingResponsibility ?? '';

    if(shipping == 'inhouse_shipping'
        && (widget.orderModel?.orderStatus == 'out_for_delivery'
        || widget.orderModel?.orderStatus == 'delivered'
        || widget.orderModel?.orderStatus == 'returned'
        || widget.orderModel?.orderStatus == 'failed'
        || widget.orderModel?.orderStatus == 'canceled')
    ){
      inHouseShipping = true;
    }else{
      inHouseShipping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
  final double keyBoardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        InkWell(
          onTap: () => Navigator.pop(context),
          child: Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.cancel_outlined,
              size: Dimensions.iconSizeMedium,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),

        Text(
          getTranslated('order_setup', context)!,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: Dimensions.paddingSizeMedium),

        Consumer<OrderDetailsController>(
          builder: (_, orderDetailsController, __) {
            bool paymentActive = _isPaymentActive(orderDetailsController);
            final bool statusListReady = inHouseShipping
                || orderDetailsController.orderStatusList.isNotEmpty;

            if (!statusListReady) {
              return const Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyBoardHeight),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      inHouseShipping ?
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeExtraSmall,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeSmall,
                        ),
                        child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                border: Border.all(width: .5,color: Theme.of(context).hintColor.withValues(alpha:.125)),
                                color: Theme.of(context).hintColor.withValues(alpha:.12),
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSize),
                              child: Text(getTranslated(widget.orderModel?.orderStatus, context)!),
                            ),
                        ),
                      ) :
                      QuikseeDropDownItemWidget(
                        title: 'order_status',
                        widget: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'order-status-${_dropdownOrderStatus(orderDetailsController)}-${orderDetailsController.orderStatusList.length}',
                          ),
                          initialValue: _dropdownOrderStatus(orderDetailsController),
                          isExpanded: true,
                          decoration: const InputDecoration(border: InputBorder.none),
                          iconSize: 24, elevation: 16, style: robotoRegular,
                          onChanged: _isVendorStatusLocked(widget.orderModel)
                              ? null
                              : (value) {
                                  setState(() => _selectedOrderStatus = value);
                                  orderDetailsController.updateOrderSetupStatus(value);
                                },
                          items: _orderStatusOptions(orderDetailsController)
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(getTranslated(value, context)!,
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_isVendorStatusLocked(widget.orderModel))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Dimensions.paddingSizeDefault,
                            0,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeSmall,
                          ),
                          child: Text(
                            getTranslated(
                                  'vendor_cannot_change_status_after_out_for_delivery',
                                  context,
                                ) ??
                                'You cannot change status after out for delivery or delivered.',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),

                      QuikseeDropDownItemWidget(
                        title: 'payment_status',
                        widget: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(border: InputBorder.none),
                          iconSize: 24, elevation: 16, style: robotoRegular,
                          onChanged: !paymentActive ? null : (value) {
                            setState(() => _selectedPaymentStatus = value);
                            orderDetailsController.updateOrderSetupPaymentStatus(value);
                          },
                          items: paymentTypeList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(getTranslated(value, context)!,
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                            );
                          }).toList(),
                        ),
                      ),

                      if(widget.orderModel?.shippingResponsibility == 'inhouse_shipping')...[
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
                          ),
                          child: Row(
                            children: [
                              QuikseeAssetImageWidget(Images.infoIcon, height: 15, width: 15),
                              SizedBox(width: Dimensions.paddingSizeSmall),
                              Expanded(
                                child: Text(getTranslated('this_order_was_placed_with_the_inhouse_shipping', context)!,
                                    style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: Dimensions.paddingSizeSmall)
                      ],

                      _deliverySetUpExist() ?
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: DeliveryManAssignWidget(
                          orderType: widget.orderModel?.orderType,
                          orderModel: widget.orderModel,
                          orderId: widget.orderModel!.id,
                        ),
                      ) : const SizedBox(),

                      _deliverySetUpExist() ?
                      const SizedBox(height: Dimensions.paddingSizeSmall) : SizedBox.shrink(),

                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Row(
                          children: [
                            if (_canCancelOrder(widget.orderModel)) ...[
                              Expanded(
                                child: QuikseeButtonWidget(
                                  isLoading: orderDetailsController.isLoading,
                                  btnTxt: getTranslated('cancel_order', context) ??
                                      'Cancel Order',
                                  backgroundColor: Colors.red.shade600,
                                  borderRadius: 8,
                                  onTap: orderDetailsController.isLoading
                                      ? null
                                      : () => _cancelOrderFromSetup(
                                            orderDetailsController,
                                          ),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),
                            ],
                            Expanded(
                              child: QuikseeButtonWidget(
                                isLoading: orderDetailsController.isLoading,
                                btnTxt: getTranslated('update', context),
                                backgroundColor: Theme.of(context).primaryColor,
                                borderRadius: 8,
                                onTap: () async {
                                  DeliveryManController deliveryManController = Provider.of<DeliveryManController>(context, listen: false);

                                  orderDetailsController.orderSetupModel.orderStatus =
                                      _isVendorStatusLocked(widget.orderModel)
                                          ? widget.orderModel?.orderStatus
                                          : _selectedOrderStatus;
                                  orderDetailsController.orderSetupModel.paymentStatus = _selectedPaymentStatus;
                                  _populateOrderSetUpModel(orderDetailsController.orderSetupModel, deliveryManController);

                                  if (_isVendorStatusLocked(widget.orderModel) &&
                                      _selectedOrderStatus != null &&
                                      _selectedOrderStatus != widget.orderModel?.orderStatus) {
                                    showToast(
                                      message: getTranslated(
                                            'vendor_cannot_change_status_after_out_for_delivery',
                                            context,
                                          ) ??
                                          'You cannot change status after out for delivery or delivered.',
                                    );
                                    return;
                                  }

                                  if (_canUpdate(orderDetailsController.orderSetupModel, widget.orderModel)) {

                                    if (!mounted) return;

                                    final bool updated =
                                        await orderDetailsController.setUpOrder(
                                      orderSetupModel:
                                          orderDetailsController.orderSetupModel,
                                      context: context,
                                    );

                                    if (updated && mounted) {
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    final deliveryManController = Provider.of<DeliveryManController>(context, listen: false);

                                    if(deliveryManController.selectedDeliveryTypeIndex == 1 && deliveryManController.deliveryManIndex == 0){
                                      showToast(message: getTranslated('please_select_delivery_man', context)!);
                                      return;
                                    }
                                    else if(deliveryManController.selectedDeliveryTypeIndex == 1
                                        && deliveryManController.deliveryManIndex != 0
                                        && deliveryManController.deliveryManChargeTextEditingController.text.isEmpty ){
                                      showToast(message: getTranslated('please_enter_delivery_incentive', context)!);
                                      return;
                                    }
                                    else if(deliveryManController.selectedDeliveryTypeIndex == 2
                                        && deliveryManController.thirdPartyShippingNameTextEditingController.text.isEmpty){
                                      showToast(message: getTranslated('please_enter_delivery_service_name', context)!);
                                      return;
                                    }
                                    else if(deliveryManController.selectedDeliveryTypeIndex == 2
                                        && deliveryManController.thirdPartyShippingTrackingIdTextEditingController.text.isEmpty) {
                                      showToast(message: getTranslated('please_enter_tracking_id', context)!);
                                      return;
                                    }
                                    else{
                                      showToast(message: getTranslated('there_is_no_change_to_update', context)!);
                                      showQuikseeSnackBarWidget(
                                        getTranslated('there_is_no_change_to_update', context),
                                        context,
                                        isToaster: true,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

          }
        ),
      ]),
    );
  }

  void showToast({Color backGroundColor = Colors.red, required String message}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: backGroundColor,
        textColor: Colors.white,
        fontSize: Dimensions.fontSizeDefault
    );
  }

  List<String> _orderStatusOptions(OrderDetailsController orderDetailsController) {
    final current = widget.orderModel?.orderStatus;
    final options = List<String>.from(orderDetailsController.orderStatusList);
    if (current != null && current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return options;
  }

  String? _dropdownOrderStatus(OrderDetailsController orderDetailsController) {
    final selected = _selectedOrderStatus ?? orderDetailsController.orderSetupModel.orderStatus;
    final options = _orderStatusOptions(orderDetailsController);
    if (selected != null && options.contains(selected)) {
      return selected;
    }
    return options.isNotEmpty ? options.first : null;
  }

  void _populateOrderSetUpModel(OrderSetupModel orderSetUpModel, DeliveryManController deliveryManController) {
    final int? index = deliveryManController.deliveryManIndex;
    if (index != null &&
        index > 0 &&
        index < deliveryManController.deliveryManIds.length) {
      orderSetUpModel.deliveryManId = deliveryManController.deliveryManIds[index];
    }
    if(deliveryManController.deliveryManChargeTextEditingController.text.isNotEmpty){
      orderSetUpModel.deliveryManCharge = deliveryManController.deliveryManChargeTextEditingController.text;
    }
    if(deliveryManController.thirdPartyShippingNameTextEditingController.text.isNotEmpty){
      orderSetUpModel.thirdPartyDeliveryServiceName = deliveryManController.thirdPartyShippingNameTextEditingController.text;
    }
    if(deliveryManController.thirdPartyShippingTrackingIdTextEditingController.text.isNotEmpty){
      orderSetUpModel.thirdPartyDeliveryServiceTrackingId = deliveryManController.thirdPartyShippingTrackingIdTextEditingController.text;
    }
    if(deliveryManController.expectedDeliveryDateTextEditingController.text.isNotEmpty){
      orderSetUpModel.expectedDeliveryDate = deliveryManController.expectedDeliveryDateTextEditingController.text;
    }
    if(deliveryManController.selectedDeliveryTypeIndex != 0 ){
      orderSetUpModel.deliveryType = deliveryManController.selectedDeliveryTypeIndex == 1 ? 'by_self_delivery_man' : 'third_party_delivery';
    }
  }

  bool _isVendorStatusLocked(Order? order) {
    final status = (order?.orderStatus ?? '').toLowerCase();
    return status == 'out_for_delivery' || status == 'delivered';
  }

  bool _canCancelOrder(Order? order) {
    final status = (order?.orderStatus ?? '').toLowerCase();
    return status.isNotEmpty &&
        !const {
          'canceled',
          'cancelled',
          'delivered',
          'out_for_delivery',
          'returned',
          'failed',
        }.contains(status);
  }

  Future<void> _cancelOrderFromSetup(
    OrderDetailsController orderDetailsController,
  ) async {
    final orderId = widget.orderModel?.id;
    if (orderId == null || orderId <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          getTranslated('are_you_sure', dialogContext) ?? 'Are you sure?',
        ),
        content: Text(
          getTranslated('are_you_sure_to_cancel', dialogContext) ??
              'Are you sure you want to cancel this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(getTranslated('no', dialogContext) ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              getTranslated('yes', dialogContext) ?? 'Yes',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final payment = (widget.orderModel?.paymentStatus ?? 'unpaid')
        .trim()
        .toLowerCase();
    final paymentStatus =
        payment == 'paid' || payment == 'unpaid' ? payment : 'unpaid';

    if (!mounted) return;

    final ok = await orderDetailsController.setUpOrder(
      orderSetupModel: OrderSetupModel(
        orderId: orderId,
        orderStatus: 'canceled',
        paymentStatus: paymentStatus,
      ),
      context: context,
    );

    if (!mounted) return;
    Navigator.pop(context);
    if (ok) {
      showQuikseeSnackBarWidget(
        getTranslated('cancelled', context) ?? 'Order cancelled',
        context,
        isError: false,
        isToaster: true,
        sanckBarType: SnackBarType.success,
      );
    }
  }

  bool _canUpdate(OrderSetupModel orderSetUpModel, Order? order) {
    final deliveryManController =
        Provider.of<DeliveryManController>(widget.bottomContext, listen: false);
    final String? nextStatus = _selectedOrderStatus ?? orderSetUpModel.orderStatus;
    final String? nextPayment =
        _selectedPaymentStatus ?? orderSetUpModel.paymentStatus;

    return order?.paymentStatus != nextPayment
        || order?.orderStatus != nextStatus
        || order?.thirdPartyServiceName != orderSetUpModel.thirdPartyDeliveryServiceName
        || order?.thirdPartyTrackingId != orderSetUpModel.thirdPartyDeliveryServiceTrackingId
        || order?.deliveryManId != orderSetUpModel.deliveryManId
        || order?.deliverymanCharge?.toString() != orderSetUpModel.deliveryManCharge
        || order?.expectedDeliveryDate != orderSetUpModel.expectedDeliveryDate
        || (deliveryManController.selectedDeliveryTypeIndex != 0
            && orderSetUpModel.deliveryType != null
            && order?.deliveryType != orderSetUpModel.deliveryType);
  }

  bool _isPaymentActive(OrderDetailsController orderDetailsController) {
    if(widget.orderModel?.paymentStatus == 'paid') return false;

    return true;

  }

  bool _deliverySetUpExist() => isSellerWiseShipping && !widget.onlyDigital && widget.orderModel?.orderType != 'POS';

}
