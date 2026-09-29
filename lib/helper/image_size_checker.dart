import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart';
import 'package:quiksee/utill/app_constants.dart';

class ImageValidationHelper{

  static Future<XFile?> validateAndPickImage({
    required BuildContext context,
    required ImageSource source,
    int? imageQuality,
    double? maxHeight,
    double? maxWidth,
  }) async {
    try {
      // Step 1: Pick the image
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        imageQuality: AppConstants.imageQuality ?? 50,
        maxHeight: maxHeight,
        maxWidth: maxWidth,
      );

      if (pickedImage == null) return null;

      // Step 2: Validate file extension
      final extensionError = validateFileExtension(
        file: pickedImage,
        context: Get.context!,
      );

      if (extensionError != null) {
        showQuikseeSnackBarWidget(extensionError);
        return null;
      }

      // Step 3: Get config and validate size
      ConfigModel? configModel = Get.find<SplashController>().configModel;
      int maxSize = (configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit);


      final validationError = await validateFileSizeAsync(
        file: pickedImage,
        maxSizeInBytes: maxSize,
        context: Get.context!,
      );

      // Step 4: Show error if validation failed
      if (validationError != null) {
        showQuikseeSnackBarWidget(validationError);
        return null;
      }

      // Step 5: Return valid file
      return pickedImage;

    } catch (error) {
      debugPrint('Image picking error: $error');
      return null;
    }
  }


  static Future<List<XFile>> validateAndPickMultipleImages({
    required BuildContext context,
    int? imageQuality,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedImages = await picker.pickMultiImage(
        imageQuality: AppConstants.imageQuality ?? 30,
      );

      if (pickedImages.isEmpty) return [];

      // Step 2: Validate file extensions
      final extensionError = validateMultipleFileExtensions(
        files: pickedImages,
        context: Get.context!,
      );

      if (extensionError != null) {
        showQuikseeSnackBarWidget(extensionError);
        return [];
      }

      // Step 3: Get config and validate sizes
      ConfigModel? configModel = Get.find<SplashController>().configModel;
      int maxSize = (configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit);

      final validationError = await validateMultipleFilesSize(
        files: pickedImages,
        maxSizeInBytes: maxSize,
        context: Get.context!,
      );

      // Step 4: Show error if validation failed
      if (validationError != null) {
        showQuikseeSnackBarWidget(validationError);
        return [];
      }

      // Step 5: Return valid files
      return pickedImages;
    } catch (error) {
      debugPrint('Multiple images picking error: $error');
      return [];
    }
  }


  static String? validateMultipleFileExtensions({
    required List<XFile> files,
    required BuildContext context,
  }) {
    for (int i = 0; i < files.length; i++) {
      final error = validateFileExtension(
        file: files[i],
        context: context,
      );
      if (error != null) {
        return '${'file'.tr} ${i + 1}: $error';
      }
    }

    return null;
  }


  static Future<String?> validateFileSizeAsync({
    required XFile file,
    required int maxSizeInBytes,
    required BuildContext context,
  }) async {
    try {
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);


      if (fileSizeInMB > maxSizeInBytes) {
        final maxSizeInMB = maxSizeInBytes;
        return '${'file_size'.tr} (${fileSizeInMB.toStringAsFixed(2)} ${'mb'.tr}) ${'exceeds_maximum_allowed_size'.tr} (${maxSizeInMB.toStringAsFixed(2)} ${'mb'.tr})';
      }
      return null;
    } catch (e) {
      return '${'failed_to_validate_file_size'.tr}: $e';
    }
  }


  static String? validateFileExtension({
    required XFile file,
    required BuildContext context,
  }) {
    try {
      // Try 1: Validate using MIME type (iOS/Web usually provides this)
      if (_isValidMimeType(file.mimeType)) {
        return null;
      }

      // Try 2: Validate using file extension from name or path (Android often needs this)
      final fileExtension = _extractFileExtension(file);
      if (_isValidExtension(fileExtension)) {
        return null;
      }

      // Return error if validation failed
      return _buildInvalidFileTypeError(context);

    } catch (e) {
      return _buildValidationFailedError(context, e);
    }
  }

  /// Checks if MIME type contains any allowed image extension
  static bool _isValidMimeType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) {
      return false;
    }

    final normalizedMimeType = mimeType.toLowerCase();
    return AppConstants.imageExtensions.any(
          (extension) => normalizedMimeType.contains(extension),
    );
  }

  static bool _isValidExtension(String? extension) {
    if (extension == null || extension.isEmpty) {
      return false;
    }

    return AppConstants.imageExtensions.contains(extension);
  }

  static String _buildInvalidFileTypeError(BuildContext context) {
    final invalidFileType = 'invalid_file_type'.tr;
    final allowedFormats = 'allowed_formats'.tr;
    final extensions = AppConstants.imageExtensions.join(', ');

    return '$invalidFileType. $allowedFormats: $extensions';
  }

  static String? _extractFileExtension(XFile file) {
    // Try getting extension from file name first
    if (file.name.isNotEmpty && file.name.contains('.')) {
      return file.name.toLowerCase().split('.').last;
    }

    // Fallback to file path
    if (file.path.contains('.')) {
      return file.path.toLowerCase().split('.').last;
    }

    return null;
  }

  /// Builds error message for validation failure
  static String _buildValidationFailedError(BuildContext context, Object error) {
    final failedMessage = 'failed_to_validate_file_type'.tr;
    return '$failedMessage: $error';
  }


  static Future<String?> validateMultipleFilesSize({
    required List<XFile> files,
    required int maxSizeInBytes,
    required BuildContext context,
  }) async {
    for (int i = 0; i < files.length; i++) {
      final error = await validateFileSizeAsync(
        file: files[i],
        maxSizeInBytes: maxSizeInBytes,
        context: context,
      );

      if (error != null) {
        return '${'file'.tr} ${i + 1}: $error';
      }
    }

    return null;
  }


  static Future <double> getImageSizeFromXFile(XFile xFile)  async {
    int sizeInKB =  await xFile.length();
    double sizeInMB = sizeInKB / (1024 * 1024);
    return sizeInMB;
  }

   static Future <double> getMultipleImageSizeFromXFile(List<XFile>  xFiles)  async {

     double imageSize = 0.0;
     for (var element in xFiles) {
       imageSize = ( await element.length() / (1024 * 1024)) + imageSize;
     }
     return imageSize;
   }


   static double getFileSizeFromXFileSync(XFile xFile) {
     final file = File(xFile.path);
     final sizeInBytes = file.lengthSync();
     return sizeInBytes / (1024 * 1024);
   }

   // static Future <double> getMultipleImageSizeFromMultipart(List<MultipartBody>  multiParts)  async {
   //
   //   double imageSize = 0.0;
   //   for (var element in multiParts) {
   //     imageSize = ( await element.file.length() / (1024 * 1024)) + imageSize;
   //   }
   //   return imageSize;
   // }

   static String getFileSizeFromPlatformFileToString(PlatformFile platformFile)  {

     int sizeOfTheFileInBytes =  platformFile.size;
     String fileSize = "";

     if((sizeOfTheFileInBytes / (1024 * 1024)) > 1){
       fileSize = "${(sizeOfTheFileInBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
     }else{
       fileSize = "${(sizeOfTheFileInBytes / 1024 ).toStringAsFixed(1)} KB";
     }
     return fileSize;
   }

   static double getFileSizeFromPlatformFileToDouble(PlatformFile platformFile)  {
     return (platformFile.size / (1024 * 1024));
   }


   static double getMultipleFileSizeFromPlatformFiles(List<PlatformFile> platformFiles)  {

     double fileSize = 0.0;
     for (var element in platformFiles) {
       fileSize  = (element.size / (1024 * 1024)) + fileSize;
     }
     return fileSize;
   }
}