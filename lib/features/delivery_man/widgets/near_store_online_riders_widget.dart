import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/delivery_man/controllers/delivery_man_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:url_launcher/url_launcher.dart';

String _t(BuildContext context, String key, String fallback) {
  final value = getTranslated(key, context);
  if (value == null || value.isEmpty || value == key) {
    return fallback;
  }
  return value;
}

class NearStoreRidersFab extends StatefulWidget {
  const NearStoreRidersFab({super.key});

  @override
  State<NearStoreRidersFab> createState() => _NearStoreRidersFabState();
}

class _NearStoreRidersFabState extends State<NearStoreRidersFab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<DeliveryManController>(context, listen: false)
          .getNearStoreOnlineRiders(notify: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryManController>(
      builder: (context, controller, _) {
        final count = controller.nearStoreRiders.length;
        return FloatingActionButton(
          heroTag: 'near_store_riders_fab',
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () => NearStoreOnlineRidersSheet.show(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
              if (count > 0)
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class NearStoreRidersOpenButton extends StatelessWidget {
  final int? orderId;

  const NearStoreRidersOpenButton({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryManController>(
      builder: (context, controller, _) {
        final count = controller.nearStoreRiders.length;
        return Material(
          color: Theme.of(context).cardColor,
          child: InkWell(
            onTap: () => NearStoreOnlineRidersSheet.show(context, orderId: orderId),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeDefault,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      _t(context, 'riders_near_store', 'Riders near your store'),
                      style: robotoMedium.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  if (controller.nearStoreLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    if (count > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    Icon(Icons.chevron_right,
                        color: Theme.of(context).hintColor),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NearStoreOnlineRidersSheet {
  static Future<void> show(BuildContext context, {int? orderId}) async {
    final controller =
        Provider.of<DeliveryManController>(context, listen: false);
    unawaited(controller.getNearStoreOnlineRiders());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height * 0.7;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .hintColor
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining,
                        color: Theme.of(sheetContext).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _t(sheetContext, 'riders_near_store',
                            'Riders near your store'),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _t(sheetContext, 'refresh', 'Refresh'),
                      onPressed: () => controller.getNearStoreOnlineRiders(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<DeliveryManController>(
                  builder: (context, ctrl, _) {
                    if (ctrl.nearStoreLoading && ctrl.nearStoreRiders.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final riders = ctrl.nearStoreRiders;
                    if (riders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _t(
                              context,
                              'no_online_riders_near_store',
                              'No live riders near your store right now',
                            ),
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: riders.length + 1,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context)
                            .hintColor
                            .withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final nearCount =
                              ctrl.nearStoreSummary?['near_count'] ??
                                  riders.length;
                          final onlineCount =
                              ctrl.nearStoreSummary?['online_count'] ?? 0;
                          final acceptedCount =
                              ctrl.nearStoreSummary?['accepted_count'] ?? 0;
                          final outCount = ctrl.nearStoreSummary?[
                                  'out_for_delivery_count'] ??
                              0;
                          final summaryParts = <String>[
                            '${_t(context, 'near_store_riders', 'Near store')}: $nearCount',
                            '${_t(context, 'online', 'Online')}: $onlineCount',
                            '${_t(context, 'accepted', 'Accepted')}: $acceptedCount',
                          ];
                          if (outCount is num && outCount > 0) {
                            summaryParts.add(
                              '${_t(context, 'out_for_delivery', 'Out for delivery')}: $outCount',
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 4),
                            child: Text(
                              summaryParts.join(' · '),
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          );
                        }

                        final rider = riders[index - 1];
                        final bool hasPendingOrder = (orderId != null &&
                                orderId > 0) ||
                            ctrl.waitingOrders.isNotEmpty;
                        return _RiderTile(
                          rider: rider,
                          orderId: orderId,
                          sending: ctrl.sendingOffer,
                          allowSendRequest: hasPendingOrder,
                          onSendRequest: () async {
                            final id = int.tryParse('${rider['id'] ?? 0}') ?? 0;
                            if (id <= 0) return;
                            final waiting = ctrl.waitingOrders;
                            int? targetOrderId = orderId;
                            if (targetOrderId == null || targetOrderId <= 0) {
                              if (waiting.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_t(
                                      context,
                                      'no_order_waiting_for_rider',
                                      'No order is waiting for a rider right now',
                                    )),
                                  ),
                                );
                                return;
                              }
                              targetOrderId = int.tryParse(
                                      '${waiting.first['id'] ?? 0}') ??
                                  0;
                            }
                            if (targetOrderId <= 0) return;
                            final ok = await ctrl.sendOfferToDeliveryMan(
                              deliveryManId: id,
                              orderId: targetOrderId,
                            );
                            if (ok && context.mounted) {

                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiderTile extends StatelessWidget {
  final Map<String, dynamic> rider;
  final int? orderId;
  final bool sending;
  final bool allowSendRequest;
  final Future<void> Function() onSendRequest;

  const _RiderTile({
    required this.rider,
    required this.onSendRequest,
    this.orderId,
    this.sending = false,
    this.allowSendRequest = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${rider['name'] ?? ''}'.trim();
    final distance = rider['distance_km'];
    final isLive = rider['is_live'] == true || rider['is_live'] == 1;
    final hasAccepted =
        rider['has_accepted'] == true || rider['has_accepted'] == 1;
    final hasPending =
        rider['has_pending_offer'] == true || rider['has_pending_offer'] == 1;
    final canSend = allowSendRequest &&
        (rider['can_send_request'] == true || rider['can_send_request'] == 1);
    final distanceLabel = distance == null
        ? _t(context, 'location_unknown', 'Location unknown')
        : '$distance km';

    String statusLabel;
    Color statusColor;
    Color badgeBg;
    Color badgeBorder;
    Color badgeTextColor;
    String badgeText;

    final orderStatus = '${rider['accepted_order_status'] ?? ''}'.toLowerCase();
    final isOutForDelivery = orderStatus == 'out_for_delivery' ||
        rider['is_out_for_delivery'] == true ||
        rider['is_out_for_delivery'] == 1;
    final isReachedRestaurant = orderStatus == 'reached_restaurant' ||
        rider['is_reached_restaurant'] == true ||
        rider['is_reached_restaurant'] == 1;

    if (hasAccepted) {
      statusLabel =
          '${rider['accepted_label'] ?? (_t(context, 'accepted', 'Accepted'))}';
      if (isOutForDelivery) {
        statusColor = Colors.blue.shade800;
        badgeBg = Colors.blue.shade50;
        badgeBorder = Colors.blue.shade300;
        badgeTextColor = Colors.blue.shade900;
        badgeText = '${rider['accepted_badge'] ?? _t(context, 'out_for_delivery', 'Out for delivery')}';
      } else if (isReachedRestaurant) {
        statusColor = Colors.indigo.shade800;
        badgeBg = Colors.indigo.shade50;
        badgeBorder = Colors.indigo.shade300;
        badgeTextColor = Colors.indigo.shade900;
        badgeText = '${rider['accepted_badge'] ?? _t(context, 'reached_restaurant', 'Reached restaurant')}';
      } else {
        statusColor = Colors.green.shade700;
        badgeBg = Colors.green.shade50;
        badgeBorder = Colors.green.shade300;
        badgeTextColor = Colors.green.shade800;
        badgeText = '${rider['accepted_badge'] ?? _t(context, 'accepted', 'Accepted')}';
      }
    } else if (hasPending) {
      statusLabel =
          '${rider['pending_offer_label'] ?? (_t(context, 'request_sent', 'Request sent'))}';
      statusColor = Colors.orange.shade800;
      badgeBg = Colors.orange.shade50;
      badgeBorder = Colors.orange.shade300;
      badgeTextColor = Colors.orange.shade900;
      badgeText = _t(context, 'request_sent', 'Request sent');
    } else {
      statusLabel = isLive
          ? _t(context, 'live', 'Live')
          : _t(context, 'online', 'Online');
      statusColor = Theme.of(context).hintColor;
      badgeBg = Colors.transparent;
      badgeBorder = Colors.transparent;
      badgeTextColor = Colors.transparent;
      badgeText = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: QuikseeImageWidget(
                  height: 48,
                  width: 48,
                  image: '${rider['image'] ?? ''}',
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: hasAccepted
                        ? (isOutForDelivery
                            ? Colors.blue
                            : (isReachedRestaurant ? Colors.indigo : Colors.green))
                        : (isLive ? Colors.green : Colors.orange),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Rider' : name,
                  style: robotoMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '$distanceLabel · $statusLabel',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (hasAccepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                badgeText,
                style: robotoMedium.copyWith(
                  color: badgeTextColor,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            )
          else if (hasPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                badgeText,
                style: robotoMedium.copyWith(
                  color: badgeTextColor,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            )
          else if (canSend)
            TextButton(
              onPressed: sending ? null : onSendRequest,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _t(context, 'send_request', 'Send request'),
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          if (_dialNumber(rider) != null) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.green.shade600,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _callRider(context, rider),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.call, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _dialNumber(Map<String, dynamic> rider) {
  final full = '${rider['full_phone'] ?? ''}'.trim();
  if (full.isNotEmpty) return full.replaceAll(RegExp(r'[\s\-]'), '');

  final phone = '${rider['phone'] ?? ''}'.trim();
  if (phone.isEmpty) return null;

  final code = '${rider['country_code'] ?? ''}'.trim();
  if (phone.startsWith('+') || code.isEmpty) {
    return phone.replaceAll(RegExp(r'[\s\-]'), '');
  }
  final dialCode = code.startsWith('+') ? code : '+$code';
  final local = phone.startsWith('0') ? phone.substring(1) : phone;
  return '$dialCode$local'.replaceAll(RegExp(r'[\s\-]'), '');
}

Future<void> _callRider(BuildContext context, Map<String, dynamic> rider) async {
  final phone = _dialNumber(rider);
  if (phone == null || phone.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(context, 'phone_number_not_available', 'Phone number not available'),
        ),
      ),
    );
    return;
  }

  final uri = Uri.parse(Platform.isIOS ? 'tel://$phone' : 'tel:$phone');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context, 'could_not_open_dialer', 'Could not open dialer')),
        ),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(context, 'could_not_open_dialer', 'Could not open dialer')),
      ),
    );
  }
}
