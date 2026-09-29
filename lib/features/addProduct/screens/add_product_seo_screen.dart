import 'dart:io';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_image_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_tax_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/digital_product_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/variation_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/image_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/widgets/add_product_section_widget.dart';
import 'package:quiksee_vendor_app/features/addProduct/widgets/meta_seo_widget.dart';
import 'package:quiksee_vendor_app/features/ai/controllers/ai_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/category_controller.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:textfield_tags/textfield_tags.dart';

class AddProductSeoScreen extends StatefulWidget {
  final ValueChanged<bool>? isSelected;
  final Product? product;
  final String? unitPrice;
  final String? discount;
  final String? currentStock;
  final String? minimumOrderQuantity;
  final List<int?>? tax;
  final String? shippingCost;
  final String? categoryId;
  final String? subCategoryId;
  final String? subSubCategoryId;
  final String? brandyId;
  final String? unit;
  final String? title;
  final String? description;
  final AddProductModel? addProduct;
  final Function(int) onTabChanged;

  const AddProductSeoScreen({
    super.key, this.isSelected, required this.product, required this.addProduct,
    this.unitPrice, this.tax, this.discount, this.currentStock, this.shippingCost, this.categoryId, this.subCategoryId,
    this.subSubCategoryId, this.brandyId, this.unit, this.minimumOrderQuantity, this.title, this.description, required this.onTabChanged
  });

  @override
  AddProductSeoScreenState createState() => AddProductSeoScreenState();
}

class AddProductSeoScreenState extends State<AddProductSeoScreen>  with AutomaticKeepAliveClientMixin {
  bool isSelected = false;
  final FocusNode _seoTitleNode = FocusNode();
  final FocusNode _seoDescriptionNode = FocusNode();
  final TextEditingController _seoTitleController = TextEditingController();
  final TextEditingController _seoDescriptionController = TextEditingController();
  final TextEditingController _youtubeLinkController = TextEditingController();
  AutoCompleteTextField? searchTextField;
  late double _distanceToField;
  TextfieldTagsController? _controller;
  GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
  SimpleAutoCompleteTextField? textField;
  bool showWhichErrorText = false;
  late bool _update;
  Product? _product;
  AddProductModel? _addProduct;
  String? thumbnailImage ='', metaImage ='';
  int counter = 0, total = 0;
  int addColor = 0;
  List<String> tagList = [];
  final categoryController = Provider.of<CategoryController>(Get.context!,listen: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose();
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _update = widget.product != null;
    _addProduct = widget.addProduct;
    if(_update) {
      if(_product!.tags != null) {
        for(int i = 0; i< _product!.tags!.length; i++){
          tagList.add(_product!.tags![i].tag!);
        }
      }
      _seoTitleController.text = _product!.metaSeoInfo != null ? _product!.metaSeoInfo?.metaTitle ?? '' : _product!.metaTitle ?? '' ;
      _seoDescriptionController.text = _product!.metaSeoInfo != null ? _product!.metaSeoInfo?.metaDescription ?? '' : _product!.metaDescription ?? '';
      thumbnailImage = _product!.thumbnail;
      metaImage = _product!.metaImage;
      _youtubeLinkController.text = _product?.videoUrl ?? '';

      if(_product?.imagesFullUrl != null) {
        List<Map<String, dynamic>>? productImages = [];
        for(int i = 0; i< _product!.imagesFullUrl!.length; i++){
          productImages.add({
            "image_name" : _product?.imagesFullUrl?[i].key ?? '',
            "storage" : null,
          });
        }

      }
    }else {
      AddProductController addProductController = Provider.of<AddProductController>(context,listen: false);
      _seoTitleController.text = addProductController.titleControllerList[0].text;
      _product = Product();
      _addProduct = AddProductModel();
      Provider.of<AddProductController>(Get.context!,listen: false).resetMetaSeoInfo();
    }
    _controller = TextfieldTagsController();

    if((Provider.of<AiController>(context, listen: false).generalSetupModel?.data?.searchTags ?? []).isNotEmpty) {
      for(int i = 0; i< (Provider.of<AiController>(context, listen: false).generalSetupModel?.data?.searchTags ?? []).length; i++) {
        if(!tagList.contains(Provider.of<AiController>(context, listen: false).generalSetupModel?.data?.searchTags ?? '')) {
          tagList.add(Provider.of<AiController>(context, listen: false).generalSetupModel?.data?.searchTags?[i] ?? '');
        }
      }
    }

    _loadData();
  }

  Future<void> _loadData() async {
    if(Provider.of<AiController>(Get.context!,listen: false).requestTypeImage) {
      await Provider.of<AiController>(Get.context!,listen: false).generateMetaSeoSetup(
        title: widget.title ?? '',
        description: widget.description ?? '',
        seoTitleController: _seoTitleController,
        seoDescriptionController: _seoDescriptionController,
        formInit: true
      );
    }
    Provider.of<AiController>(Get.context!,listen: false).setRequestType(false, willUpdate: false);
  }

  void route(bool isRoute, String name, String type, String? colorCode) {
    if (!isRoute) {
      return;
    }
    if (type == 'meta') {
      metaImage = name;
    } else if (type == 'thumbnail') {
      thumbnailImage = name;
    }

    final imageController = Provider.of<AddProductImageController>(Get.context!, listen: false);
    if (imageController.imagesWithColor.isNotEmpty && colorCode != null) {
      for (int index = 0; index < imageController.imagesWithColor.length; index++) {
        final String retColor = imageController.imagesWithColor[index].color!;
        String? normalizedColor;
        if (retColor.contains('#')) {
          normalizedColor = retColor.replaceAll('#', '');
        }
        if (normalizedColor == colorCode) {
          imageController.setStringImage(index, name, colorCode);
          break;
        }
      }
    }
  }

  Future<bool> _uploadAllPendingImages(
    BuildContext context,
    AddProductImageController imageController,
  ) async {
    if (widget.product != null) {
      for (final ImageModel value in imageController.imagesWithColor) {
        if (value.image?.path == null && value.colorImage?.imageName?.path == null) {
          showQuikseeSnackBarWidget('${getTranslated('please_add_color_image', context)}', context);
          return false;
        }
      }

      if (context.mounted) {
        await imageController.onUploadColorImages(
          context: context,
          isUpdate: _update,
          productId: _product?.id,
          callBack: route,
        );
      }
    }

    final uploads = <PendingProductImageUpload>[];

    if (imageController.selectedLogoFile != null) {
      uploads.add(PendingProductImageUpload(imageController.thumbnailImageModel, update: _update));
    }
    if (imageController.selectedMetaImageFile != null) {
      uploads.add(PendingProductImageUpload(imageController.metaImageModel, update: _update));
    }

    if (widget.product == null) {
      for (int i = 0; i < imageController.imagesWithColor.length; i++) {
        if (imageController.imagesWithColor[i].image != null) {
          uploads.add(PendingProductImageUpload(imageController.imagesWithColor[i]));
        }
      }
    }

    for (int i = 0; i < imageController.withoutColor.length; i++) {
      if (imageController.withoutColor[i].image != null) {
        uploads.add(PendingProductImageUpload(
          imageController.withoutColor[i],
          index: i,
          update: _update,
        ));
      }
    }

    if (uploads.isEmpty) {
      return true;
    }

    final uploaded = await imageController.uploadProductImagesBatch(context, uploads, route);
    if (!uploaded) {
      return false;
    }

    if (widget.product == null &&
        imageController.selectedLogoFile != null &&
        (thumbnailImage == null || thumbnailImage!.isEmpty)) {
      showQuikseeSnackBarWidget(getTranslated('image_upload_failed', context), context);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async{
        Provider.of<AddProductController>(context,listen: false).setSelectedPageIndex(1, isUpdate: true);
      },

      child: Scaffold(

        body: SafeArea(child: Consumer<VariationController>(
            builder: (context, variationController, child){
            return Consumer<AddProductController>(
              builder: (context, resProvider, child){
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: (variationController.attributeList != null &&
                          variationController.attributeList!.isNotEmpty &&
                          categoryController.categoryList != null &&
                          Provider.of<SplashController>(context,listen: false).colorList!= null) ?
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Column(children: [
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                AddProductSectionWidget(
                                  childrenPadding:Dimensions.paddingSizeMedium,
                                  title: getTranslated('tags', context)!,
                                  childrens: [
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    TextFieldTags(
                                      textfieldTagsController: _controller,
                                      initialTags:(tagList.isNotEmpty)  ?  tagList : const [],
                                      textSeparators: const [' ', ','],
                                      letterCase: LetterCase.normal,
                                      validator: (String? tag) {
                                        if (tag == 'php') {
                                          return 'No, please just no';
                                        } else if (_controller!.getTags!.contains(tag)) {
                                          return 'you already entered that';
                                        }
                                        return null;
                                      },

                                      inputfieldBuilder: (context, tec, fn, error, onChanged, onSubmitted) {
                                        return (context, sc, tags, onTagDelete) {
                                          tagList = tags;
                                          return TextField(
                                            controller: tec,
                                            focusNode: fn,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).primaryColor,
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).hintColor,
                                                  width: 1.0,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).primaryColor,
                                                  width: 1.0,
                                                ),
                                              ),
                                              helperText: '',
                                              helperStyle: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                              ),
                                              hintText: _controller!.hasTags ? '' : "Enter tag...",
                                              hintStyle: TextStyle(color: Theme.of(context).hintColor),
                                              errorText: error,
                                              prefixIconConstraints:
                                              BoxConstraints(maxWidth: _distanceToField * 0.74),
                                              prefixIcon: tags.isNotEmpty
                                                  ? SingleChildScrollView(
                                                controller: sc,
                                                scrollDirection: Axis.horizontal,
                                                child: Row(children: tags.map((String? tag) {
                                                  return Container(decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                                      color: Theme.of(context).primaryColor),
                                                    margin: const EdgeInsets.symmetric( horizontal: 5.0),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                                    child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                      Text('$tag', style: const TextStyle(color: Colors.white)),
                                                      const SizedBox(width: 4.0),

                                                      InkWell(
                                                        splashColor: Colors.transparent,
                                                        child: const Icon(Icons.cancel, size: 14.0,
                                                            color: Color.fromARGB(255, 233, 233, 233)),
                                                        onTap: () {
                                                          onTagDelete(tag!);},
                                                      )
                                                    ],
                                                    ),
                                                  );
                                                }).toList()),
                                              )
                                                  : null,
                                            ),
                                            onChanged: onChanged,
                                            onSubmitted: onSubmitted,
                                          );
                                        };
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.paddingSizeDefault),

                                AddProductSectionWidget(
                                  childrenPadding:Dimensions.paddingSizeMedium,
                                  title: getTranslated('product_seo', context)!,
                                  subTitle: getTranslated('add_meta_titles_descriptions_and_images_for_products', context)!,
                                  aiWidget: Consumer<AiController> (
                                    builder: (context, aiController, child) {
                                      return InkWell(
                                        onTap: () {
                                          if(widget.title == null) {
                                            showQuikseeSnackBarWidget('${getTranslated('product_name_required', context)}', context);
                                          } else if (widget.description == null) {
                                            showQuikseeSnackBarWidget('${getTranslated('product_description_required', context)}', context);
                                          } else{
                                            aiController.generateMetaSeoSetup(
                                                title: widget.title ?? '',
                                                description: widget.description ?? '',
                                                seoTitleController: _seoTitleController,
                                                seoDescriptionController: _seoDescriptionController
                                            );
                                          }
                                        },
                                        child: !aiController.metaSeoLoading ? Icon(Icons.auto_awesome, color: Colors.blue) : Shimmer.fromColors(
                                          baseColor: Theme.of(context).primaryColor,
                                          highlightColor: Colors.grey[100]!,
                                          child: Row(children: [
                                            Icon(Icons.auto_awesome, color: Colors.blue),
                                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                            Text(getTranslated('generating', context) ?? '', style: robotoBold.copyWith(color: Colors.blue)),
                                          ]),
                                        ),
                                      );
                                    }
                                  ),
                                  childrens: [
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    QuikseeTextFieldWidget(
                                      formProduct: true,
                                      border: true,
                                      textInputType: TextInputType.name,
                                      focusNode: _seoTitleNode,
                                      controller: _seoTitleController,
                                      nextNode: _seoDescriptionNode,
                                      textInputAction: TextInputAction.next,
                                      hintText: getTranslated('meta_title', context),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeLarge),

                                    QuikseeTextFieldWidget(
                                      formProduct: true,
                                      isDescription:true,
                                      border: true,
                                      controller: _seoDescriptionController,
                                      focusNode: _seoDescriptionNode,
                                      textInputAction: TextInputAction.next,
                                      textInputType: TextInputType.multiline,
                                      maxLine: 3,
                                      hintText: getTranslated('meta_description_hint', context),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeLarge),

                                    Text(getTranslated('meta_image', context)!,
                                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color:  Theme.of(context).textTheme.bodyLarge!.color)),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),

                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style.copyWith(
                                          color: Theme.of(context).hintColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                        children: <InlineSpan>[
                                          TextSpan(text: getTranslated('jpg_png_less_then_1_mb', context) ?? ''),
                                          TextSpan(
                                            text: getTranslated('ratio_1_1', context) ?? '',
                                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),

                                    Consumer<AddProductImageController>(
                                      builder: (context, addProductImageController, child){
                                        return Align(alignment: Alignment.topLeft, child: Stack(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                              child: addProductImageController.selectedMetaImageFile != null ? Image.file(
                                                File(addProductImageController.selectedMetaImageFile!.path), width: 140, height: 140, fit: BoxFit.cover,
                                              ) : widget.product != null ? FadeInImage.assetNetwork(
                                                placeholder: Images.placeholderImage,
                                                image: _product!.metaSeoInfo != null ? _product!.metaSeoInfo?.imageFullUrl?.path ?? '' : _product!.metaImageFullUrl?.path ?? '',
                                                height: 140, width: 140, fit: BoxFit.cover,
                                                imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholderImage, height: 140,
                                                    width: 140, fit: BoxFit.cover, color: Theme.of(context).highlightColor),
                                              ) : Image.asset(Images.placeholderImage, height: 140,
                                                width: 140, fit: BoxFit.cover, color: Theme.of(context).highlightColor,),
                                            ),
                                          ),

                                          Positioned(bottom: 0, right: 0, top: 0, left: 0,
                                            child: Consumer<AddProductImageController>(
                                              builder: (context, addProductImageController, child){
                                                return InkWell(
                                                  splashColor: Colors.transparent,
                                                  onTap: () => addProductImageController.pickImage(false,true, false, null),
                                                  child: DottedBorder(
                                                    options: RoundedRectDottedBorderOptions (
                                                      dashPattern: const [4,5],
                                                      color: Theme.of(context).hintColor,
                                                      radius: const Radius.circular(Dimensions.paddingEye),
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: addProductImageController.selectedMetaImageFile != null ? Colors.black.withValues(alpha: 0.5) : null,
                                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                                      ),
                                                      child: (addProductImageController.selectedMetaImageFile == null && (_product!.metaSeoInfo?.imageFullUrl?.path == null || _product!.metaSeoInfo?.imageFullUrl?.path == '')) ?
                                                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                        QuikseeAssetImageWidget(Images.addImageIcon, height: 30, width: 30, color: Theme.of(context).hintColor),
                                                        SizedBox(height: Dimensions.paddingSizeDefault),

                                                        Text(getTranslated('click_to_add', context)!, style: robotoRegular.copyWith(color: Theme.of(context).hintColor.withValues(alpha: .7),),)
                                                      ],) : const SizedBox.shrink(),
                                                    ),
                                                  ),
                                                );
                                              }
                                            ),
                                          ),

                                          if (addProductImageController.selectedLogoFile  != null || (widget.product?.thumbnailFullUrl?.path?.isNotEmpty ?? false))
                                            Positioned(right: 10, top: 10,
                                              child: SizedBox(width: 25, height: 25,
                                                child: InkWell(
                                                  onTap: () => addProductImageController.pickImage(false,true, false, null),
                                                  child: const Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      QuikseeAssetImageWidget(Images.editImageIcon, height: 25, width: 25),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ),

                                        ]));
                                      }
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.paddingSizeDefault),

                                Consumer<AiController> (
                                  builder: (context, aiController, child) {
                                    return AddProductSectionWidget(
                                      isAiGenerating: aiController.metaSeoLoading,
                                      childrenPadding: Dimensions.paddingSizeMedium,
                                      title: getTranslated('product_seo_settings', context) ?? ' ',
                                      subTitle: getTranslated('setup_how_to_indexing_snippet_preview', context) ?? ' ',
                                      aiWidget: Consumer<AiController> (
                                          builder: (context, aiController, child) {
                                            return InkWell(
                                              onTap: () {
                                                if(widget.title == null) {
                                                  showQuikseeSnackBarWidget('${getTranslated('product_name_required', context)}', context);
                                                } else if (widget.description == null) {
                                                  showQuikseeSnackBarWidget('${getTranslated('product_description_required', context)}', context);
                                                } else{
                                                  aiController.generateMetaSeoSetup(
                                                      title: widget.title ?? '',
                                                      description: widget.description ?? '',
                                                      seoTitleController: _seoTitleController,
                                                      seoDescriptionController: _seoDescriptionController
                                                  );
                                                }
                                              },
                                              child: !aiController.metaSeoLoading ? Icon(Icons.auto_awesome, color: Colors.blue) : Shimmer.fromColors(
                                                baseColor: Theme.of(context).primaryColor,
                                                highlightColor: Colors.grey[100]!,
                                                child: Row(children: [
                                                  Icon(Icons.auto_awesome, color: Colors.blue),
                                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                                  Text(getTranslated('generating', context) ?? '', style: robotoBold.copyWith(color: Colors.blue)),
                                                ]),
                                              ),
                                            );
                                          }
                                      ),
                                      childrens: [
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        const MetaSeoWidget(),

                                        const SizedBox(height: Dimensions.paddingSizeSmall),
                                      ],
                                    );
                                  }
                                ),
                              ],),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          ]) : const Padding(
                          padding: EdgeInsets.only(top: 300.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),

                    Consumer<AddProductController>(
                      builder: (context, resProvider, _) {
                        return Consumer<AiController>(
                          builder: (context, aiController, _) {
                            return Consumer<AddProductImageController>(
                              builder: (context, addProductImageController, _) {
                              return Container(height: 80,
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [BoxShadow(color: Colors.grey[Provider.of<ThemeController>(context).darkTheme ? 800 : 200]!,
                                      spreadRadius: 0.5, blurRadius: 0.3)],
                                ),
                                child: aiController.addProductMetaScreenLoading ?
                                Container(width: MediaQuery.of(context).size.width, height: 40,
                                  margin: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          getTranslated('ai_is_generating_product_details', context) ?? '',
                                          style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
                                          maxLines: 2,
                                        )
                                      ),

                                      SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                      Shimmer.fromColors(
                                        baseColor: Theme.of(context).primaryColor,
                                        highlightColor: Colors.grey[100]!,
                                        child: Row(children: [
                                          Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                          Text(getTranslated('generating', context) ?? '', style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
                                        ]),
                                      ),
                                    ],
                                  )
                                ) :
                                !resProvider.isLoading && !addProductImageController.isLoading ?
                                Row(
                                  children: [
                                    Expanded(child: InkWell(
                                      splashColor: Colors.transparent,
                                      onTap: (){
                                        widget.onTabChanged(1);
                                        resProvider.setSelectedPageIndex(1, isUpdate: true);
                                      },
                                      child: QuikseeButtonWidget(
                                        isColor: true,
                                        btnTxt: '${getTranslated('go_back', context)}',
                                        backgroundColor: Theme.of(context).hintColor.withValues(alpha: .6),
                                        buttonHeight: 55,
                                      ),
                                    )),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),

                                    Expanded(
                                      child: QuikseeButtonWidget(
                                        btnTxt: _update ? getTranslated('update',context) : getTranslated('submit', context), buttonHeight: 55,
                                        onTap: () async {
                                          final digitalProductController = Provider.of<DigitalProductController>(Get.context!,listen: false);
                                          final categoryController = Provider.of<CategoryController>(Get.context!,listen: false);

                                          resProvider.initUpload();
                                          if (!_update) {
                                            addProductImageController.productReturnImageList = [];
                                            addProductImageController.colorImageObject = [];
                                          }
                                          String seoDescription = _seoDescriptionController.text.trim();
                                          String seoTitle = _seoTitleController.text.trim();
                                          String? unit = widget.unit;
                                          String? brandId = widget.brandyId;
                                          String metaTitle =_seoTitleController.text.trim();
                                          String metaDescription =_seoDescriptionController.text.trim();
                                          String videoUrl = _youtubeLinkController.text.trim();
                                          String multiPlyWithQuantity = resProvider.isMultiply?'1':'0';
                                          int multi = int.parse(multiPlyWithQuantity);
                                          String productCode = resProvider.productCode.text;
                                          bool isColorImageEmpty = false;

                                          List<String> titleList = [];
                                          List<String> descriptionList = [];
                                          for(TextEditingController textEditingController in resProvider.titleControllerList) {
                                            titleList.add(textEditingController.text.trim());
                                          }
                                          for (var description in resProvider.descriptionControllerList) {
                                            descriptionList.add(description.text.trim());}

                                          if(addProductImageController.imagesWithColor.isNotEmpty) {
                                            for (int i=0; i<addProductImageController.imagesWithColor.length; i++) {
                                              final colorImg = addProductImageController.imagesWithColor[i];
                                              final bool hasLocal = colorImg.image != null;
                                              final bool hasRemote = (colorImg.colorImage?.imageName?.path?.isNotEmpty ?? false) ||
                                                  (colorImg.imageString?.isNotEmpty ?? false);
                                              if (!_update && !hasLocal && !isColorImageEmpty) {
                                                isColorImageEmpty = true;
                                              } else if (_update && !hasLocal && !hasRemote && !isColorImageEmpty){
                                                isColorImageEmpty = true;
                                              }
                                            }
                                          }

                                          if (isColorImageEmpty) {
                                            showQuikseeSnackBarWidget('${getTranslated('please_add_color_image', context)}', context);
                                            widget.onTabChanged(1);
                                            return;
                                          }

                                          CategoryController categoryControllerr =  Provider.of<CategoryController>(context, listen: false);
                                          final taxController = Provider.of<AddProductTaxController>(context, listen: false);
                                          final imageController = Provider.of<AddProductImageController>(context, listen: false);
                                          final configModel = Provider.of<SplashController>(context, listen: false).configModel;

                                          bool? isValidateProduct;
                                          bool? isValidVariation;

                                          isValidateProduct = resProvider.validateGeneralInfo(
                                            context,
                                            categoryController: categoryControllerr,
                                            imageController: addProductImageController,
                                            existingProduct: resProvider.getEffectiveEditProduct(widget.product),
                                            youtubeLink: resProvider.youtubeLinkController.text.trim(),
                                          );

                                          if(isValidateProduct) {
                                            isValidVariation = resProvider.validateVariations(
                                              context,
                                              digitalProductController: digitalProductController,
                                              variationController: variationController,
                                              taxController: taxController,
                                              imageController: imageController,
                                              configModel: configModel,

                                              unitPrice: resProvider.unitPriceController.text.trim(),
                                              currentStock: variationController.totalQuantityController.text.trim(),
                                              orderQuantity: resProvider.minimumOrderQuantityController.text.trim(),
                                              shippingCost: resProvider.shippingCostController.text.trim(),
                                              isUpdate: widget.product != null,
                                            );
                                          }

                                          if(!isValidateProduct) {
                                            widget.onTabChanged(0);
                                          } else if (!(isValidVariation ?? false)) {
                                            widget.onTabChanged(1);
                                          } else if(!_update && (variationController.attributeList?.isNotEmpty != true || !variationController.attributeList![0].active) && !imageController.hasExistingOrNewProductImages) {
                                            showQuikseeSnackBarWidget(getTranslated('upload_product_image', context), context, sanckBarType: SnackBarType.warning);
                                            widget.onTabChanged(0);
                                          } else if(_update && (variationController.attributeList?.isNotEmpty != true || !variationController.attributeList![0].active) && !imageController.hasExistingOrNewProductImages) {
                                            showQuikseeSnackBarWidget(getTranslated('upload_product_image', context), context, sanckBarType: SnackBarType.warning);
                                            widget.onTabChanged(0);
                                          } else {
                                            if(Provider.of<ShopController>(context, listen: false).shopModel?.setupGuideApp != null && Provider.of<ShopController>(context, listen: false).shopModel?.setupGuideApp?['add_new_product'] != 1) {
                                              Provider.of<ShopController>(context, listen: false).updateTutorialFlow('add_new_product');
                                              Provider.of<ShopController>(context, listen: false).updateSetupGuideApp('add_new_product', 1);
                                            }
                                            _addProduct = AddProductModel();
                                            _addProduct!.titleList = titleList;
                                            _addProduct!.descriptionList = descriptionList;
                                            _addProduct!.videoUrl = videoUrl;
                                            _product!.taxIds = (widget.tax ?? []).where((id) => id != null && id > 0).toList();
                                            if ((_product!.taxIds == null || _product!.taxIds!.isEmpty) && _update) {
                                              final effective = resProvider.getEffectiveEditProduct(widget.product);
                                              final existingTaxIds = (effective?.taxIds ?? widget.product?.taxIds ?? [])
                                                  .where((id) => id != null && id > 0)
                                                  .toList();
                                              _product!.taxIds = existingTaxIds.isNotEmpty
                                                  ? existingTaxIds
                                                  : (effective?.taxVats ?? widget.product?.taxVats)
                                                      ?.map((tax) => tax.taxId)
                                                      .where((id) => id != null && id > 0)
                                                      .toList();
                                            }
                                            _product!.taxModel = resProvider.taxTypeIndex == 0 ? 'include' : 'exclude';
                                            _product!.unitPrice = PriceConverter.systemCurrencyToDefaultCurrency(double.tryParse(widget.unitPrice ?? '') ?? widget.product?.unitPrice ?? 0, context);
                                            _product!.discount = resProvider.discountTypeIndex == 0 ?
                                            (double.tryParse(widget.discount ?? '') ?? widget.product?.discount ?? 0) : PriceConverter.systemCurrencyToDefaultCurrency(double.tryParse(widget.discount ?? '') ?? widget.product?.discount ?? 0, context);
                                            _product!.productType = resProvider.productTypeIndex == 0 ? 'physical' : 'digital';
                                            _product!.unit = unit;
                                            _product!.code = productCode;
                                            _product!.shippingCost = PriceConverter.systemCurrencyToDefaultCurrency(double.tryParse(widget.shippingCost ?? '') ?? widget.product?.shippingCost ?? 0, context);
                                            _product!.multiplyWithQuantity = multi;
                                            final parsedBrandId = int.tryParse(brandId ?? '');
                                            _product!.brandId = Provider.of<SplashController>(Get.context!, listen: false).configModel!.brandSetting == "1" && resProvider.productTypeIndex != 1 && parsedBrandId != null && parsedBrandId > 0
                                                ? parsedBrandId
                                                : (_update ? widget.product?.brandId : null);
                                            _product!.metaTitle = metaTitle;
                                            _product!.metaDescription = metaDescription;
                                            _product!.currentStock = int.tryParse(widget.currentStock ?? '') ?? widget.product?.currentStock ?? 0;
                                            _product!.minimumOrderQty = int.tryParse(widget.minimumOrderQuantity ?? '') ?? widget.product?.minimumOrderQty ?? 1;
                                            final prepText = resProvider.preparationTimeController.text.trim();
                                            _product!.preparationTime = prepText.isEmpty ? null : int.tryParse(prepText);
                                            _product!.metaTitle = seoTitle;
                                            _product!.metaDescription = seoDescription;
                                            _product!.discountType = resProvider.discountType;
                                            _product!.digitalProductType = Provider.of<DigitalProductController>(Get.context!,listen: false).digitalProductTypeIndex == 0 ? 'ready_after_sell' : 'ready_product';
                                            _product!.digitalFileReady = digitalProductController.digitalProductFileName;
                                            _product!.categoryIds = [];
                                            final parsedCategoryId = int.tryParse(widget.categoryId ?? '');
                                            if (parsedCategoryId != null && parsedCategoryId > 0) {
                                              _product!.categoryIds!.add(CategoryIds(id: widget.categoryId));
                                              if (categoryController.subCategoryIndex != 0) {
                                                _product!.categoryIds!.add(CategoryIds(id: widget.subCategoryId));
                                              }
                                              if (categoryController.subSubCategoryIndex != 0) {
                                                _product!.categoryIds!.add(CategoryIds(id: widget.subSubCategoryId));
                                              }
                                            } else if (_update && widget.product?.categoryIds != null && widget.product!.categoryIds!.isNotEmpty) {
                                              _product!.categoryIds = List<CategoryIds>.from(widget.product!.categoryIds!);
                                            }

                                            _addProduct!.colorCodeList =[];
                                            _addProduct!.colorCodeList!.addAll(variationController.colorCodeList);

                                            _addProduct!.languageList = [];
                                            if(Provider.of<SplashController>(context, listen:false).configModel!.languageList!=null &&
                                                Provider.of<SplashController>(context, listen:false).configModel!.languageList!.isNotEmpty){
                                              for(int i=0; i<Provider.of<SplashController>(context, listen:false).
                                              configModel!.languageList!.length;i++){
                                                _addProduct!.languageList!.insert(i, Provider.of<SplashController>(context, listen:false).configModel!.languageList![i].code) ;
                                              }
                                            }

                                            final imagesUploaded = await _uploadAllPendingImages(
                                              context,
                                              addProductImageController,
                                            );
                                            if (!imagesUploaded) {
                                              return;
                                            }

                                            Provider.of<AddProductController>(Get.context!, listen: false).addProduct(
                                              Get.context!,
                                              _product!,
                                              _addProduct!,
                                              thumbnailImage,
                                              metaImage,
                                              widget.product == null,
                                              tagList,
                                            );
                                          }

                                        }
                                      ),
                                    )
                                  ],
                                )  :const Center(child: CircularProgressIndicator()),);
                            });
                          }
                        );
                      }
                    ),

                  ],
                );
              },
            );
          }
        ),),

      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

