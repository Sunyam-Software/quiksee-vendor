import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/features/tip/controllers/tip_controller.dart';
import 'package:quiksee/features/tip/widgets/order_tip_badge_widget.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TipOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const TipOrderDetailScreen({super.key, required this.orderId});

  @override
  State<TipOrderDetailScreen> createState() => _TipOrderDetailScreenState();
}

class _TipOrderDetailScreenState extends State<TipOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<TipController>().getTipOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'tip_details'.tr, isBack: true),
      body: GetBuilder<TipController>(
        builder: (tipController) {
          if (tipController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tip = tipController.orderTipDetail;
          if (tip == null) {
            return Center(child: Text('no_data_found'.tr));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'order'.tr} #${tip.orderId}',
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeOverLarge,
                  ),
                ),
                if (tip.customerName != null)
                  Padding(
                    padding:
                        EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    child: Text(
                      tip.customerName!,
                      style: rubikRegular.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                SizedBox(height: Dimensions.paddingSizeDefault),
                OrderTipBadgeWidget(tipItem: tip, compact: false),
                SizedBox(height: Dimensions.paddingSizeDefault),
                _infoCard(context, tip),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(BuildContext context, tip) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tip.storeName != null)
            _row('seller'.tr, tip.storeName!),
          if (tip.deliveryAddress != null)
            _row('address'.tr, tip.deliveryAddress!),
          if (tip.orderAmount != null)
            _row(
              'order_amount'.tr,
              tip.orderAmountFormatted ??
                  PriceConverter.convertPrice(tip.orderAmount),
            ),
          if (tip.paymentMethod != null)
            _row('payment_method'.tr, tip.paymentMethod!.replaceAll('_', ' ')),
          if (tip.orderStatus != null)
            _row('order_status'.tr, tip.orderStatus!.replaceAll('_', ' ')),
          if (tip.tipCreditedAt != null)
            _row(
              'tip_credited_at'.tr,
              DateConverter.isoStringToLocalDateOnly(tip.tipCreditedAt!),
            ),
          if (tip.note != null)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Text(
                tip.note!,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: rubikRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: rubikRegular),
          ),
        ],
      ),
    );
  }
}
