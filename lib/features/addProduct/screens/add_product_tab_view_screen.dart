import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/edt_product_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/product_general_info_data_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_next_screen.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_screen.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_seo_screen.dart';
import 'package:quiksee_vendor_app/features/addProduct/widgets/add_product_tabbar_widget.dart';
import 'package:quiksee_vendor_app/features/ai/widgets/genertate_count_widget.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';

class AddProductTabView extends StatefulWidget {
  final Product? product;
  final AddProductModel? addProduct;
  final EditProductModel? editProduct;
  final bool fromHome;
  const AddProductTabView({super.key, this.product, this.addProduct, this.editProduct, required this.fromHome});

  @override
  State<AddProductTabView> createState() => _AddProductTabViewState();
}

class _AddProductTabViewState extends State<AddProductTabView>  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AddProductScreenState> _firstTabKey = GlobalKey<AddProductScreenState>();
  final GlobalKey<AddProductNextScreenState> _secondTabKey = GlobalKey<AddProductNextScreenState>();

  ProductGeneralInfoData? productGeneralInfoData;
  ProductCombinedData? productCombinedData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging && _tabController.index > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fetchDataFromFirstTab();
          _fetchDataFromSecondTab();
        });
      }
    });
  }

  void _fetchDataFromFirstTab() {
    if (!mounted) return;
    try {
      ProductGeneralInfoData? latestData = _firstTabKey.currentState?.getCurrentFormData();
      setState(() {
        productGeneralInfoData = latestData;
      });
    } catch (_) {}
  }

  void _fetchDataFromSecondTab() {
    if (!mounted) return;
    try {
      ProductCombinedData? data = _secondTabKey.currentState?.getCurrentFormData();
      setState(() {
        productCombinedData = data;
      });
    } catch (_) {}
  }

  void _navigateToTab(int index) {
    if (!mounted) return;
    if (index >= 1) {
      _fetchDataFromFirstTab();
    }
    if (index >= 2) {
      _fetchDataFromSecondTab();
    }

    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: QuikseeAppBarWidget(
          useQuikseeBrandedHeader: true,
          centerTitle: false,
          title: widget.product != null ? getTranslated('update_product', context) : getTranslated('add_product', context),
          widget: GeneratesLeftCount(),
          isFilter: true,
          isAction: true,
          onBackPressed: () {
            Navigator.of(context).pop();
          },
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              height: 60,
              child: AddProductTitleBar(tabController: _tabController),
            ),

            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  AddProductScreen(product: widget.product, addProduct: widget.addProduct, fromHome: widget.fromHome, onTabChanged: _navigateToTab, key: _firstTabKey),

                  AddProductNextScreen(
                    key: _secondTabKey,
                    categoryId: productGeneralInfoData?.categoryId,
                    subCategoryId:  productGeneralInfoData?.subCategoryId,
                    subSubCategoryId: productGeneralInfoData?.subSubCategoryId,
                    brandId: productGeneralInfoData?.brandId,
                    unit: productGeneralInfoData?.unit,
                    product: widget.product,
                    addProduct: productGeneralInfoData?.addProduct,
                    title: productGeneralInfoData?.title,
                    description: productGeneralInfoData?.description,
                    onTabChanged: _navigateToTab,
                  ),

                  AddProductSeoScreen(
                    unitPrice: productCombinedData?.unitPrice,
                    tax: productCombinedData?.tax,
                    unit: productCombinedData?.unit,
                    categoryId: productCombinedData?.categoryId,
                    subCategoryId: productCombinedData?.subCategoryId,
                    subSubCategoryId: productCombinedData?.subSubCategoryId,
                    brandyId: productCombinedData?.brandId,
                    discount: productCombinedData?.discount,
                    currentStock: productCombinedData?.currentStock,
                    minimumOrderQuantity: productCombinedData?.minimumOrderQuantity,
                    shippingCost: productCombinedData?.shippingCost,
                    product: widget.product,
                    addProduct: productCombinedData?.addProduct,
                    title: productCombinedData?.title,
                    description: productCombinedData?.description,
                    onTabChanged: _navigateToTab,
                  ),
                ],
              ),
            )

          ],
        ),
      );
  }
}