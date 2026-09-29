import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_image_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_tax_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/digital_product_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/variation_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/attribute_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/product_image_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/variant_type_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/services/add_product_service_interface.dart';
import 'package:quiksee_vendor_app/features/ai/controllers/ai_controller.dart';
import 'package:quiksee_vendor_app/features/ai/domain/models/ai_meta_seo_model.dart';
import 'package:quiksee_vendor_app/features/ai/domain/models/genara_setup_model.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/controllers/dynamic_field_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/category_controller.dart';
import 'package:quiksee_vendor_app/features/product/screens/product_list_screen.dart';
import 'package:quiksee_vendor_app/features/restock/controllers/restock_controller.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/edt_product_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/image_model.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/helper/product_helper.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';

class AddProductController extends ChangeNotifier {
  final AddProductServiceInterface shopServiceInterface;

  AddProductController({required this.shopServiceInterface});

  int _totalQuantity = 0;
  int get totalQuantity => _totalQuantity;
  String? _unitValue;
  String? get unitValue => _unitValue;
  int _discountTypeIndex = 0;
  int _taxTypeIndex = -1;
  String _imagePreviewSelectedType = 'large';
  int _unitIndex = 0;

  MetaSeoInfo? _metaSeoInfo = MetaSeoInfo();
  final TextEditingController maxSnippetController = TextEditingController(text: '-1');
  final TextEditingController maxImagePreviewController = TextEditingController(text: '-1');

  int get unitIndex => _unitIndex;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAttributeActive = false;
  bool get isAttributeActive => _isAttributeActive;

  EditProductModel? _editProduct;
  EditProductModel? get editProduct => _editProduct;
  Product? _editProductFull;
  Product? get editProductFull => _editProductFull;
  int get discountTypeIndex => _discountTypeIndex;
  int get taxTypeIndex => _taxTypeIndex;
  String get imagePreviewSelectedType => _imagePreviewSelectedType;

  bool _isMultiply = false;
  bool get isMultiply => _isMultiply;

  final picker = ImagePicker();
  List<TextEditingController> _titleControllerList = [];
  List<TextEditingController> _descriptionControllerList = [];

  List<TextEditingController>  get titleControllerList=> _titleControllerList;
  List<TextEditingController> get descriptionControllerList=> _descriptionControllerList;
  final TextEditingController _productCode = TextEditingController();
  TextEditingController get productCode => _productCode;
  List<FocusNode>? _titleNode;
  List<FocusNode>? _descriptionNode;
  List<FocusNode>? get titleNode => _titleNode;
  List<FocusNode>? get descriptionNode => _descriptionNode;
  int _productTypeIndex = 0;
  int get productTypeIndex => _productTypeIndex;

  int _totalVariantQuantity = 0;
  int get totalVariantQuantity => _totalVariantQuantity;

  List<Map<String, dynamic>>? productReturnImage  = [];
  int _variationTotalQuantity = 0;
  int get variationTotalQuantity  => _variationTotalQuantity;
  final bool _isCategoryLoading = false;
  bool get isCategoryLoading => _isCategoryLoading;
  int? _selectedPageIndex = 0;
  int? get selectedPageIndex => _selectedPageIndex;

  MetaSeoInfo? get metaSeoInfo => _metaSeoInfo;

  List<String> pages = ['general_info', 'variation_setup', 'product_seo'];
  List<String> imagePreviewType = ['large', 'medium', 'small'];

  TextEditingController unitPriceController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController shippingCostController = TextEditingController();
  TextEditingController minimumOrderQuantityController = TextEditingController();
  TextEditingController preparationTimeController = TextEditingController();
  TextEditingController youtubeLinkController = TextEditingController();

  @override
  void dispose() {
    unitPriceController.dispose();
    discountController.dispose();
    shippingCostController.dispose();
    minimumOrderQuantityController.dispose();
    preparationTimeController.dispose();
    youtubeLinkController.dispose();
    super.dispose();
  }

  void setTitle(int index, String title, {bool isUpdate = false}) {
    _titleControllerList[index].text = title;

    if(isUpdate) {
      notifyListeners();
    }
  }

  void setDescription(int index, String description) {
    _descriptionControllerList[index].text = description;
  }

  void getTitleAndDescriptionList(List<Language> languageList, EditProductModel? edtProduct){
    _titleControllerList = [];
    _descriptionControllerList = [];
    for(int i= 0; i<languageList.length; i++){
      if(edtProduct != null){
        if(i==0){
          String plainProductDetails = ProductHelper.htmlToPlainText(edtProduct.details ?? '');
          _titleControllerList.insert(i,TextEditingController(text: edtProduct.name)) ;
          _descriptionControllerList.add(TextEditingController(text: plainProductDetails)) ;
        } else{
          for (var lan in edtProduct.translations!) {
            if(lan.locale == languageList[i].code && lan.key == 'name'){
              _titleControllerList.add(TextEditingController(text: lan.value)) ;
            }
            if(lan.locale == languageList[i].code && lan.key == 'description'){
              String plainText = ProductHelper.htmlToPlainText(lan.value ?? '');
              _descriptionControllerList.add(TextEditingController(text: plainText));

              debugPrint('--------description---------${lan.value}');

            }
          }
        }
      }
      else{
        _titleControllerList.add(TextEditingController());
        _descriptionControllerList.add(TextEditingController());
      }
    }
    if(edtProduct != null){
      if(_titleControllerList.length < languageList.length) {
        int l1 = languageList.length-_titleControllerList.length;
        for(int i=0; i<l1; i++) {
          _titleControllerList.add(TextEditingController(text: editProduct!.name));
          debugPrint('--------name---------${editProduct!.name}');
        }
      }
      if(_descriptionControllerList.length < languageList.length) {
        int l0 = languageList.length-_descriptionControllerList.length;
        for(int i=0; i<l0; i++) {
          _descriptionControllerList.add(TextEditingController(text: editProduct!.details));
          debugPrint('--------description---------${editProduct!.details}');
        }
      }
    }else {
      if(_titleControllerList.length < languageList.length) {
        int l = languageList.length-_titleControllerList.length;
        for(int i=0; i<l; i++) {
          _titleControllerList.add(TextEditingController());
        }
      }
      if(_descriptionControllerList.length < languageList.length) {
        int l2 = languageList.length-_descriptionControllerList.length;
        for(int i=0; i<l2; i++) {
          _descriptionControllerList.add(TextEditingController());
        }
      }
    }
  }

  void resetDiscountTypeIndex() {
    _discountTypeIndex = 0;
  }

  String discountType= 'percent';

  void setDiscountTypeIndex(int index, bool notify) {
    _discountTypeIndex = index;
    if(_discountTypeIndex == 0){
      discountType = 'percent';
    }else{
      discountType = 'flat';
    }
    if(notify) {
      notifyListeners();
    }
  }

  void setTaxTypeIndex(int index, bool notify) {
    _taxTypeIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  void setImagePreviewType(String type, bool notify) {
    _imagePreviewSelectedType = type;
    if(notify) {
      notifyListeners();
    }
  }

  void toggleMultiply(BuildContext context) {
    _isMultiply = !_isMultiply;
    notifyListeners();
  }

  Future<void> getEditProduct(BuildContext context,int? id) async {
    _editProduct = null;
    _editProductFull = null;
    ApiResponse response = await shopServiceInterface.getEditProduct(id);
    if (response.response != null && response.response!.statusCode == 200) {
      final data = response.response!.data;
      if (data is Map<String, dynamic>) {
        _editProductFull = Product.fromJson(data);
      } else if (data is Map) {
        _editProductFull = Product.fromJson(Map<String, dynamic>.from(data));
      }

      _editProduct = EditProductModel.fromJson(response.response!.data);
      if(_editProduct?.seoInfo != null) {
        convertSeoInfoToMetaSeoInfo(_editProduct!.seoInfo!);
      }

      getTitleAndDescriptionList(Provider.of<SplashController>(Get.context!,listen: false).configModel!.languageList!, _editProduct);
      Provider.of<DigitalProductController>(Get.context!,listen: false).initDigitalProductVariation(_editProduct!);
      if (Get.context != null) {
        Provider.of<DynamicFieldController>(Get.context!, listen: false)
            .applyApiPayload(response.response!.data as Map<String, dynamic>?);
        await hydrateEditProductControllers(Get.context!);
      }
    } else {
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }

  Product? getEffectiveEditProduct(Product? fallback) {
    return _editProductFull ?? fallback;
  }

  Future<void> hydrateEditProductControllers(BuildContext context) async {
    final product = _editProductFull;
    if (product == null) return;

    final languageCode = Provider.of<LocalizationController>(context, listen: false).locale.countryCode == 'US'
        ? 'en'
        : Provider.of<LocalizationController>(context, listen: false).locale.countryCode!.toLowerCase();

    Provider.of<AddProductTaxController>(context, listen: false).setProductVatTax(product.taxVats);

    await Provider.of<CategoryController>(context, listen: false).getCategoryList(context, product, languageCode);

    await Provider.of<ProductController>(context, listen: false).getBrandList(context, languageCode);
    if (product.brandId != null) {
      Provider.of<ProductController>(context, listen: false).setBrandIndexFromId(product.brandId);
    }

    if (product.discountType != null) {
      setDiscountTypeIndex(product.discountType == 'percent' ? 0 : 1, false);
    }
    if (product.taxModel != null) {
      setTaxTypeIndex(product.taxModel == 'include' ? 0 : 1, false);
    }
  }

  void convertSeoInfoToMetaSeoInfo(SeoInfo seoInfo) {
    _metaSeoInfo = MetaSeoInfo(
      metaIndex: seoInfo.index,
      metaNoFollow: seoInfo.noFollow,
      metaNoImageIndex: seoInfo.noImageIndex,
      metaNoArchive: seoInfo.noArchive,
      metaNoSnippet: seoInfo.noSnippet,
      metaMaxSnippet: seoInfo.maxSnippet,
      metaMaxSnippetValue: seoInfo.maxSnippetValue,
      metaMaxVideoPreview: seoInfo.maxVideoPreview,
      metaMaxVideoPreviewValue: seoInfo.maxVideoPreviewValue,
      metaMaxImagePreview: seoInfo.maxImagePreview,
      metaMaxImagePreviewValue: seoInfo.maxImagePreviewValue,
      imageFullUrl: seoInfo.imageFullUrl
    );
  }

  void setUnitIndex(int index, bool notify) {
    _unitIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  int totalUploaded = 0;
  void initUpload(){
    totalUploaded = 0;
    notifyListeners();
  }

  Future<void> addProduct(BuildContext context, Product product, AddProductModel addProduct, String? thumbnail, String? metaImage, bool isAdd, List<String?> tags) async {
    final String? dynamicFieldError =
        Provider.of<DynamicFieldController>(context, listen: false).validateLocally();
    if (dynamicFieldError != null) {
      showQuikseeSnackBarWidget(dynamicFieldError, context, isToaster: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final addProductImageController = Provider.of<AddProductImageController>(context, listen: false);
      final bool isDigitalVariationEmpty =
          Provider.of<DigitalProductController>(context, listen: false).selectedDigitalVariation.isNotEmpty;

      DigitalVariationModel? digitalVariationModel;
      final List<AttributeModel>? attributeList =
          Provider.of<VariationController>(context, listen: false).attributeList;

      final Map<String, dynamic> variationFields =
          Provider.of<VariationController>(context, listen: false).processVariantData(context);

      Provider.of<VariationController>(context, listen: false).onClearColorVariations(addProduct);

      final List<Map<String, dynamic>>? productReturnImages =
          addProductImageController.productReturnImageList;

      final List<ColorImage> colorImageObjects = addProductImageController.colorImageObject;

      final String? digitalProductFileName =
          Provider.of<DigitalProductController>(context, listen: false).digitalProductFileName;

      if (_productTypeIndex == 1) {
        digitalVariationModel =
            Provider.of<DigitalProductController>(context, listen: false).getDigitalVariationModel();
      } else {
        digitalVariationModel = DigitalVariationModel();
      }

      final token = Provider.of<AuthController>(context, listen: false).getUserToken();

      setMetaSeoData(product);

      final ApiResponse response = await shopServiceInterface.addProduct(
        product,
        addProduct,
        variationFields,
        productReturnImages,
        thumbnail,
        metaImage,
        isAdd,
        attributeList?.isNotEmpty == true ? attributeList!.first.active : false,
        colorImageObjects,
        tags,
        digitalProductFileName,
        digitalVariationModel,
        isDigitalVariationEmpty,
        token,
      );

      final int? statusCode = response.response?.statusCode;
      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        await addProductImageController.onDeleteColorImages(product);

        _productCode.clear();

        final navContext = Get.context!;
        final productController = Provider.of<ProductController>(navContext, listen: false);
        final profileController = Provider.of<ProfileController>(navContext, listen: false);
        final localization = Provider.of<LocalizationController>(navContext, listen: false);
        final languageCode = localization.locale.countryCode == 'US'
            ? 'en'
            : (localization.locale.countryCode ?? 'en').toLowerCase();
        final sellerId = profileController.userId;
        final search = productController.sellerProductModel?.search ?? '';

        if (Navigator.of(navContext).canPop()) {
          Navigator.of(navContext).pop();
        } else {
          Navigator.of(navContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProductListMenuScreen(fromNotification: true)),
            (route) => false,
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = Get.context;
          if (ctx == null) return;

          showQuikseeSnackBarWidget(
            isAdd
                ? getTranslated('product_added_successfully', ctx)
                : getTranslated('product_updated_successfully', ctx),
            ctx,
            isError: false,
          );
          titleControllerList.clear();
          descriptionControllerList.clear();
          Provider.of<AddProductImageController>(ctx, listen: false).removeProductImage();
          emptyDigitalProductData();
          _metaSeoInfo = MetaSeoInfo();

          if (sellerId != null) {
            productController.getSellerProductList(
              sellerId.toString(),
              1,
              languageCode,
              search,
              filterSearchModel: productController.filterModel.copyWith(reload: true),
            );
          }
        });
      } else {
        Provider.of<AddProductImageController>(Get.context!, listen: false).emptyWithColorImage();
        ApiChecker.checkApi(response);
        showQuikseeSnackBarWidget(
          getTranslated('product_add_failed', Get.context!),
          Get.context!,
          sanckBarType: SnackBarType.error,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMetaSeoData(Product product) {
    metaSeoInfo?.metaMaxImagePreviewValue = _imagePreviewSelectedType;
    product.metaSeoInfo = metaSeoInfo;
  }

  void loadingFalse() {
    _isLoading = false;
    notifyListeners();
  }

  void setValueForUnit (String? setValue){
    if (kDebugMode) {
      debugPrint('------$setValue====$_unitValue');
    }
    _unitValue = setValue;
  }

  void setProductTypeIndex(int index, bool notify) {
    _productTypeIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  void setTotalVariantTotalQuantity(int total){
    _totalVariantQuantity = total;
  }

  Future<void> updateProductQuantity(BuildContext context, int? productId, int currentStock, List<Variation> variations) async {
    if(kDebugMode){
      debugPrint("variation======>${variations.length}/${variations.toList()}");
    }
    List<Variation> updatedVariations = [];
    for(int i=0; i<variations.length; i++){
      updatedVariations.add(Variation(type: variations[i].type,
          sku: variations[i].sku,
          price: variations[i].price,
          qty: int.parse( Provider.of<VariationController>(context, listen: false).variantTypeList[i].qtyController.text)
      ));
    }
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await shopServiceInterface.updateProductQuantity(productId, currentStock, updatedVariations);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      Navigator.pop(Get.context!);
      showQuikseeSnackBarWidget(getTranslated('quantity_updated_successfully', Get.context!), Get.context!, isError: false);
      Provider.of<ProductController>(Get.context!, listen: false).getStockOutProductList(1, 'en');
    } else {
      _isLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<void> updateRestockProductQuantity(BuildContext context, int? productId, int currentStock, List<Variation> variations,{int? index}) async {
    if(kDebugMode){
      debugPrint("variation======>${variations.length}/${variations.toList()}");
    }
    List<Variation> updatedVariations = [];
    for(int i=0; i<variations.length; i++){
      updatedVariations.add(Variation(type: variations[i].type,
          sku: variations[i].sku,
          price: variations[i].price,
          qty: int.parse(Provider.of<VariationController>(context, listen: false).variantTypeList[i].qtyController.text)
      ));
    }
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await shopServiceInterface.updateRestockProductQuantity(productId, currentStock, updatedVariations);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      Navigator.pop(Get.context!);
      showQuikseeSnackBarWidget(getTranslated('quantity_updated_successfully', Get.context!), Get.context!, isError: false);
      await Provider.of<RestockController>(Get.context!, listen: false).getRestockProductList(1);

    } else {
      _isLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  List<String> imagesWithoutColor = [];
  List<String> imagesWithColorForUpdate = [];
  ProductImagesModel? productImagesModel;

  void  setSelectedPageIndex (int index, {bool isUpdate = true}){
    _selectedPageIndex = index;
    if(isUpdate) {
      notifyListeners();
    }
  }

  List<String> processList(List<String> inputList) {
    return inputList.map((str) => str.toLowerCase().trim()).toList();
  }

  void updateState(){
    notifyListeners();
  }

  void emptyDigitalProductData() {
    Provider.of<DigitalProductController>(Get.context!, listen: false).emptyDigitalProductData();
  }

  Future<void> generateAndSetOtherData({String? title, String? description, String? langCode}) async {
    AiController aiController = Provider.of<AiController>(Get.context!, listen: false);

    await aiController.generateGeneralSetup(
      title: title ?? '',
      description: description ?? '',
      langCode: langCode ?? '',
    ).then((value) {
      GeneralSetupModel? generalSetupModel = aiController.generalSetupModel;

      if(generalSetupModel != null) {
        ProductController productController = Provider.of<ProductController>(Get.context!, listen: false);
        productController.setAiBrandIndex(generalSetupModel.data?.brandId ?? 0);
      }

      if(generalSetupModel != null) {
        CategoryController categoryController = Provider.of<CategoryController>(Get.context!, listen: false);
        categoryController.setAiCategoryIndex(generalSetupModel.data?.categoryId, generalSetupModel.data?.subCategoryId, generalSetupModel.data?.subSubCategoryId);
      }

      if(generalSetupModel != null && generalSetupModel.data?.unitName != null && generalSetupModel.data!.unitName!.isNotEmpty ) {
        _unitValue = generalSetupModel.data?.unitName;
      }

      if(generalSetupModel != null && generalSetupModel.data?.productType != null) {
        _productTypeIndex = generalSetupModel.data?.productType == 'physical' ? 0 : 1;
      }

      if(generalSetupModel != null && generalSetupModel.data?.productType != null && generalSetupModel.data?.productType == 'digital' && generalSetupModel.data?.deliveryType != null) {
        Provider.of<DigitalProductController>(Get.context!, listen: false).setDigitalProductTypeIndex(
          generalSetupModel.data?.deliveryType == 'ready_product' ? 1 : 0, true
        );
      }
      notifyListeners();
    });
  }

  void updateMetaSeoInfo(AiMetaSEOModel? aiMetaSeoModel) {
    if(aiMetaSeoModel != null) {
      _metaSeoInfo?.metaIndex = aiMetaSeoModel.data?.metaIndex == '0' ? '0' : '1';
      _metaSeoInfo?.metaNoFollow = aiMetaSeoModel.data?.metaNoFollow == 0 ? '0' : 'nofollow';
      _metaSeoInfo?.metaNoIndex = aiMetaSeoModel.data?.metaNoImageIndex == 0 ? '0' : '1';
      _metaSeoInfo?.metaNoArchive = aiMetaSeoModel.data?.metaNoArchive == 0 ? '0' : '1';
      _metaSeoInfo?.metaNoSnippet = aiMetaSeoModel.data?.metaNoSnippet == 0 ? '0' : '1';
      _metaSeoInfo?.metaMaxSnippet = aiMetaSeoModel.data?.metaMaxSnippet == 0 ? '0' : '1';
      _metaSeoInfo?.metaMaxVideoPreview = aiMetaSeoModel.data?.metaMaxVideoPreview == 0 ? '0' : '1';
      _metaSeoInfo?.metaMaxImagePreview = aiMetaSeoModel.data?.metaMaxImagePreview == 0 ? '0' : '1';

      _metaSeoInfo?.metaMaxSnippetValue = aiMetaSeoModel.data?.metaMaxSnippetValue.toString();
      _metaSeoInfo?.metaMaxVideoPreviewValue = aiMetaSeoModel.data?.metaMaxVideoPreviewValue.toString();
      _metaSeoInfo?.metaMaxImagePreviewValue = aiMetaSeoModel.data?.metaMaxImagePreviewValue.toString();
      notifyListeners();
    }
  }

  void setIsAttributeActive(bool isActive, {bool notify = false}) {
    _isAttributeActive = isActive;
    if(notify) {
      notifyListeners();
    }
  }

  bool validateGeneralInfo(BuildContext context, {
    required CategoryController categoryController,
    required AddProductImageController imageController,
    required Product? existingProduct,
    required String? youtubeLink,
  }) {
    bool isUpdate = existingProduct != null;

    if(titleControllerList.isNotEmpty && titleControllerList[0].text.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('please_input_all_title', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    if(descriptionControllerList.isNotEmpty && descriptionControllerList[0].text.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('please_input_all_des', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    if (categoryController.categoryIndex == 0 || categoryController.categoryIndex == -1) {
      showQuikseeSnackBarWidget(getTranslated('select_a_category', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    if ((unitValue == 'select_unit' || unitValue == null) && productTypeIndex == 0) {
      showQuikseeSnackBarWidget(getTranslated('select_a_unit', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    if (productCode.text.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('product_code_is_required', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    if (productCode.text.length < 6 || productCode.text == '000000') {
      showQuikseeSnackBarWidget(getTranslated('product_code_minimum_6_digit', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    final Product? editFull = _editProductFull ?? existingProduct;
    final bool hasExistingThumbnail = isUpdate && (
      (editFull?.thumbnailFullUrl?.path != null && editFull!.thumbnailFullUrl!.path!.isNotEmpty) ||
      (editFull?.thumbnail != null && editFull!.thumbnail!.isNotEmpty && editFull.thumbnail != 'null')
    );

    if (!isUpdate && imageController.selectedLogoFile == null) {
      showQuikseeSnackBarWidget(getTranslated('upload_thumbnail_image', context), context, sanckBarType: SnackBarType.warning);
      return false;
    } else if (isUpdate && imageController.selectedLogoFile == null && !hasExistingThumbnail) {
      showQuikseeSnackBarWidget(getTranslated('upload_thumbnail_image', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    if(youtubeLink != null && youtubeLink.trim().isNotEmpty && !youtubeLink.contains('youtube.com/embed/')) {
      showQuikseeSnackBarWidget(getTranslated('provide_embedded_link', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    return true;
  }

  bool _isProductWiseTaxRequired(ConfigModel? configModel, AddProductTaxController taxController) {
    if (taxController.hasTaxConfigLoaded) {
      return taxController.showTaxSection;
    }
    return configModel?.systemTaxType == 'product_wise' && configModel?.systemTaxIncludeStatus == 0;
  }

  bool validateVariations(BuildContext context, {
    required DigitalProductController digitalProductController,
    required VariationController variationController,
    required AddProductTaxController taxController,
    required AddProductImageController imageController,
    required ConfigModel? configModel,

    required String unitPrice,
    required String currentStock,
    required String orderQuantity,
    required String shippingCost,
    required bool isUpdate,
  }) {

    bool digitalProductVariationEmpty = false;
    bool isTitleEmpty = false;
    bool isFileEmpty = false;
    bool isPriceEmpty = false;
    bool isSKUEmpty = false;

    for (int index = 0; index < digitalProductController.selectedDigitalVariation.length; index++) {
      if(digitalProductController.digitalVariationExtantion[index].isEmpty) {
        digitalProductVariationEmpty = true;
        break;
      }
    }

    for (int index = 0; index < digitalProductController.selectedDigitalVariation.length; index++) {
      for(int i =0; i< digitalProductController.variationFileList[index].length; i++) {
        if(digitalProductController.variationFileList[index][i].fileName == null) {
          isFileEmpty = true;
          break;
        }
        if(digitalProductController.variationFileList[index][i].priceController?.text.trim() == ''){
          isPriceEmpty = true;
          break;
        }
        if(digitalProductController.variationFileList[index][i].skuController?.text.trim() == ''){
          isSKUEmpty = true;
          break;
        }
        if(digitalProductController.variationFileList[index][i].fileName == null){
          isTitleEmpty = true;
          break;
        }
      }
    }

    bool haveBlankVariant = false;
    bool blankVariantPrice = false;
    bool blankVariantQuantity = false;

    if (variationController.attributeList != null) {
      for (AttributeModel attr in variationController.attributeList!) {
        if (attr.active && attr.variants.isEmpty) {
          haveBlankVariant = true;
          break;
        }
      }
    }

    for (VariantTypeModel variantType in variationController.variantTypeList) {
      if (variantType.controller.text.isEmpty) {
        blankVariantPrice = true;
        break;
      }
      if (variantType.qtyController.text.isEmpty) {
        blankVariantQuantity = true;
        break;
      }
    }

    bool isColorImageEmpty = false;
    if(imageController.imagesWithColor.isNotEmpty) {
      for (int i=0; i<imageController.imagesWithColor.length; i++) {
        final colorImg = imageController.imagesWithColor[i];
        final bool hasLocal = colorImg.image != null;
        final bool hasRemote = (colorImg.colorImage?.imageName?.path?.isNotEmpty ?? false) ||
            (colorImg.imageString?.isNotEmpty ?? false);
        if (!isUpdate && !hasLocal && !isColorImageEmpty) {
          isColorImageEmpty = true;
        } else if (isUpdate && !hasLocal && !hasRemote && !isColorImageEmpty){
          isColorImageEmpty = true;
        }
      }
    }

    if (unitPrice.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_unit_price', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (currentStock.isEmpty && productTypeIndex == 0) {
      showQuikseeSnackBarWidget(getTranslated('enter_total_quantity', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (orderQuantity.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_minimum_order_quantity', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (haveBlankVariant) {
      showQuikseeSnackBarWidget(getTranslated('add_at_least_one_variant_for_every_attribute', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (blankVariantPrice) {
      showQuikseeSnackBarWidget(getTranslated('enter_price_for_every_variant', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (blankVariantQuantity) {
      showQuikseeSnackBarWidget(getTranslated('enter_quantity_for_every_variant', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (productTypeIndex == 0 && shippingCost.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_shipping_cost', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if((isUpdate || !isUpdate) && productTypeIndex == 1 && digitalProductController.digitalProductTypeIndex == 1 && isFileEmpty) {
      showQuikseeSnackBarWidget(getTranslated('digital_product_file_empty', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if(productTypeIndex == 1 && isPriceEmpty) {
      showQuikseeSnackBarWidget(getTranslated('digital_product_price_empty', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if(productTypeIndex == 1 && isSKUEmpty) {
      showQuikseeSnackBarWidget(getTranslated('digital_product_sku_empty', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if(productTypeIndex == 1 && digitalProductVariationEmpty) {
      showQuikseeSnackBarWidget(getTranslated('digital_product_variation_empty', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if (!isUpdate && (productTypeIndex == 1 && digitalProductController.digitalProductTypeIndex == 1 &&
        digitalProductController.selectedFileForImport == null) && digitalProductController.selectedDigitalVariation.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('please_choose_digital_product', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if(_isProductWiseTaxRequired(configModel, taxController) && taxController.selectedTaxList.isEmpty) {

      if (isUpdate && (_editProductFull?.taxVats?.isNotEmpty ?? false)) {
        taxController.setProductVatTax(_editProductFull!.taxVats);
      }
      if (taxController.selectedTaxList.isEmpty &&
          !(isUpdate && (_editProductFull?.taxVats?.isNotEmpty ?? false))) {
        showQuikseeSnackBarWidget(getTranslated('please_add_your_product_tax', context), context, sanckBarType: SnackBarType.warning);
        return false;
      }
    }
    else if(_isProductWiseTaxRequired(configModel, taxController) && taxTypeIndex == -1) {
      showQuikseeSnackBarWidget(getTranslated('select_tax_model', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }
    else if(!isUpdate && variationController.attributeList![0].active && variationController.attributeList![0].variants.isNotEmpty && isColorImageEmpty) {
      showQuikseeSnackBarWidget(getTranslated('upload_product_color_image', context), context, sanckBarType: SnackBarType.warning);
      return false;
    }

    return true;
  }

  void resetMetaSeoInfo({bool isUpdate = false}) {
    _metaSeoInfo = MetaSeoInfo();
    if(isUpdate) {
      notifyListeners();
    }
  }

}
