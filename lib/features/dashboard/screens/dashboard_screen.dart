import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_dialog_widget.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/digital_product_controller.dart';
import 'package:quiksee_vendor_app/features/ai/controllers/ai_controller.dart';
import 'package:quiksee_vendor_app/features/pos/controllers/cart_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/category_controller.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:quiksee_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee_vendor_app/helper/network_info.dart';
import 'package:quiksee_vendor_app/helper/order_wake_permission_helper.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/features/home/screens/home_page_screen.dart';
import 'package:quiksee_vendor_app/features/delivery_man/widgets/near_store_online_riders_widget.dart';
import 'package:quiksee_vendor_app/features/menu/widgets/menu_widget.dart';
import 'package:quiksee_vendor_app/features/order/screens/order_screen.dart';
import 'package:quiksee_vendor_app/features/refund/screens/refund_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    unawaited(Provider.of<ProfileController>(context, listen: false).hydrateSellerIdFromCache());
    String languageCode = Provider.of<LocalizationController>(context, listen: false).locale.countryCode == 'US'?
    'en':Provider.of<LocalizationController>(context, listen: false).locale.countryCode!.toLowerCase();
    Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    Provider.of<DigitalProductController>(context, listen: false).getDigitalAuthor();
    Provider.of<DigitalProductController>(context, listen: false).getPublishingHouse();
    Provider.of<CategoryController>(context,listen: false).getCategoryList(context, null, languageCode);
    Provider.of<CartController>(context,listen: false).getCartData();
    Provider.of<ShopController>(context, listen: false).getShopInfo();

    Provider.of<TransactionController>(context, listen: false).getTransactionList(context,'all','','');
    Provider.of<WalletController>(context, listen: false).getPaymentInfoList();

    if(Provider.of<SplashController>(context,listen: false).configModel?.isAiFeatureActive == 1) {
      Provider.of<AiController>(context,listen: false).generateLimitCheck();
    }

    _screens = [
      HomePageScreen(
        callback: () {
          setState(() {
            setPage(1);
          });
        },
        onOpenMenu: _openMenu,
      ),
      const OrderScreen(),
      const RefundScreen(fromNotification: false),
    ];

    NetworkInfo.checkConnectivity(context);
    _initOrderAlerts();
  }

  Future<void> _initOrderAlerts() async {
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final needsSetup = (prefs.getInt(AppConstants.orderWakeSetupVersion) ?? 0) <
          AppConstants.currentOrderWakeSetupVersion;
      if (needsSetup && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(getTranslated('order_wake_setup_title', context)!),
            content: Text(getTranslated('order_wake_setup_message', context)!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(getTranslated('ok', context)!),
              ),
            ],
          ),
        );
      }
    }

    await OrderWakePermissionHelper.requestAll();
    await OrderWakePermissionHelper.ensureAlertsActive();
    if (!mounted) return;
    await Provider.of<AuthController>(context, listen: false).updateToken(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_pageIndex != 0) {
          setPage(0);
        } else {
          _onWillPop(context);
        }
        if(didPop) return;
      },

      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _pageIndex == 0 ? const NearStoreRidersFab() : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: QuikseeBrandColors.forestGreen,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: QuikseeBrandColors.gold,
              unselectedItemColor: Colors.white70,
              selectedFontSize: Dimensions.fontSizeSmall,
              unselectedFontSize: Dimensions.fontSizeSmall,
              selectedLabelStyle: robotoBold,
              unselectedLabelStyle: robotoRegular,
              showUnselectedLabels: true,
              currentIndex: _pageIndex,
              type: BottomNavigationBarType.fixed,
              items: [
                _barItem(Images.home, getTranslated('home', context), 0),
                _barItem(Images.order, getTranslated('my_order', context), 1),
                _barItem(Images.refund, getTranslated('refund', context), 2),
                _barItem(Images.menu, getTranslated('menu', context), 3),
              ],
              onTap: (int index) {
                if (index != 3) {
                  setState(() {
                    setPage(index);
                  });
                } else {
                  _openMenu();
                }
              },
            ),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: _screens.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _screens[index];
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _barItem(String icon, String? label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom : Dimensions.paddingSizeExtraSmall),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(width: index == _pageIndex ? Dimensions.iconSizeLarge : Dimensions.iconSizeMedium,
              child: Image.asset(
              icon,
              color: index == _pageIndex ? QuikseeBrandColors.gold : Colors.white70,
            )
            ),
          ],
        ),
      ),
      label: label,
    );
  }

  void setPage(int pageIndex) {
    setState(() {
      _pageController.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black26,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.76,
          widthFactor: 1,
          child: const MenuBottomSheetWidget(),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    showAnimatedDialogWidget(context,  ConfirmationDialogWidget(icon: Images.logOut,
      title: getTranslated('exit_app', context),
      description: getTranslated('do_you_want_to_exit_the_app', context),
      onYesPressed: () {
        SystemNavigator.pop();
      },
    ), isFlip: true);

    return true;
  }

}
