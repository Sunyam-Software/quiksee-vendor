import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// Green branded header for Order Information (matches design mock).
class OrderDetailsAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  static const Color brandGreen = Color(0xFF0F6B2D);

  final int? orderId;
  final VoidCallback? onBack;

  const OrderDetailsAppBarWidget({
    super.key,
    this.orderId,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: brandGreen,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          Dimensions.paddingSizeSmall,
          top + 8,
          Dimensions.paddingSizeDefault,
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onBack ?? () => Get.back(),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'order_information'.tr,
                    style: rubikBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'track_order_realtime'.tr,
                    style: rubikRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: brandGreen, size: 18),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'order_id'.tr,
                        style: rubikRegular.copyWith(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '#${orderId ?? '--'}',
                        style: rubikBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: brandGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
