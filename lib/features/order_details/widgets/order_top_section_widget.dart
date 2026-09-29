import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

PreferredSizeWidget buildOrderDetailsAppBar({
  required BuildContext context,
  required Order? orderModel,
  required bool fromNotification,
}) {
  return AppBar(
    elevation: 1,
    backgroundColor: Theme.of(context).cardColor,
    surfaceTintColor: Theme.of(context).cardColor,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () {
        if (fromNotification) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pop();
        }
        Provider.of<OrderDetailsController>(context, listen: false)
            .emptyOrderDetails();
      },
    ),
    title: Text(
      orderModel == null
          ? (getTranslated('order_details', context) ?? 'Order Details')
          : '${getTranslated('order', context) ?? 'Order'} #${orderModel.id}',
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeLarge,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    ),

  );
}

class OrderStatusHeaderWidget extends StatelessWidget {
  final Order? orderModel;
  const OrderStatusHeaderWidget({super.key, this.orderModel});

  Color _statusColor(BuildContext context) {
    final status = orderModel?.orderStatus;
    if (status == 'delivered' || status == 'confirmed') {
      return Theme.of(context).colorScheme.onTertiaryContainer;
    }
    if (status == 'pending') return Theme.of(context).primaryColor;
    if (status == 'processing') return Theme.of(context).colorScheme.outline;
    if (status == 'canceled' || status == 'failed') {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    if (orderModel == null) return const SizedBox.shrink();

    final status = (orderModel?.orderStatus ?? '').toLowerCase();
    final eta = orderModel?.etaLabel;
    final alreadyReady = (orderModel?.vendorReadyAt ?? '').isNotEmpty;
    final canMarkReady = !alreadyReady &&
        (status == 'confirmed' ||
            status == 'reached_restaurant' ||
            status == 'processing');

    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: getTranslated('your_order_is', context) ?? 'Your Order is',
              style: titilliumRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).hintColor,
              ),
              children: [
                TextSpan(
                  text:
                      ' ${getTranslated(orderModel!.orderStatus, context) ?? orderModel!.orderStatus ?? ''}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: _statusColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (eta != null && eta.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              eta,
              textAlign: TextAlign.center,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
          if (alreadyReady) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onTertiaryContainer
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Flexible(
                    child: Text(
                      getTranslated('order_marked_ready', context) ??
                          'Marked ready for pickup',
                      textAlign: TextAlign.center,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canMarkReady) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Consumer<OrderDetailsController>(
              builder: (context, orderProvider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: orderProvider.isLoading
                        ? null
                        : () async {
                            await orderProvider.notifyDeliveryManReady(
                              orderId: orderModel!.id!,
                              context: context,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    icon: orderProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded,
                            size: 20),
                    label: Text(
                      getTranslated('order_ready_for_pickup', context) ??
                          'Order Ready for Pickup',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

@Deprecated('Use OrderStatusHeaderWidget')
class OrderTopSectionWidget extends StatelessWidget {
  final Order? orderModel;
  final bool? fromNotification;
  const OrderTopSectionWidget({
    super.key,
    this.orderModel,
    this.fromNotification,
  });

  @override
  Widget build(BuildContext context) {
    return OrderStatusHeaderWidget(orderModel: orderModel);
  }
}

@Deprecated('Use OrderStatusHeaderWidget')
class OrderReadyActionWidget extends StatelessWidget {
  final Order? orderModel;
  const OrderReadyActionWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
