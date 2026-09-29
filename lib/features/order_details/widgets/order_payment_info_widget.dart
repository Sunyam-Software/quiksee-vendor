import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/scheduled_delivery_model.dart';
import 'package:quiksee_vendor_app/features/order/widgets/scheduled_delivery_badge_widget.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:quiksee_vendor_app/helper/date_converter.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderPaymentInfoWidget extends StatelessWidget {
  const OrderPaymentInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsController>(
      builder: (context, orderProvider, child) {
        ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;
        final hideCustomerDeliveryOtp =
            (orderProvider.orderDetails?.first.order?.foodPickupOtpEnabled ?? 0) == 1
            || (orderProvider.orderDetails?.first.order?.pickupOtpRequired ?? 0) == 1
            || (orderProvider.orderDetails?.first.order?.pickupOtpVerified ?? 0) == 1;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:0.2), spreadRadius:1.5, blurRadius: 3)],
            color: Theme.of(context).cardColor,
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Column(
              children: [
                const SizedBox(height: Dimensions.paddingSizeDefault),

                if(configModel?.orderVerification == 1
                    && !hideCustomerDeliveryOtp
                    && orderProvider.orderDetails?.first.order?.orderType != 'POS')...[
                  Container(
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated('order_verification_code', context) ?? '',
                          style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                        ),

                        Text(
                          orderProvider.orderDetails?.first.order?.verificationCode ?? '',
                          style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
                        ),
                      ],
                    ),
                  ),

                  if(configModel?.orderVerification == 1 && orderProvider.orderDetails?.first.order?.orderType != 'POS')
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                  SizedBox(height: 1, child: Divider(thickness: .200, color: Theme.of(context).hintColor.withValues(alpha: 0.45))),
                ],

                if(configModel?.orderVerification == 1
                    && !hideCustomerDeliveryOtp
                    && orderProvider.orderDetails?.first.order?.orderType != 'POS')
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        getTranslated('order_date_details', context) ?? '',
                        style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                    ),

                    Text(
                      DateConverter.localDateToIsoStringAMPMOrder(DateTime.parse(orderProvider.orderDetails!.first.order!.createdAt!)),
                      style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeDefault)
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                SizedBox(height: 1, child: Divider(thickness: .200, color: Theme.of(context).hintColor.withValues(alpha: 0.45))),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        getTranslated('order_type', context) ?? '',
                        style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                    ),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                      ),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      child: Text(
                          orderProvider.orderDetails?.first.order?.orderType == 'POS' ?
                          getTranslated('pos_order_small', context) ?? 'POS Order' :
                          getTranslated('regular', context) ?? 'Regular',
                          style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                if (orderProvider.orderDetails?.first.order?.scheduledDelivery?.isScheduled == true) ...[
                  SizedBox(height: 1, child: Divider(thickness: .200, color: Theme.of(context).hintColor.withValues(alpha: 0.45))),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _ScheduledDeliveryInfoSection(
                    schedule: orderProvider.orderDetails!.first.order!.scheduledDelivery!,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],

                if(orderProvider.orderDetails?.first.order?.bringChangeAmountCurrency != null && (double.tryParse(orderProvider.orderDetails!.first.order!.bringChangeAmountCurrency.toString()) ?? 0) > 0)...[
                  SizedBox(height: 1, child: Divider(thickness: .200, color: Theme.of(context).hintColor.withValues(alpha: 0.45))),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:0.2), spreadRadius:3, blurRadius: 3)],
                      color: Theme.of(context).cardColor,
                    ),
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            getTranslated('change_request', context) ?? '',
                            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                        ),
                        SizedBox(height: Dimensions.paddingSizeSmall),

                        Container(
                          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall)
                          ),
                          child:  RichText(text: TextSpan(children: [
                            TextSpan(text: getTranslated('please_bring', context),
                              style: titilliumRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            TextSpan(text: PriceConverter.convertPrice(context, (double.tryParse(orderProvider.orderDetails!.first.order!.bringChangeAmountCurrency.toString()) ?? 0)),
                              style: titilliumBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            TextSpan(text: getTranslated('in_change_when_making_the_delivery', context),
                              style: titilliumRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                          ])
                          ),
                        )

                      ],
                    )
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                ]

              ],
            ),
          ),
        );
      }
    );
  }
}

class _ScheduledDeliveryInfoSection extends StatelessWidget {
  final ScheduledDeliveryInfo schedule;
  const _ScheduledDeliveryInfoSection({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final String label = (schedule.label?.trim().isNotEmpty ?? false)
        ? schedule.label!
        : schedule.displayBadgeText;
    final String timeText = schedule.displayTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScheduledDeliveryBadgeWidget(schedule: schedule, compact: false),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslated('scheduled_delivery', context) ?? 'Scheduled delivery',
              style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.end,
                style: robotoMedium.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ),
          ],
        ),

        if (schedule.dateDisplay != null && schedule.dateDisplay!.trim().isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated('schedule_date', context) ?? 'Date',
                style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color),
              ),
              Text(
                schedule.dateDisplay!,
                style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
        ],

        if (timeText.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated('schedule_time', context) ?? 'Time',
                style: robotoRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color),
              ),
              Text(
                timeText,
                style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
        ],

        if (schedule.riderTimingNote != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            schedule.riderTimingNote!,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ],
    );
  }
}
