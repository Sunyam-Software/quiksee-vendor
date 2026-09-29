import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/helper/color_helper.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryManContactInformationWidget extends StatelessWidget {
  final String? orderType;
  final Order? orderModel;
  final bool? onlyDigital;

  const DeliveryManContactInformationWidget({
    super.key,
    this.orderModel,
    this.orderType,
    this.onlyDigital,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryMan = orderModel?.deliveryMan;
    if (deliveryMan == null) return const SizedBox.shrink();

    final textColor = ColorHelper.blendColors(
      Colors.white,
      Theme.of(context).textTheme.bodyLarge!.color!,
      0.7,
    );
    final phone = '${deliveryMan.countryCode ?? ''} ${deliveryMan.phone ?? ''}'.trim();
    final email = deliveryMan.email?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).hintColor.withValues(alpha: 0.2),
            spreadRadius: 1.5,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Text(
              getTranslated('deliveryman_information', context)!,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Divider(
            thickness: 0.2,
            height: 1,
            color: Theme.of(context).hintColor.withValues(alpha: .65),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: QuikseeImageWidget(
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    image: '${deliveryMan.imageFullUrl?.path}',
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${deliveryMan.fName ?? ''} ${deliveryMan.lName ?? ''}'.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        _ContactLine(
                          icon: Images.phone,
                          text: phone,
                          textColor: textColor,
                        ),
                      ],
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        _ContactLine(
                          icon: Images.email,
                          text: email,
                          textColor: textColor,
                        ),
                      ],
                    ],
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () => _sendEmail(email),
                    child: const QuikseeAssetImageWidget(
                      Images.email,
                      height: 25,
                      width: 25,
                    ),
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () => _callPhone(phone),
                    child: const QuikseeAssetImageWidget(
                      Images.customerCallIcon,
                      height: 25,
                      width: 25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeFull('subject=Support&body='),
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _ContactLine extends StatelessWidget {
  final String icon;
  final String text;
  final Color textColor;

  const _ContactLine({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon, width: 15),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titilliumRegular.copyWith(
              color: textColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
      ],
    );
  }
}
