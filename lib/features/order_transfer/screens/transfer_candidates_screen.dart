import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/domain/models/transfer_candidate_model.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// OLD rider: pick one free area rider and send transfer offer.
class TransferCandidatesScreen extends StatefulWidget {
  final int orderId;

  const TransferCandidatesScreen({super.key, required this.orderId});

  @override
  State<TransferCandidatesScreen> createState() =>
      _TransferCandidatesScreenState();
}

class _TransferCandidatesScreenState extends State<TransferCandidatesScreen> {
  int? _selectedId;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!OrderTransferBinding.ensure()) return;
      Get.find<OrderTransferController>().loadCandidates(widget.orderId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend(OrderTransferController controller) async {
    final toId = _selectedId;
    if (toId == null) {
      showQuikseeSnackBarWidget('select_rider_first'.tr);
      return;
    }
    TransferCandidateModel? picked;
    for (final c in controller.candidates) {
      if (c.id == toId) {
        picked = c;
        break;
      }
    }
    if (picked != null && !picked.canSelect) {
      showQuikseeSnackBarWidget(
        picked.availability == 'busy'
            ? 'Rider is busy right now'
            : 'Rider is offline',
      );
      return;
    }

    final okConfirm = await Get.dialog<bool>(
          AlertDialog(
            title: Text('confirm_transfer'.tr),
            content: Text('transfer_confirm_body'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('send_transfer'.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!okConfirm) return;

    final ok = await controller.requestTransfer(
      orderId: widget.orderId,
      toDeliveryManId: toId,
      reason: _reasonController.text,
    );
    if (!ok) return;

    controller.startOutgoingWaitUi(
      onAccepted: () async {
        if (Get.isRegistered<OrderTransferController>()) {
          Get.find<OrderTransferController>()
              .markOrderTransferAcceptedLocally(widget.orderId);
        }
        if (Get.isRegistered<OrderController>()) {
          await Get.find<OrderController>().onAssignedOrderReleasedPush(
            orderId: widget.orderId,
          );
        }
        if (mounted) {
          Get.until((route) => route.isFirst);
        }
      },
      onRejectedOrExpired: () {
        // Stay on candidates so OLD can pick another rider themselves.
        // Never auto-send to the next rider.
        if (mounted) {
          setState(() => _selectedId = null);
        }
        controller.loadCandidates(widget.orderId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!OrderTransferBinding.ensure()) {
      return Scaffold(
        appBar: QuikseeAppBarWidget(title: 'transfer_order'.tr, isBack: true),
        body: Center(child: Text('transfer_failed'.tr)),
      );
    }
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'transfer_order'.tr, isBack: true),
      body: GetBuilder<OrderTransferController>(builder: (controller) {
        if (controller.loadingCandidates) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = controller.candidates;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Text(
                'transfer_candidates_hint'.tr,
                style: rubikRegular.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('no_free_riders_nearby'.tr))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: Dimensions.paddingSizeSmall),
                      itemBuilder: (context, index) {
                        final c = list[index];
                        final selected = _selectedId == c.id;
                        final canTap = c.canSelect;
                        final statusColor = c.availability == 'online'
                            ? const Color(0xFF1B8A3E)
                            : (c.availability == 'busy'
                                ? const Color(0xFFE65100)
                                : const Color(0xFF757575));
                        final statusLabel = c.availability == 'online'
                            ? 'Online'
                            : (c.availability == 'busy' ? 'Busy' : 'Offline');
                        return InkWell(
                          onTap: canTap
                              ? () => setState(() => _selectedId = c.id)
                              : null,
                          child: Opacity(
                            opacity: canTap ? 1 : 0.55,
                            child: Container(
                            padding:
                                EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: 0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).hintColor,
                                ),
                                SizedBox(width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name.isEmpty
                                            ? 'Rider #${c.id}'
                                            : c.name,
                                        style: rubikMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusLabel,
                                            style: rubikMedium.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              color: statusColor,
                                            ),
                                          ),
                                          if (c.distanceKm != null) ...[
                                            Text(
                                              '  ·  ',
                                              style: rubikRegular.copyWith(
                                                color: Theme.of(context)
                                                    .hintColor,
                                              ),
                                            ),
                                            Text(
                                              '${c.distanceKm!.toStringAsFixed(1)} km',
                                              style: rubikRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: Theme.of(context)
                                                    .hintColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      PriceConverter.convertPrice(
                                          c.expectedTotal),
                                      style: rubikMedium.copyWith(
                                        color:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'goes_with_order'.tr,
                                      style: rubikRegular.copyWith(
                                        fontSize:
                                            Dimensions.fontSizeExtraSmall,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                children: [
                  TextField(
                    controller: _reasonController,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: 'transfer_reason_optional'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingSizeSmall),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.requesting
                          ? null
                          : () => _confirmAndSend(controller),
                      child: controller.requesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text('send_transfer'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
