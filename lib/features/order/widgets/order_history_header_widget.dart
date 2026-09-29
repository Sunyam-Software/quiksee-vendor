import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/widgets/order_type_button_widget.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class OrderHistoryHeaderWidget extends StatefulWidget {
  const OrderHistoryHeaderWidget({super.key});

  @override
  State<OrderHistoryHeaderWidget> createState() =>
      _OrderHistoryHeaderWidgetState();
}

class _OrderHistoryHeaderWidgetState extends State<OrderHistoryHeaderWidget> {

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = List.generate(6, (index) => GlobalKey());
  int _lastChipIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollSelectedChipHorizontally(int index) {
    if (index == _lastChipIndex) return;
    _lastChipIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _itemKeys.length) return;
      if (!_scrollController.hasClients) return;

      final keyContext = _itemKeys[index].currentContext;
      final itemBox = keyContext?.findRenderObject() as RenderBox?;
      final listBox =
          _scrollController.position.context.notificationContext?.findRenderObject()
              as RenderBox?;
      if (itemBox == null || listBox == null) return;

      final itemGlobal = itemBox.localToGlobal(Offset.zero);
      final listGlobal = listBox.localToGlobal(Offset.zero);
      final itemCenter =
          itemGlobal.dx + (itemBox.size.width / 2) - listGlobal.dx;
      final target = (_scrollController.offset +
              itemCenter -
              (listBox.size.width / 2))
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        _scrollSelectedChipHorizontally(orderController.orderTypeIndex);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Get.isRegistered<AssignmentController>() &&
                Get.find<AssignmentController>().scheduledDeliveryEnabled)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HistoryModeChip(
                        label: 'normal_delivery'.tr,
                        selected: !orderController.isScheduledHistoryMode,
                        onTap: () {
                          if (orderController.isScheduledHistoryMode) {
                            orderController.setScheduledHistoryMode(false);
                            orderController.setOrderTypeIndex(
                              orderController.orderTypeIndex,
                              force: true,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: _HistoryModeChip(
                        label: 'scheduled_delivery'.tr,
                        selected: orderController.isScheduledHistoryMode,
                        onTap: () {
                          if (!orderController.isScheduledHistoryMode) {
                            orderController.setScheduledHistoryMode(true);
                            orderController.setOrderTypeIndex(
                              orderController.orderTypeIndex,
                              force: true,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Container(
          height: 65, padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,
            ),
            child: SizedBox(
              height: 55,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  OrderTypeButtonWidget(key: _itemKeys[0], text: 'all'.tr, index: 0,),

                  OrderTypeButtonWidget(key: _itemKeys[1], text: 'out_for_delivery'.tr, index: 1,),

                  OrderTypeButtonWidget(key: _itemKeys[2], text: 'paused'.tr, index: 2,),

                  OrderTypeButtonWidget(key: _itemKeys[3], text: 'delivered'.tr, index: 3,),

                  OrderTypeButtonWidget(key: _itemKeys[4], text: 'return'.tr, index: 4,),

                  OrderTypeButtonWidget(key: _itemKeys[5], text: 'canceled'.tr, index: 5,),
                ],
              ),
            ),
          ),
        ),
          ],
        );
      },
    );
  }
}

class _HistoryModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Material(
      color: selected ? color : color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: rubikMedium.copyWith(
              color: selected ? Colors.white : color,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
      ),
    );
  }
}