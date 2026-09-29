import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_tab_view_screen.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/order/screens/order_screen.dart';
import 'package:quiksee_vendor_app/features/shop/widgets/animated_floating_button_widget.dart';
import 'package:quiksee_vendor_app/features/shop/widgets/shop_product_card_widget.dart';
import 'package:quiksee_vendor_app/features/product/screens/stock_out_product_screen.dart';

class ProductViewWidget extends StatefulWidget {
  final int? sellerId;
  final bool fromNotification;
  final double keyboardHeight;

  final bool ownBootstrap;
  const ProductViewWidget({
    super.key,
    required this.sellerId,
    this.fromNotification = false,
    required this.keyboardHeight,
    this.ownBootstrap = true,
  });

  @override
  State<ProductViewWidget> createState() => _ProductViewWidgetState();
}

class _ProductViewWidgetState extends State<ProductViewWidget> {
  ScrollController scrollController = ScrollController();
  String message = "";
  bool activated = false;
  bool endScroll = false;
  bool _bootstrapped = false;
  bool _isPaginating = false;
  ProfileController? _profileController;
  int? userId;

  String _languageCode() {
    final locale = Provider.of<LocalizationController>(context, listen: false).locale;
    final lang = (locale.languageCode).trim().toLowerCase();
    if (lang.isNotEmpty && lang != 'us') return lang;
    final country = (locale.countryCode ?? '').trim().toLowerCase();
    if (country == 'us' || country.isEmpty) return 'en';
    return country;
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final nearBottom = position.pixels >= (position.maxScrollExtent - 280);

    if (nearBottom && !position.outOfRange) {
      if (!endScroll) {
        setState(() {
          endScroll = true;
          message = "bottom";
        });
        if (kDebugMode) {
          print('=========$message=========');
        }
      }
      _loadNextPageIfNeeded();
    } else if (endScroll) {
      setState(() {
        endScroll = false;
      });
    }
  }

  Future<void> _loadNextPageIfNeeded() async {
    if (!mounted || _isPaginating) return;
    final prodProvider = Provider.of<ProductController>(context, listen: false);
    final model = prodProvider.sellerProductModel;
    if (model == null) return;

    final int total = model.totalSize ?? 0;
    final int loaded = model.products?.length ?? 0;
    if (total <= 0 || loaded >= total) return;

    final int currentOffset = model.offset ?? 1;
    final int pageLimit = model.limit ?? 10;
    final int pageSize = (total / pageLimit).ceil();
    if (currentOffset >= pageSize) return;

    final id = Provider.of<ProfileController>(context, listen: false).userId ?? userId;
    if (id == null) return;

    _isPaginating = true;
    if (mounted) setState(() {});
    try {
      await prodProvider.getSellerProductList(
        id.toString(),
        currentOffset + 1,
        _languageCode(),
        model.search ?? '',
        filterSearchModel: prodProvider.filterModel.copyWith(reload: false),
      );
    } finally {
      _isPaginating = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _profileController?.removeListener(_onProfileChanged);
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted || !widget.ownBootstrap) return;
    final id = _profileController?.userId;
    if (id == null) return;
    userId = id;
    _bootstrapOnce();
  }

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(_scrollListener);
    _profileController = Provider.of<ProfileController>(context, listen: false);
    if (widget.ownBootstrap) {
      _profileController!.addListener(_onProfileChanged);
    }
    userId = _profileController!.userId ?? widget.sellerId;

    if (widget.ownBootstrap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bootstrapOnce();
      });
    } else {
      _bootstrapped = true;
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ProductViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.ownBootstrap) return;
    if (widget.sellerId != null && widget.sellerId != oldWidget.sellerId) {
      userId = widget.sellerId;
      _bootstrapOnce(force: true);
    }
  }

  Future<void> _bootstrapOnce({bool force = false}) async {
    if (!widget.ownBootstrap) return;
    if (!mounted) return;
    if (_bootstrapped && !force) return;

    final productController = Provider.of<ProductController>(context, listen: false);
    final profile = Provider.of<ProfileController>(context, listen: false);

    if (!force && productController.sellerProductModel != null) {
      _bootstrapped = true;
      return;
    }

    if (!force && productController.isSellerListLoading) {
      _bootstrapped = true;
      await productController.waitForSellerListLoad();
      if (!mounted) return;
      if (productController.sellerProductModel != null) return;
    }

    _bootstrapped = true;

    var id = profile.userId ?? userId ?? widget.sellerId ?? productController.sellerProductOwnerId;
    if (id == null) {
      id = await profile.resolveSellerId();
      if (!mounted) return;
    }
    if (id == null) {
      _bootstrapped = false;
      return;
    }

    userId = id;
    await productController.getSellerProductList(
      id.toString(),
      1,
      _languageCode(),
      '',
      filterSearchModel: productController.filterModel.copyWith(reload: true),
      replace: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final productController = Provider.of<ProductController>(context, listen: false);
        final profile = Provider.of<ProfileController>(context, listen: false);
        final id = profile.userId ?? userId ?? widget.sellerId;
        if (id == null) return;
        await productController.getSellerProductList(
          id.toString(), 1,
          _languageCode(),
          productController.sellerProductModel?.search ?? '',
          filterSearchModel: productController.filterModel.copyWith(reload: true),
          replace: true,
        );
      },
      child: Consumer2<ProductController, ProfileController>(
        builder: (context, prodProvider, profile, child) {
          final profileId = profile.userId ?? userId ?? widget.sellerId;
          if (profileId != null) {
            userId = profileId;
          }

          if (widget.ownBootstrap &&
              !_bootstrapped &&
              profileId != null &&
              prodProvider.sellerProductModel == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _bootstrapOnce();
            });
          }

          final bool hasProducts = prodProvider.sellerProductModel?.products != null &&
              prodProvider.sellerProductModel!.products!.isNotEmpty;
          final bool showShimmer = !hasProducts &&
              (prodProvider.sellerProductModel == null ||
                  prodProvider.isSellerListLoading ||
                  (widget.ownBootstrap && !_bootstrapped));

          return SizedBox(height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                if (hasProducts)

                  ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),

                    cacheExtent: 420,
                    itemCount: prodProvider.sellerProductModel!.products!.length +
                        (_isPaginating ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      final products = prodProvider.sellerProductModel!.products!;
                      if (index >= products.length) {
                        return const Padding(
                          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: ShopProductWidget(productModel: products[index]),
                      );
                    },
                  )
                else if (showShimmer)
                  const OrderShimmer()
                else
                  const NoDataScreen(),

               if(widget.keyboardHeight == 0)...[
                 if(!endScroll)
                   Positioned(
                     bottom: 20,
                     right: Provider.of<LocalizationController>(context, listen: false).isLtr ? 20: null,
                     left: Provider.of<LocalizationController>(context, listen: false).isLtr ? null: 20,
                     child: Align(
                       alignment: Alignment.bottomRight,
                       child: ScrollingFabAnimated(
                         width: 150,
                         color: Theme.of(context).cardColor,
                         icon: SizedBox(width: Dimensions.iconSizeExtraLarge,child: Image.asset(Images.addIcon)),
                         text: Text(getTranslated('add_new', context)!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),
                         onPress: (){
                           Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddProductTabView(product: null, addProduct: null, fromHome: false,)));
                         },
                         animateIcon: true,
                         inverted: false,
                         scrollController: scrollController,
                         radius: 10.0,
                       ),
                     ),
                   ),

                 if(!endScroll)
                   Positioned(bottom: 100,
                     right: Provider.of<LocalizationController>(context, listen: false).isLtr ? 22: null,
                     left: Provider.of<LocalizationController>(context, listen: false).isLtr ? null: 22,
                     child: ScrollingFabAnimated(width: 200, color: Theme.of(context).cardColor,
                       icon: SizedBox(width: Dimensions.iconSizeExtraLarge,child: Image.asset(Images.limitedStockIcon)),
                       text: Text(getTranslated('limited_stocks', context)!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),
                       onPress: () {
                         Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockOutProductScreen()));
                       },
                       animateIcon: true,
                       inverted: false,
                       scrollController: scrollController,
                       radius: 10.0,
                     ),
                   ),
               ],
              ],
            ),
          );
        },
      ),
    );
  }
}
