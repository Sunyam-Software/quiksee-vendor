import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/profile/screens/profile_screen.dart';
import 'package:quiksee_vendor_app/features/profile/widgets/theme_changer_widget.dart';
import 'package:quiksee_vendor_app/features/product/screens/product_list_screen.dart';
import 'package:quiksee_vendor_app/features/order/screens/order_screen.dart';
import 'package:quiksee_vendor_app/features/wallet/screens/wallet_history_screen.dart';
import 'package:quiksee_vendor_app/features/order_transaction/screens/order_transaction_screen.dart';

class ProfileScreenView extends StatefulWidget {
  const ProfileScreenView({super.key});

  @override
  ProfileScreenViewState createState() => ProfileScreenViewState();
}

class ProfileScreenViewState extends State<ProfileScreenView> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        isBackButtonExist: true,
        title: getTranslated('my_profile', context),
        useQuikseeBrandedHeader: true,
      ),
      body: Consumer<ProfileController>(
        builder: (context, profile, child) {
          final user = profile.userInfoModel;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final String nameLine = user.hasDisplayName
              ? user.displayName()
              : (getTranslated('enter_first_name', context) ?? 'Add your name');
          final String subtitleLine = user.displaySubtitle();

          return SingleChildScrollView(
            child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Stack(
                    children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Dimensions.paddingSizeMedium,
                        left: Dimensions.paddingSizeExtraSmall,
                        right: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        child: Container(
                          height: 120,
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                QuikseeBrandColors.seeTextGreen,
                                QuikseeBrandColors.forestGreen,
                              ],
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              IgnorePointer(
                                child: Center(
                                  child: Opacity(
                                    opacity: 0.14,
                                    child: Image.asset(
                                      Images.quikseeLogo,
                                      height: 88,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        Dimensions.paddingSizeSmall,
                                        0,
                                        Dimensions.paddingSizeSmall,
                                        0,
                                      ),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.white, width: 3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                                          child: QuikseeImageWidget(
                                            width: 70,
                                            height: 70,
                                            image: user.imageFullUrl?.path ?? '',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          Dimensions.paddingSizeSmall,
                                          0,
                                          Dimensions.paddingSizeSmall,
                                          Dimensions.paddingSizeSmall,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nameLine,
                                              maxLines: 2,
                                              textAlign: TextAlign.start,
                                              style: robotoBold.copyWith(
                                                color: Colors.white,
                                                fontSize: Dimensions.fontSizeExtraLarge,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (subtitleLine.isNotEmpty) ...[
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Text(
                                              subtitleLine,
                                              maxLines: 2,
                                              style: titilliumRegular.copyWith(
                                                color: Colors.white.withValues(alpha: 0.92),
                                                fontSize: Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Flexible(
                                      flex: 1,
                                      child: SizedBox(width: Dimensions.paddingSizeSmall),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Provider.of<LocalizationController>(context, listen: false).isLtr
                          ? Alignment.topRight
                          : Alignment.topLeft,
                        child: GestureDetector(
                          onTap: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                            child: SizedBox(width: Dimensions.iconSizeLarge,
                                child: Image.asset(Images.editProfileIcon)),
                          ),
                        ),
                    ),
                  ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB( Dimensions.paddingSizeMedium,
                       Dimensions.paddingSeven, Dimensions.paddingSizeMedium, Dimensions.paddingSizeMedium),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: InfoItem(
                        icon: Images.totalProducts,
                        title: 'products',
                        amount: (user.productCount ?? 0).toString(),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProductListMenuScreen()),
                        ),
                      )),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(child: InfoItem(
                        icon: Images.totalOrders,
                        title: 'orders',
                        amount: (user.ordersCount ?? 0).toString(),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrderScreen(isBacButtonExist: true)),
                        ),
                      )),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(children: [
                      Expanded(child: InfoItem(
                        icon: Images.totalEarningIcon,
                        title: 'earned',
                        amount: (user.wallet?.earnedAmount ?? 0).toString(),
                        isMoney: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
                        ),
                      )),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(child: InfoItem(
                        icon: Images.transactions,
                        title: 'commission',
                        amount: (user.wallet?.commissionGiven ?? 0).toString(),
                        isMoney: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrderTransactionScreen()),
                        ),
                      )),
                    ]),
                  ]),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeMedium),
                  child: ThemeChangerWidget(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String? icon;
  final String? title;
  final String? amount;
  final bool isMoney;
  final VoidCallback? onTap;
  const InfoItem({super.key, this.icon, this.title, this.amount, this.isMoney = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        child: Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha:.05),
            spreadRadius: 0,
            blurRadius: 2,
            offset: Offset.fromDirection(0,0),
          ),

          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha:.05),
            spreadRadius: -5,
            blurRadius: 12,
            offset: Offset.fromDirection(0,6),
          ),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [

        Container(
          width: Dimensions.iconSizeExtraLarge + 8,
          height: Dimensions.iconSizeExtraLarge + 8,
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: QuikseeBrandColors.seeTextGreen,
            shape: BoxShape.circle,
          ),
          child: QuikseeAssetImageWidget(
            icon!,
            width: Dimensions.iconSizeLarge,
            height: Dimensions.iconSizeLarge,
            color: Colors.white,
          ),
        ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
            child: !isMoney ?
            Text(amount!, style: robotoBold.copyWith(
                color: Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeLarge,
            )) :
            Text('${Provider.of<SplashController>(context, listen: false).myCurrency!.symbol} ${NumberFormat.compact().format(double.parse(amount!))}',
              style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
            ),
          ),

          Text(getTranslated(title, context)!, textAlign: TextAlign.center, style: titilliumRegular.copyWith(
              color:  Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeSmall
          )),
        ]),
        ),
      ),
    );
  }
}
