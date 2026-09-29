import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/filter_icon_widget.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/product/widgets/product_filter_bottomsheet_widget.dart';
import 'package:quiksee_vendor_app/features/product/widgets/status_filter_widget.dart';
import 'package:quiksee_vendor_app/helper/debounce_helper.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_search_field_widget.dart';
import 'package:quiksee_vendor_app/features/product/widgets/product_widget.dart';

class ProductListMenuScreen extends StatefulWidget {
  final bool fromNotification;
  const ProductListMenuScreen({super.key,  this.fromNotification = false});
  @override
  State<ProductListMenuScreen> createState() => _ProductListMenuScreenState();
}

class _ProductListMenuScreenState extends State<ProductListMenuScreen> {
  final DebounceHelper _debounce = DebounceHelper(milliseconds: 500);
  TextEditingController searchController = TextEditingController();
  int? userId;
  Timer? _watchdog;
  int _watchdogTries = 0;
  bool _loadStarted = false;
  ProfileController? _profileController;

  String _languageCode() {
    final locale = Provider.of<LocalizationController>(context, listen: false).locale;
    final lang = (locale.languageCode).trim().toLowerCase();
    if (lang.isNotEmpty && lang != 'us') return lang;
    final country = (locale.countryCode ?? '').trim().toLowerCase();
    if (country == 'us' || country.isEmpty) return 'en';
    return country;
  }

  String? _sellerIdString() {
    final id = Provider.of<ProfileController>(context, listen: false).userId ?? userId;
    if (id == null) return null;
    return id.toString();
  }

  Future<void> _loadProductList({
    String search = '',
    bool replace = false,
  }) async {

    _loadStarted = true;

    final productController = Provider.of<ProductController>(context, listen: false);
    final profile = Provider.of<ProfileController>(context, listen: false);

    bool hasUsableList() =>
        productController.sellerProductModel != null &&
        (productController.sellerProductModel!.products?.isNotEmpty ?? false);

    if (!replace && productController.isSellerListLoading) {
      try {
        await productController
            .waitForSellerListLoad()
            .timeout(const Duration(seconds: 45));
      } catch (_) {}
      if (!mounted) return;
      if (hasUsableList() || productController.sellerProductModel != null) return;
    }

    var sellerId = profile.userId ?? userId ?? productController.sellerProductOwnerId;
    if (sellerId == null) {
      sellerId = await profile.resolveSellerId(networkTimeout: const Duration(seconds: 20));
    }
    if (!mounted) return;
    if (sellerId == null) {

      _loadStarted = false;
      return;
    }
    userId = sellerId;

    if (!replace &&
        hasUsableList() &&
        search.isEmpty &&
        !widget.fromNotification) {
      return;
    }

    if (!replace && productController.isSellerListLoading) {
      try {
        await productController
            .waitForSellerListLoad()
            .timeout(const Duration(seconds: 45));
      } catch (_) {}
      if (!mounted) return;
      if (hasUsableList() || productController.sellerProductModel != null) return;
    }

    await productController.getSellerProductList(
      sellerId.toString(), 1, _languageCode(), search,
      filterSearchModel: productController.filterModel.copyWith(reload: true),
      replace: replace,
    );
  }

  Future<void> _forceReloadNow() async {
    final profile = Provider.of<ProfileController>(context, listen: false);
    final productController = Provider.of<ProductController>(context, listen: false);

    var sellerId = profile.userId ?? userId ?? productController.sellerProductOwnerId;
    sellerId ??= await profile.resolveSellerId(networkTimeout: const Duration(seconds: 15));
    if (!mounted) return;

    if (sellerId == null) {
      showQuikseeSnackBarWidget(
        'Unable to refresh right now. Please wait a moment and try again.',
        context,
        sanckBarType: SnackBarType.error,
      );
      return;
    }

    userId = sellerId;

    await _loadProductList(
      search: searchController.text.trim(),
      replace: true,
    );
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdogTries = 0;

    _watchdog = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final productController = Provider.of<ProductController>(context, listen: false);
      if (productController.sellerProductModel != null) {
        timer.cancel();
        return;
      }

      if (productController.isSellerListLoading) {
        return;
      }
      _watchdogTries++;
      if (_watchdogTries > 3) {
        timer.cancel();
        return;
      }
      _loadProductList(search: searchController.text.trim(), replace: false);
    });
  }

  void _getBrandList() {
    String languageCode = _languageCode();
    Provider.of<ProductController>(Get.context!,listen: false).getBrandList(Get.context!, languageCode);
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final sellerId = _profileController?.userId;
    if (sellerId == null) return;
    userId = sellerId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadStarted) return;
      final productController = Provider.of<ProductController>(context, listen: false);
      if (productController.sellerProductModel == null &&
          !productController.isSellerListLoading) {
        _loadProductList(search: searchController.text.trim(), replace: false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _profileController = Provider.of<ProfileController>(context, listen: false);
    _profileController!.addListener(_onProfileChanged);
    userId = _profileController!.userId;
    final productController = Provider.of<ProductController>(context, listen: false);
    final profile = _profileController!;
    final cachedOwnerId = productController.sellerProductOwnerId;
    final sellerMismatch = userId != null &&
        cachedOwnerId != null &&
        cachedOwnerId != userId;

    if (sellerMismatch || widget.fromNotification) {
      productController.clearFilterData();
      productController.emptySellerProduct(notify: false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final hasCache = productController.sellerProductModel != null &&
          (productController.sellerProductModel!.products?.isNotEmpty ?? false) &&
          !widget.fromNotification &&
          !sellerMismatch;

      if (profile.userId != null) {
        userId = profile.userId;
      } else if (userId == null) {
        await profile.hydrateSellerIdFromCache();
        if (!mounted) return;
        userId = profile.userId ?? userId;
      }

      if (hasCache) {

        _loadStarted = true;
        return;
      }

      final stuckEmpty = productController.isSellerListLoading &&
          productController.sellerProductModel == null;
      await _loadProductList(
        search: '',
        replace: stuckEmpty,
      );
      if (mounted) _startWatchdog();
    });
  }

  void _exitProductList() {
    if (!mounted) return;
    if (widget.fromNotification || !Navigator.canPop(context)) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _exitProductListDeferred() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _exitProductList();
    });
  }

  @override
  void dispose() {
    _profileController?.removeListener(_onProfileChanged);
    _watchdog?.cancel();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitProductListDeferred();
      },

      child: Scaffold(
        appBar: QuikseeAppBarWidget(
          useQuikseeBrandedHeader: true,
          title: getTranslated('product_list', context),
          isAction: true,
          isFilter: true,
          widget: IconButton(
            onPressed: _forceReloadNow,
            icon: const Icon(Icons.refresh_rounded),
          ),
          onBackPressed: _exitProductListDeferred,
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.only(top : Dimensions.paddingSizeMedium),
            color: Theme.of(context).cardColor,
            child: StatusFilterWidget(
              onFilterChanged: (index) {},
            ),
          ),

          SizedBox(height: 80,
            child: Consumer2<ProductController, ProfileController>(
              builder: (context, productController, profile, _) {
                if (profile.userId != null) {
                  userId = profile.userId;
                }

                return Container(
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeMedium, vertical: Dimensions.paddingSizeExtraSmall),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuikseeSearchFieldWidget(
                            controller: searchController,
                            hint: getTranslated('search_by_product_name', context),
                            prefix: Images.iconsSearch,
                            iconPressed: () => _forceReloadNow(),
                            onSubmit: (text) => _loadProductList(
                              search: text.trim(),
                              replace: true,
                            ),
                            onTap: () {

                            },
                            onChanged: (value)=> _debounce.run(() async {
                              final trimmed = value.trim();

                              if (trimmed.isEmpty &&
                                  (productController.sellerProductModel?.search ?? '').isEmpty) {
                                return;
                              }
                              final sellerId = _sellerIdString();
                              if (sellerId == null) {
                                await _loadProductList(search: trimmed, replace: true);
                                return;
                              }
                              userId = int.tryParse(sellerId) ?? userId;
                              productController.getSellerProductList(
                                sellerId, 1, _languageCode(), trimmed,
                                filterSearchModel: productController.filterModel.copyWith(
                                  reload: true,
                                ),
                                replace: true,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSize),

                        InkWell(
                          onTap: _forceReloadNow,
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              border: Border.all(
                                color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: productController.isSellerListLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 22,
                                    color: Theme.of(context).primaryColor,
                                  ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSize),

                        FilterIconWidget(
                          filterCount: _getFilterCount(productController.sellerProductModel),
                          onTap: productController.sellerProductModel == null ? null : () {
                            _getBrandList();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (builder) => const ProductFilterBottomSheet(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            )
          ),
          const SizedBox(height: Dimensions.paddingSize),

          Expanded(child: ProductViewWidget(
            sellerId: Provider.of<ProfileController>(context).userId ?? userId,
            fromNotification: widget.fromNotification,
            keyboardHeight: MediaQuery.of(context).viewInsets.bottom,

            ownBootstrap: false,
          ))

          ],
        ),
      ),
    );
  }

  int _getFilterCount(ProductModel? sellerProductModel) {
    if (sellerProductModel == null) return 0;
    final int nonNullFilterCount = [
      sellerProductModel.productType,
      sellerProductModel.maxPrice,
      sellerProductModel.endDate,
      sellerProductModel.status,
      sellerProductModel.isApproved,
      sellerProductModel.sorting,
      sellerProductModel.offerType,
    ].whereType<Object>().length;

    final int categoryCount = sellerProductModel.categoryIds?.length ?? 0;
    final int subCategoryCount = sellerProductModel.filterSubCategoryIds?.length ?? 0;
    final int subSubCategoryCount = sellerProductModel.filterSubSubCategoryIds?.length ?? 0;
    final int brandCount = sellerProductModel.brandIds?.length ?? 0;
    final int publisherCount = sellerProductModel.publishHouseIds?.length ?? 0;
    final int authorCount = sellerProductModel.authorIds?.length ?? 0;

    return nonNullFilterCount +
        categoryCount +
        subCategoryCount +
        subSubCategoryCount +
        brandCount +
        publisherCount +
        authorCount;
  }

}
