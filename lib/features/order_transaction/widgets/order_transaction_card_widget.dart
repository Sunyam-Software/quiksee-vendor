import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/features/order_transaction/domain/models/order_transaction_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderTransactionCardWidget extends StatelessWidget {
  final OrderTransactionRow row;
  const OrderTransactionCardWidget({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeSmall,
        0,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${getTranslated('order', context) ?? 'Order'} #${row.orderId}',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),
              Text(
                PriceConverter.convertPrice(context, row.vendorNetIncome),
                style: robotoBold.copyWith(
                  color: QuikseeBrandColors.forestGreen,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row.customerName.isEmpty
                ? (getTranslated('customer', context) ?? 'Customer')
                : row.customerName,
            style: robotoRegular.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _line(context, getTranslated('total_product_amount', context) ?? 'Product Amount', row.totalProductAmount),
          _discountLine(
            context,
            getTranslated('product_discount', context) ?? 'Product Discount',
            row.productDiscount,
            row.productDiscountSide,
            row.productDiscountBearer,
          ),
          _discountLine(
            context,
            getTranslated('sale_clearance_discount', context) ?? 'Sale Discount',
            row.saleDiscount,
            row.saleDiscountSide,
            row.saleDiscountBearer,
          ),
          _discountLine(
            context,
            getTranslated('coupon_discount', context) ?? 'Coupon Discount',
            row.couponDiscount,
            row.couponDiscountSide,
            row.couponDiscountBearer,
          ),
          _line(context, getTranslated('discounted_amount', context) ?? 'Discounted Amount', row.discountedAmount),
          _line(context, getTranslated('tax', context) ?? 'GST', row.tax),
          _line(context, getTranslated('shipping', context) ?? 'Shipping', row.shippingCharge),
          const Divider(height: 20),
          _line(context, getTranslated('admin_commission', context) ?? 'Admin Commission', row.adminCommission),
          _line(
            context,
            getTranslated('vendor_net_income', context) ?? 'Vendor Net Income',
            row.vendorNetIncome,
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, double amount, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (emphasize ? robotoMedium : robotoRegular).copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            PriceConverter.convertPrice(context, amount),
            style: (emphasize ? robotoBold : robotoMedium).copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: emphasize ? QuikseeBrandColors.forestGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountLine(
    BuildContext context,
    String label,
    double amount,
    String sideLabel,
    String? bearer,
  ) {
    final side = sideLabel.trim().isNotEmpty
        ? '$sideLabel side'
        : (bearer == 'admin'
            ? (getTranslated('admin_side', context) ?? 'Admin side')
            : bearer == 'seller' || bearer == 'vendor'
                ? (getTranslated('vendor_side', context) ?? 'Vendor side')
                : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                if (amount > 0 && side.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _sideBadge(context, side, bearer),
                ],
              ],
            ),
          ),
          Text(
            PriceConverter.convertPrice(context, amount),
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ],
      ),
    );
  }

  Widget _sideBadge(BuildContext context, String label, String? bearer) {
    final isAdmin = bearer == 'admin' || label.toLowerCase().contains('admin');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFE8F1FF) : const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: isAdmin ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C),
        ),
      ),
    );
  }
}
