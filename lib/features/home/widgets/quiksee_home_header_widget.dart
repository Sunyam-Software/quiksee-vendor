import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/home/widgets/quiksee_header_wave_painter.dart';
import 'package:quiksee_vendor_app/features/notification/controllers/notification_controller.dart';
import 'package:quiksee_vendor_app/features/notification/screens/notification_screen.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/profile/screens/profile_view_screen.dart' show ProfileScreenView;
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class QuikseeHomeHeaderWidget extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const QuikseeHomeHeaderWidget({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    QuikseeBrandColors.headerBackgroundGreen,
                    Color(0xFFF0F9F3),
                    Colors.white,
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: QuikseeHeaderWavePainter(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                4,
                4,
                Dimensions.paddingSizeDefault,
                10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onMenuTap,
                    icon: const Icon(
                      Icons.menu,
                      color: QuikseeBrandColors.seeTextGreen,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          Images.quikseeLogo,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: QuikseeBrandColors.seeTextGreen,
                            letterSpacing: 0.3,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _callSupport(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: QuikseeBrandColors.seeTextGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: QuikseeBrandColors.seeTextGreen.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<NotificationController>(
                    builder: (context, notificationController, _) {
                      final count =
                          notificationController.notificationModel?.newNotificationItem ?? 0;
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                CupertinoIcons.bell,
                                color: QuikseeBrandColors.seeTextGreen,
                                size: 28,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: QuikseeBrandColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: robotoBold.copyWith(
                                      fontSize: 10,
                                      color: QuikseeBrandColors.forestGreen,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Consumer<ProfileController>(
                    builder: (context, profile, _) {
                      final image = profile.userInfoModel?.imageFullUrl?.path;
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreenView()),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: QuikseeBrandColors.seeTextGreen.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                image != null && image.isNotEmpty ? NetworkImage(image) : null,
                            child: image == null || image.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: QuikseeBrandColors.seeTextGreen,
                                    size: 28,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const String _supportNumber = '1800313000033';

  static Future<void> _callSupport(BuildContext context) async {
    final uri = Uri.parse(
      Platform.isIOS ? 'tel://$_supportNumber' : 'tel:$_supportNumber',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open dialer')),
      );
    }
  }
}
