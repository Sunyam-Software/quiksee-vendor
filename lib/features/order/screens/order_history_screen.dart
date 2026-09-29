import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/widgets/order_history_appbar.dart';
import 'package:quiksee/features/order/widgets/order_history_shimmer_widget.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/order/widgets/order_history_header_widget.dart';
import 'package:quiksee/features/order/widgets/order_history_item_widget.dart';


class OrderHistoryScreen extends StatefulWidget {
  final bool fromMenu;
  const OrderHistoryScreen({super.key, this.fromMenu = false});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    Get.find<WalletController>().selectDate();

    if (widget.fromMenu) {
      final orderController = Get.find<OrderController>();
      orderController.resetFilters(isUpdate: false);
      if (orderController.allOrderHistory == null) {
        unawaited(orderController.ensureOrderHistoryLoaded());
      }
    }
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrderHistoryAppBar(
        title: 'order_history',
        searchController: searchController,
        onSearchChanged: (String searchKey) {},
      ),

      body: RefreshIndicator(onRefresh: () async {
        Get.find<OrderController>().searchOrderController.clear();
        Get.find<OrderController>().setOrderTypeIndex(
          Get.find<OrderController>().orderTypeIndex,
          startDate: Get.find<WalletController>().startDate == "dd-mm-yyyy"
              ? ""
              : Get.find<WalletController>().startDate,
          endDate: Get.find<WalletController>().endDate == "dd-mm-yyyy"
              ? ""
              : Get.find<WalletController>().endDate,
          force: true,
        );
      },
      child: CustomScrollView( slivers: [
        SliverToBoxAdapter(child: Column(children: [
          const OrderHistoryHeaderWidget(),

          Container(transform: Matrix4.translationValues(0.0, -00.0, 0.0),
            child: GetBuilder<OrderController>(builder: (orderController) {
              final orders = orderController.currentHistoryOrders;
              final loading = orderController.isHistoryLoading;

              if (orders != null && orders.isNotEmpty) {
                return RepaintBoundary(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderHistoryItemWidget(
                        key: ValueKey('hist_${order.id}_$index'),
                        orderModel: order,
                      );
                    },
                  ),
                );
              }

              if (loading) {
                return const OrderHistoryShimmer();
              }

              return Padding(
                padding:
                    EdgeInsets.only(top: Dimensions.paddingSizeOverLarge),
                child: const NoDataScreenWidget(),
              );
            }),
          )
        ]))
      ]),
      ),
    );
  }
}
