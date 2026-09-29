import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/image_full_url.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/variation_controller.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/image_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/product_image_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/services/add_product_service_interface.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/helper/image_size_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';

class PendingProductImageUpload {
  final ImageModel model;
  final int? index;
  final bool update;

  const PendingProductImageUpload(this.model, {this.index, this.update = false});
}

class AddProductImageController extends ChangeNotifier {
  final AddProductServiceInterface shopServiceInterface;

  AddProductImageController({required this.shopServiceInterface});

  XFile? _selectedLogoFile;
  XFile? _selectedCoverFile;
  XFile? _selectedMetaImageFile;
  XFile? _selectedCoveredImageFile;
  List <XFile>_productImage = [];
  bool _isMultiply = false;
  bool get isMultiply => _isMultiply;
  XFile? get selectedLogoFile => _selectedLogoFile;
  XFile? get selectedCoverFile => _selectedCoverFile;
  XFile? get selectedMetaImageFile => _selectedMetaImageFile;
  XFile? get selectedCoveredImageFile => _selectedCoveredImageFile;
  List<XFile> get productImage => _productImage;

  late ImageModel thumbnailImageModel;
  late ImageModel metaImageModel;
  List<ImageModel> imagesWithColor = [];
  List<ColorImage> previousColorImage = [];
  List<ImageModel> withoutColor = [];
  List<String> imageKeysWithColor = [];
  List<String> imageKeysWithoutColor = [];
  List<ColorImage> colorImageObject = [];
  int totalSelectedImages = 0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>>? productReturnImageList  = [];
  List<String> imagesWithColorForUpdate = [];

  void pickImage(bool isLogo,bool isMeta, bool isRemove, int? index, {bool update = false, bool isAddProduct = false}) async {
    if(isRemove) {
      totalSelectedImages--;
      _selectedLogoFile = null;
      _selectedCoverFile = null;
      _selectedMetaImageFile = null;
      _selectedCoveredImageFile = null;
      _productImage = [];
      imagesWithColor =[];
      withoutColor =[];
    }else {

      totalSelectedImages ++;
      if (isLogo) {
        _selectedLogoFile =  await ImageValidationHelper.validateAndPickImage(
          source: ImageSource.gallery,
          context: Get.context!,
        );

        if(_selectedLogoFile != null) {
          thumbnailImageModel = ImageModel(type: 'thumbnail', color: '', image: _selectedLogoFile);
          if(isAddProduct){
            metaImageModel = ImageModel(type: 'meta', color: '', image: _selectedLogoFile);
            _selectedMetaImageFile = selectedLogoFile;
          }
        }
      } else if(isMeta) {
        _selectedMetaImageFile =  await ImageValidationHelper.validateAndPickImage(
          source: ImageSource.gallery,
          context: Get.context!,
        );

        if(_selectedMetaImageFile != null) {
          metaImageModel = ImageModel(type: 'meta', color: '', image: _selectedMetaImageFile);
        }
      } else {
        _selectedCoveredImageFile = await ImageValidationHelper.validateAndPickImage(
          source: ImageSource.gallery,
          context: Get.context!
        );

        if (_selectedCoveredImageFile != null && index != null) {
          if(update) {
            totalSelectedImages --;
          }
          imagesWithColor[index].image =  _selectedCoveredImageFile;
          imagesWithColor[index].type =  'product';
        } else if(_selectedCoveredImageFile != null) {
          withoutColor.add(ImageModel(image: _selectedCoveredImageFile, type: 'product',color: ''));
        }
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> _parseUploadResponseData(dynamic data) {
    dynamic payload = data;
    if (payload is String && payload.isNotEmpty) {
      payload = jsonDecode(payload);
    }
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      if (map['image_name'] != null || map['type'] != null) {
        return map;
      }
      final nested = map['data'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return {};
  }

  bool _isSuccessStatusCode(int? code) {
    return code != null && code >= 200 && code < 300;
  }

  bool _applyImageUploadResponse(
    Map<String, dynamic> map, {
    required bool isColorVariationActive,
    required bool update,
    int? index,
    required Function callback,
  }) {
    final String? name = map['image_name']?.toString();
    final String? type = map['type']?.toString();
    if (type == 'product') {
      if (name != null && name != 'null') {
        productReturnImageList?.add({
          'image_name': name,
          'storage': map['storage'] ?? 'public',
        });
      }

      if (isColorVariationActive) {
        final colorImage = map['color_image'];
        if (update &&
            colorImage is Map &&
            colorImage['color'] != null &&
            index != null &&
            index < imagesWithColorForUpdate.length) {
          final String? previousColor = colorImage['color']?.toString();
          final imageIndex = colorImageObject.indexWhere((v) => v.color == previousColor);
          if (imageIndex != -1) {
            colorImageObject[imageIndex] = ColorImage(
              color: previousColor,
              imageName: ImageFullUrl(key: name),
              storage: map['storage']?.toString(),
            );
          } else {
            final i = imagesWithColor.indexWhere((v) => v.color == previousColor);
            if (i == -1) {
              colorImageObject.add(ColorImage(
                color: previousColor,
                imageName: ImageFullUrl(key: name),
                storage: map['storage']?.toString(),
              ));
            }
          }
        } else {
          colorImageObject.add(ColorImage(
            color: colorImage is Map ? colorImage['color']?.toString() : null,
            imageName: ImageFullUrl(key: name),
            storage: map['storage']?.toString(),
          ));
        }
      }
    }

    callback(
      true,
      name,
      type,
      map['color_image'] is Map ? map['color_image']['color']?.toString() : null,
    );
    return true;
  }

  Future<bool> uploadProductImagesBatch(
    BuildContext context,
    List<PendingProductImageUpload> uploads,
    Function callback,
  ) async {
    if (uploads.isEmpty) {
      return true;
    }

    final attributeList = Provider.of<VariationController>(context, listen: false).attributeList;
    final bool isColorVariationActive = attributeList != null &&
        attributeList.isNotEmpty &&
        attributeList[0].active;

    _isLoading = true;
    notifyListeners();

    try {
      for (final upload in uploads) {
        final ApiResponse response = await shopServiceInterface.addImage(
          context,
          upload.model,
          isColorVariationActive,
        );

        if (!_isSuccessStatusCode(response.response?.statusCode)) {
          ApiChecker.checkApi(response);
          showQuikseeSnackBarWidget(
            getTranslated('image_upload_failed', Get.context!),
            Get.context!,
          );
          return false;
        }

        final map = _parseUploadResponseData(response.response!.data);
        if (map['image_name'] == null) {
          showQuikseeSnackBarWidget(
            getTranslated('image_upload_failed', Get.context!),
            Get.context!,
          );
          return false;
        }

        totalUploaded++;
        _applyImageUploadResponse(
          map,
          isColorVariationActive: isColorVariationActive,
          update: upload.update,
          index: upload.index,
          callback: callback,
        );
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future addProductImage(BuildContext context, ImageModel imageForUpload, Function callback, {bool update =false, int? index, int? productId}) async {
    return uploadProductImagesBatch(
      context,
      [PendingProductImageUpload(imageForUpload, index: index, update: update)],
      callback,
    );
  }

  int totalUploaded = 0;
  void initUpload(){
    totalUploaded = 0;
    notifyListeners();
  }

  void removeImage(int index,bool fromColor){
    if(fromColor){
      if (kDebugMode) {
        debugPrint('==$index/${imagesWithColor[index].image}/${imagesWithColor[index].color}');
      }
      imagesWithColor[index].image = null;
    }else{
      withoutColor.removeAt(index);
    }
    notifyListeners();
  }

  List<String> imagesWithoutColor = [];
  ProductImagesModel? productImagesModel;

  bool get hasExistingOrNewProductImages =>
      withoutColor.isNotEmpty ||
      imagesWithoutColor.isNotEmpty ||
      (productReturnImageList != null && productReturnImageList!.isNotEmpty);

  Future<void> getProductImage(String id, {bool isStorePreviousImage = false, bool isUpdate = true}) async {
    imagesWithoutColor = [];
    productReturnImageList = [];
    colorImageObject = [];
    imagesWithColorForUpdate =[];
    imageKeysWithColor = [];
    imageKeysWithoutColor = [];
    _isLoading = true;
    if(isUpdate) {
      notifyListeners();
    }
    ApiResponse apiResponse = await shopServiceInterface.getProductImage(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      imagesWithoutColor = [];
      productReturnImageList = [];
      imagesWithColorForUpdate =[];
      colorImageObject.clear();
      _isLoading = false;
      productImagesModel = ProductImagesModel.fromJson(apiResponse.response?.data);

      if(productImagesModel!.colorImage!.isNotEmpty) {
        colorImageObject = productImagesModel?.colorImage ?? [];

        if(isStorePreviousImage) {
          previousColorImage = [];
          previousColorImage.addAll(productImagesModel?.colorImage ?? []);

          for (var v in previousColorImage) {
            debugPrint('-----------previous image value------${v.imageName?.key} || ${v.imageName?.path} || ${v.color} || ${v.storage}');
          }
        }

        for(int i = 0; i<productImagesModel!.colorImage!.length; i++) {
          ColorImage img = productImagesModel!.colorImage![i];

          if(img.color != null){
            imagesWithColorForUpdate.add(img.imageName?.key ??'');
            log("===>vai response ==> ${img.color}");
          }

          if(imagesWithColor.isNotEmpty) {
            for(int index=0; index<imagesWithColor.length; index++) {
              log("withcolor==> ${imagesWithColor[index].color}----> ${img.color}");
              String retColor = imagesWithColor[index].color!;
              String? bb;
              if(retColor.contains('#')){
                bb = retColor.replaceAll('#', '');
              }
              log("withcolor==>chk $bb----> ${img.color}");
              if(bb == img.color) {
                setStringImage(index, img.imageName?.key  ?? '', img.color ?? '', path: img.imageName?.path);
                imageKeysWithColor.add(img.imageName?.key ?? '');
              }
            }
          }

        }
      }

      List<String> pathList = [];
      List<Map<String, dynamic>> keyList = [];
      final Set<String> colorImagesPaths = {};

      for(final imageModel in imagesWithColor) {
        if(imageModel.colorImage?.imageName?.path != null) {
          colorImagesPaths.add(imageModel.colorImage!.imageName!.path!);

        }
      }

      for(int i = 0; i < (productImagesModel?.images?.length ?? 0); i++) {
        if(productImagesModel?.images?[i].path != '') {

          if(!colorImagesPaths.contains(productImagesModel?.images?[i].path)) {
            pathList.add(productImagesModel?.images![i].path ?? '');

          }

          keyList.add({
            "image_name" : productImagesModel?.images![i].key ?? '',
            "storage" : productImagesModel?.imagesStorage![i].storage ?? 'public',
          });

          imageKeysWithoutColor.add(productImagesModel?.images![i].key ?? '');

        }
      }

      imagesWithoutColor.addAll(pathList);
      productReturnImageList?.addAll(keyList);

    } else {
      _isLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void setStringImage(int index, String image, String colorCode, {String? path}) {
    imagesWithColor[index].imageString = image;
    imagesWithColor[index].colorImage = ColorImage(color: colorCode, imageName: ImageFullUrl(key: image, path: path));
  }

  void removeProductImage ({bool isUpdate = false}) {
    _selectedLogoFile = null;
    _selectedCoverFile = null;
    _selectedMetaImageFile = null;
    _selectedCoveredImageFile = null;

    withoutColor = [];
    productReturnImageList = [];
    colorImageObject = [];
    imagesWithColor = [];
    _productImage = [];

    if(isUpdate) {
      notifyListeners();
    }
  }

  Future<void> deleteProductImage(String id, String name, String? color, {bool updateProductImage = true, bool isCheckError = true}) async {

    ApiResponse apiResponse = await shopServiceInterface.deleteProductImage(id, name, color);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(updateProductImage) {
        getProductImage(id);
      }
    } else {
      if(isCheckError) {
        ApiChecker.checkApi(apiResponse);

      }
    }
    notifyListeners();
  }

  void addWithColorImage(String? colorCode, {bool isUpdate = false}) {
    imagesWithColor.add(ImageModel(color: colorCode));

    if(isUpdate) {
      notifyListeners();
    }
  }

  void removeWithColorImage(int index){
    imagesWithColor.removeAt(index);
    notifyListeners();
  }

  void emptyWithColorImage() {
    imagesWithColor = [];
  }

  final List<ColorImage> _deletedColorImageList = [];

  Future<void> onUploadColorImages({required BuildContext context, required bool isUpdate, required int? productId, required Function callBack}) async {
    _deletedColorImageList.clear();

    if (imagesWithColor.isEmpty) {
      return;
    }

    if (isUpdate) {
      await onDeleteAllProductImage(isUpdate, productId, 0);
    }

    final uploads = <PendingProductImageUpload>[];
    for (int i = 0; i < imagesWithColor.length; i++) {
      if (imagesWithColor[i].image != null) {
        uploads.add(PendingProductImageUpload(imagesWithColor[i], index: i, update: isUpdate));
      }
    }

    if (uploads.isNotEmpty && context.mounted) {
      await uploadProductImagesBatch(context, uploads, callBack);
    }
  }

  Future<void> onDeleteAllProductImage(bool update, int? productId, int? index) async {

    if (!update || productId == null || previousColorImage.isEmpty || index != 0) {
      return;
    }

    bool isImageDeleted = false;

    for (var element in imagesWithColor) {
      String? imgColor = element.color?.replaceAll('#', '');

      int i = previousColorImage.indexWhere((v) => v.color == imgColor);

      if (i != -1 && previousColorImage[i].imageName?.key != null && element.image != null) {
        isImageDeleted = true;
      }
    }

    debugPrint('-------is delete-----$isImageDeleted');
    if (isImageDeleted) {
      _isLoading = true;
      notifyListeners();

      await Future.forEach(imagesWithColor, (element) async {
        String? imgColor = element.color?.replaceAll('#', '');

        int i = previousColorImage.indexWhere((v) => v.color == imgColor);

        if (i != -1 && previousColorImage[i].imageName?.key != null && element.image != null) {
          _deletedColorImageList.add(previousColorImage[i]);
        }
      });

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onDeleteColorImages(Product product) async {
    if(_deletedColorImageList.isNotEmpty){
      await Future.forEach(_deletedColorImageList, (image) async {
        await deleteProductImage(product.id.toString(), image.imageName!.key!, null, isCheckError: true);

      });
      await getProductImage(product.id.toString());

      _deletedColorImageList.clear();
    }
  }

}