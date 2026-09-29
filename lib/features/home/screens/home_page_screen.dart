import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/delivery_man/controllers/delivery_man_controller.dart';
import 'package:quiksee_vendor_app/features/notification/controllers/notification_controller.dart';
import 'package:quiksee_vendor_app/features/order/controllers/order_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/review/controllers/product_review_controller.dart';
import 'package:quiksee_vendor_app/features/shipping/controllers/shipping_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/features/home/widgets/quiksee_home_header_widget.dart';
import 'package:quiksee_vendor_app/features/home/widgets/chart_widget.dart';
import 'package:quiksee_vendor_app/features/home/widgets/completed_order_widget.dart';
import 'package:quiksee_vendor_app/features/home/widgets/on_going_order_widget.dart';
import 'package:quiksee_vendor_app/features/product/widgets/stock_out_product_widget.dart';
import 'package:quiksee_vendor_app/features/product/screens/most_popular_product_screen.dart';
import 'package:quiksee_vendor_app/features/product/screens/top_selling_product_screen.dart';
import 'package:quiksee_vendor_app/features/delivery_man/widgets/top_delivery_man_view_widget.dart';

class HomePageScreen extends StatefulWidget {
  final Function? callback;
  final VoidCallback? onOpenMenu;
  const HomePageScreen({super.key, this.callback, this.onOpenMenu});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _tSync;

  Future<void> _loadData(BuildContext context, bool reload) async {

    final splashController = Provider.of<SplashController>(context, listen: false);
    if (splashController.configModel == null) {
      for (var i = 0; i < 25 && splashController.configModel == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }
    }

    final profile = Provider.of<ProfileController>(context, listen: false);
    final bank = Provider.of<BankInfoController>(context, listen: false);
    final order = Provider.of<OrderController>(context, listen: false);
    final product = Provider.of<ProductController>(context, listen: false);
    final shipping = Provider.of<ShippingController>(context, listen: false);
    final delivery = Provider.of<DeliveryManController>(context, listen: false);
    final notification = Provider.of<NotificationController>(context, listen: false);
    final review = Provider.of<ProductReviewController>(context, listen: false);

    await Future.wait([
      profile.getSellerInfo(),
      bank.getAnalyticsFilterData(context, 'overall'),
    ]);
    if (!mounted) return;

    bank.setRevenueFilterType(0, false);
    unawaited(bank.getDashboardRevenueData(context, 'yearEarn'));

    unawaited(bank.getBankInfo(context));
    if (order.orderModel == null || reload) {
      unawaited(order.getOrderList(context, 1, 'all', null, reload: reload));
    }
    if (splashController.configModel != null) {
      unawaited(splashController.getColorList());
    }
    unawaited(product.getStockOutProductList(1, 'en', reload: reload));
    unawaited(product.getTopSellingProductList(1, context, 'en', reload: reload));
    unawaited(shipping.getCategoryWiseShippingMethod());
    unawaited(shipping.getSelectedShippingMethodType(context));
    unawaited(delivery.getTopDeliveryManList(context));
    unawaited(notification.getNotificationList(1));
    unawaited(product.getStockLimitStatus(context));
    product.setShowCookie(true, notify: false);
    unawaited(product.getMostPopularProductList(1, context, 'en', reload: reload));
    unawaited(review.getReviewList(context));
  }

  @override
  void initState() {
    super.initState();
    final bank = Provider.of<BankInfoController>(context, listen: false);

    bank.setAnalyticsFilterName(context, 'overall', false, fetch: false);
    bank.setAnalyticsFilterType(0, false);
    _loadData(context, true);

    _tSync = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final order = Provider.of<OrderController>(context, listen: false);
      unawaited(order.getOrderList(context, 1, 'all', null, reload: false));
    });
  }

  @override
  void dispose() {
    _tSync?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double limitedStockCardHeight = MediaQuery.of(context).size.width / 1.4;

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Consumer<OrderController>(builder: (context, order, child) {
          return RefreshIndicator(
            onRefresh: () async {
              Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterName(context, 'overall',true);
              Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterType(0,true);
              await _loadData(context, true);
              await Provider.of<DeliveryManController>(context, listen: false)
                  .getNearStoreOnlineRiders();
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: QuikseeHomeHeaderWidget(onMenuTap: widget.onOpenMenu),
                ),
                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      OngoingOrderWidget(callback: widget.callback),

                      CompletedOrderWidget(callback: widget.callback),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Consumer<ProductController>(
                        builder: (context, prodProvider, child) {
                          List<Product> productList;
                          productList = prodProvider.stockOutProductList ?? [];
                          return productList.isNotEmpty ?
                          Container(
                            height: limitedStockCardHeight,
                            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: StockOutProductView(isHome: true),
                            ),
                          ) : const SizedBox();
                        }
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      const ChartWidget(),

                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      const TopSellingProductScreen(isMain: true),

                      const MostPopularProductScreen(isMain: true),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Provider.of<SplashController>(context, listen: false).configModel?.shippingMethod != 'inhouse_shipping'
                          ? const TopDeliveryManViewWidget(isMain: true)
                          : const SizedBox()

                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class TutorialFlowDialogWidget extends StatelessWidget {
  const TutorialFlowDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      color: Colors.red,
    );
  }
}
