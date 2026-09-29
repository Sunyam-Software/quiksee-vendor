import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_tab_view_screen.dart';
import 'package:quiksee_vendor_app/features/clearance_sale/screens/clearance_sale_screen.dart';
import 'package:quiksee_vendor_app/features/restock/screens/restock_list_screen.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:quiksee_vendor_app/features/discount_expense/screens/discount_expense_report_screen.dart';
import 'package:quiksee_vendor_app/features/wallet/screens/wallet_history_screen.dart';
import 'package:quiksee_vendor_app/features/vat_management/screens/vat_management_screen.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_bottom_sheet_widget.dart';
import 'package:quiksee_vendor_app/features/chat/screens/inbox_screen.dart';
import 'package:quiksee_vendor_app/features/coupon/screens/coupon_list_screen.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/nav_bar_screen.dart';
import 'package:quiksee_vendor_app/features/delivery_man/widgets/near_store_online_riders_widget.dart';
import 'package:quiksee_vendor_app/features/menu/widgets/sign_out_confirmation_dialog_widget.dart';
import 'package:quiksee_vendor_app/features/more/screens/html_view_screen.dart';
import 'package:quiksee_vendor_app/features/product/screens/product_list_screen.dart';
import 'package:quiksee_vendor_app/features/profile/screens/profile_view_screen.dart';
import 'package:quiksee_vendor_app/features/review/screens/product_review_screen.dart';
import 'package:quiksee_vendor_app/features/shop/screens/shop_screen.dart';
import 'package:quiksee_vendor_app/features/shop/screens/opening_hours_screen.dart';
import 'package:quiksee_vendor_app/features/wallet/screens/wallet_screen.dart';
import 'package:quiksee_vendor_app/features/bank_info/screens/bank_info_screen.dart';
import 'package:quiksee_vendor_app/features/settings/screens/setting_screen.dart';

import '../../../main.dart';

class MenuBottomSheetWidget extends StatelessWidget {
  const MenuBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final configModel = Provider.of<SplashController>(context, listen: false).configModel;
    final profileImage =
        Provider.of<ProfileController>(context, listen: false).userInfoModel?.imageFullUrl?.path;

    return Consumer<SplashController>(
      builder: (context, splashController, _) {
        final menuItems = _buildMenuItems(context, configModel, splashController, profileImage);

        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: QuikseeBrandColors.seeTextGreen.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: QuikseeBrandColors.featuredSectionBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            QuikseeBrandColors.seeTextGreen,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            Images.myShop,
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage your business',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Text(
                            'All in one place',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeExtraLargeTwenty,
                              color: QuikseeBrandColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    0,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                  ),
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.88,
                    children: menuItems,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault + MediaQuery.paddingOf(context).bottom,
                ),
                child: _MenuFooterButton(
                  icon: Images.logOut,
                  label: getTranslated('logout', context) ?? 'Logout',
                  isLogout: true,
                  onTap: () {
                    Navigator.pop(context);
                    Future.microtask(() {
                      final rootContext = Get.context;
                      if (rootContext == null) return;
                      showModalBottomSheet(
                        context: rootContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SignOutConfirmationDialogWidget(),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<QuikseeBottomSheetWidget> _buildMenuItems(
    BuildContext context,
    ConfigModel? configModel,
    SplashController splashController,
    String? profileImage,
  ) {
    return [
      QuikseeBottomSheetWidget(
        image: profileImage ?? '',
        isProfile: true,
        title: getTranslated('profile', context),
        onTap: () => _handleMenuTap(context, const ProfileScreenView()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.myShop,
        tintBrandGreen: true,
        title: getTranslated('my_shop', context),
        onTap: () => _handleMenuTap(context, const ShopScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.shipping,
        tintBrandGreen: true,
        title: getTranslated('opening_hours', context) ?? 'Store Hours',
        onTap: () => _handleMenuTap(context, const OpeningHoursScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.addProduct,
        tintBrandGreen: true,
        title: getTranslated('add_product', context),
        onTap: () => _handleMenuTap(context, const AddProductTabView(fromHome: false)),
      ),
      QuikseeBottomSheetWidget(
        image: Images.productIconPp,
        title: getTranslated('products', context),
        onTap: () => _handleMenuTap(context, const ProductListMenuScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.reviewIcon,
        title: getTranslated('reviews', context),
        onTap: () => _handleMenuTap(context, const ProductReviewScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.couponIcon,
        title: getTranslated('coupons', context),
        onTap: () => _handleMenuTap(context, const CouponListScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.deliveryManIcon,
        title: getTranslated('deliveryman', context),
        onTap: () {
          Navigator.pop(context);
          Future.microtask(() => NearStoreOnlineRidersSheet.show(Get.context!));
        },
      ),
      if (_isPosMenuVisible(configModel))
        QuikseeBottomSheetWidget(
          image: Images.pos,
          title: getTranslated('pos', context),
          onTap: () => _handleMenuTap(context, const NavBarScreen()),
        ),
      QuikseeBottomSheetWidget(
        image: Images.restockIcon,
        title: getTranslated('restock', context),
        onTap: () => _handleMenuTap(context, const RestockListScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.clearanceSaleImage,
        tintBrandGreen: true,
        title: getTranslated('clearance_sale', context),
        onTap: () => _handleMenuTap(context, const ClearanceSaleScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.wallet,
        tintBrandGreen: true,
        title: getTranslated('wallet', context),
        onTap: () => _handleMenuTap(context, const WalletScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.transactions,
        tintBrandGreen: true,
        title: getTranslated('total_transactions', context) ?? 'Total Transactions',
        onTap: () => _handleMenuTap(context, const WalletHistoryScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.couponIcon,
        tintBrandGreen: true,
        title: getTranslated('my_discounts_and_sales', context) ?? 'My Discounts & Sales',
        onTap: () => _handleMenuTap(context, const DiscountExpenseReportScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.message,
        tintBrandGreen: true,
        title: getTranslated('inbox', context),
        onTap: () => _handleMenuTap(context, const InboxScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.reportIcon,
        tintBrandGreen: true,
        title: getGstTranslated('vat_management', context, fallback: 'GST Report'),
        onTap: () => _handleMenuTap(context, const VatManagementScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.language,
        tintBrandGreen: true,
        title: getTranslated('settings', context),
        onTap: () => _handleMenuTap(context, const SettingsScreen()),
      ),
      QuikseeBottomSheetWidget(
        image: Images.bankingInfo,
        tintBrandGreen: true,
        title: getTranslated('bank_info', context),
        onTap: () => _handleMenuTap(context, const BankInfoScreen()),
      ),
      if (getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.termsAndCondition,
          title: getTranslated('terms_and_condition', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(
              page: getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages),
            ),
          ),
        ),
      if (getPageBySlug('about-us', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.aboutUs,
          title: getTranslated('about_us', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(page: getPageBySlug('about-us', splashController.defaultBusinessPages)),
          ),
        ),
      if (getPageBySlug('privacy-policy', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.privacyPolicy,
          tintBrandGreen: true,
          title: getTranslated('privacy_policy', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(page: getPageBySlug('privacy-policy', splashController.defaultBusinessPages)),
          ),
        ),
      if (getPageBySlug('refund-policy', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.refundPolicy,
          title: getTranslated('refund_policy', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(page: getPageBySlug('refund-policy', splashController.defaultBusinessPages)),
          ),
        ),
      if (getPageBySlug('return-policy', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.returnPolicy,
          tintBrandGreen: true,
          title: getTranslated('return_policy', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(page: getPageBySlug('return-policy', splashController.defaultBusinessPages)),
          ),
        ),
      if (getPageBySlug('cancellation-policy', splashController.defaultBusinessPages) != null)
        QuikseeBottomSheetWidget(
          image: Images.cPolicy,
          title: getTranslated('cancellation_policy', context),
          onTap: () => _handleMenuTap(
            context,
            HtmlViewScreen(
              page: getPageBySlug('cancellation-policy', splashController.defaultBusinessPages),
            ),
          ),
        ),
    ];
  }

  void _handleMenuTap(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.microtask(
      () => Navigator.push(
        Get.context!,
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }

  BusinessPageModel? getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
    if (pagesList == null || pagesList.isEmpty) return null;
    for (final page in pagesList) {
      if (page.slug == slug) return page;
    }
    return null;
  }

  bool _isPosMenuVisible(ConfigModel? configModel) {
    return (configModel?.posActive ?? 0) == 1;
  }
}

class _MenuFooterButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isLogout;
  final VoidCallback onTap;

  const _MenuFooterButton({
    required this.icon,
    required this.label,
    this.isLogout = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F9F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon == Images.appInfo
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        QuikseeBrandColors.seeTextGreen,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
                    )
                  : Image.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: QuikseeBrandColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
