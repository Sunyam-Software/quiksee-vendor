import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:open_file/open_file.dart' show OpenFile;
import 'package:open_file_manager/open_file_manager.dart';
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/order/controllers/order_controller.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/features/order_details/domain/models/order_details_model.dart';
import 'package:quiksee_vendor_app/features/order_details/domain/models/order_setup_model.dart';
import 'package:quiksee_vendor_app/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/helper/map_helper.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/images.dart';

class OrderDetailsController extends ChangeNotifier{
  final OrderDetailsServiceInterface orderDetailsServiceInterface;
  OrderDetailsController({required this.orderDetailsServiceInterface});

  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;
  List<String> _orderStatusList = [];
  List<String> get orderStatusList => _orderStatusList;
  String? _orderStatusType = '';
  String? get orderStatusType => _orderStatusType;
  int _paymentMethodIndex = 0;
  int get paymentMethodIndex => _paymentMethodIndex;
  File? _selectedFileForImport ;
  File? get selectedFileForImport =>_selectedFileForImport;
  bool _isLoading = false;
  bool get isLoading=> _isLoading;

  bool _isUploadLoading = false;
  bool get isUploadLoading=> _isUploadLoading;

  bool _isUpdating = false;
  bool get isUpdating=> _isUpdating;

  Set<Marker> _markers = HashSet<Marker>();
  Set<Marker> get markers => _markers;
  bool _isDownloadLoading = false;
  bool get isDownloadLoading => _isDownloadLoading;
  int _downloadIndex = -1;
  int get downloadIndex => _downloadIndex;

  late OrderSetupModel orderSetupModel;

  bool _isInvoiceLoading = false;
  bool get isInvoiceLoading => _isInvoiceLoading;

  Future<void> getOrderDetails( String orderID) async {
    _orderDetails = null;
    ApiResponse apiResponse = await orderDetailsServiceInterface.getOrderDetails(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      try {
        _orderDetails = [];
        apiResponse.response!.data.forEach((order) => _orderDetails!.add(OrderDetailsModel.fromJson(order)));
        await initOrderStatusList(_orderDetails?[0].order?.shippingResponsibility ?? '');

        await _silenceKitchenRingIfPastPending(
          int.tryParse(orderID) ?? 0,
          _orderDetails?[0].order?.orderStatus,
        );
      } catch (e) {
        _orderDetails = null;
        debugPrint('getOrderDetails parse error: $e');
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<void> _silenceKitchenRingIfPastPending(
    int orderId,
    String? orderStatus,
  ) async {
    if (orderId <= 0) return;
    final status = (orderStatus ?? '').trim().toLowerCase();
    if (status.isEmpty || status == 'pending') return;
  }

  Future<void> initOrderStatusList(String type) async {
    ApiResponse apiResponse = await orderDetailsServiceInterface.getOrderStatusList(type);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _orderStatusList =[];
      _orderStatusList.addAll(apiResponse.response!.data);
      _orderStatusType = apiResponse.response!.data[0];
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void setPaymentMethodIndex(int index) {
    _paymentMethodIndex = index;
    notifyListeners();
  }

  void updateOrderSetupStatus(String? status) {
    orderSetupModel.orderStatus = status;
    notifyListeners();
  }

  void updateOrderSetupPaymentStatus(String? status) {
    orderSetupModel.paymentStatus = status;
    _paymentMethodIndex = status == 'paid' ? 0 : 1;
    notifyListeners();
  }

  void setSelectedFileName(File? fileName){
    _selectedFileForImport = fileName;
    notifyListeners();
  }

  Future<ApiResponse> uploadReadyAfterSellDigitalProduct(BuildContext context, File? digitalProductAfterSellFile, String token, String orderId) async {
    _isUploadLoading = true;
    notifyListeners();
    ApiResponse  response = await orderDetailsServiceInterface.uploadAfterSellDigitalProduct(digitalProductAfterSellFile, token, orderId);
    if(response.response!.statusCode == 200) {
      Navigator.of(Get.context!).pop();
      _isUploadLoading = false;
      showQuikseeSnackBarWidget(getTranslated("digital_product_uploaded_successfully", Get.context!), Get.context!, isError: false);
    }else {
      _isUploadLoading = false;
    }
    _isUploadLoading = false;
    notifyListeners();
    return response;
  }

  BillingAddressData getAddressForMap(BillingAddressData shipping, BillingAddressData? billing) {
    if(shipping.latitude != null && shipping.longitude != null) {
      return shipping;
    } else if (billing?.latitude != null && billing?.longitude != null) {
      return billing!;
    }else {
      return shipping;
    }
  }

  Future<void> setMarker(BillingAddressData address) async {
    final LatLng? position = MapHelper.latLngFromAddress(address);
    if (position == null) return;

    _markers = HashSet<Marker>();
    final Uint8List destinationImageData = await convertAssetToUnit8List(
      Images.marker,
      width: 50,
    );

    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: position,
      icon: BitmapDescriptor.bytes(destinationImageData),
    ));

    notifyListeners();
  }

  Future<Uint8List> convertAssetToUnit8List(String imagePath, {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  }

  void productDownload({required String url, required String fileName, required int index, bool isIos = false}) async {
    _isDownloadLoading = true;
    _downloadIndex = index;
    notifyListeners();

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    var selectedFolderType = AndroidFolderType.download;
    final subFolderPathCtrl = TextEditingController();

    List<String> fileTypes = [ '.txt', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.mp3', '.wav', '.ogg', '.m4a', '.aac',
      '.mp4', '.avi', '.mkv', '.webm', '.3gp', '.pdf', '.doc'];

    if(isIos) {
      HttpClientResponse apiResponse = await orderDetailsServiceInterface.productDownload(url);
      if (apiResponse.statusCode == 200) {

        List<int> downloadData = [];
        Directory downloadDirectory;

        if (Platform.isIOS) {
          downloadDirectory = await getApplicationDocumentsDirectory();
        } else {
          downloadDirectory = Directory('/storage/emulated/0/Download');
          if (!await downloadDirectory.exists()) downloadDirectory = (await getExternalStorageDirectory())!;
        }

        String filePathName = "${downloadDirectory.path}/$fileName";
        File savedFile = File(filePathName);
        bool fileExists = await savedFile.exists();

        if (fileExists) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(content: Text("File already downloaded")));
          _isDownloadLoading = false;
        } else {
          apiResponse.listen((d) => downloadData.addAll(d), onDone: () {
            savedFile.writeAsBytes(downloadData);
          });
          showQuikseeSnackBarWidget(getTranslated('product_downloaded_successfully', Get.context!), Get.context!, isError: false);

          _isDownloadLoading = false;
          Navigator.of(Get.context!).pop();
        }
      } else {
        _isDownloadLoading = false;

        showQuikseeSnackBarWidget(getTranslated('product_download_failed', Get.context!), Get.context!);
        Navigator.of(Get.context!).pop();
      }
    } else {
      String? task;
      Directory downloadDirectory = Directory('/storage/emulated/0/Download');
      String filePathName = "${downloadDirectory.path}/$fileName";
      File savedFile = File(filePathName);
      bool fileExists = await savedFile.exists();

      if(fileExists) {
        showQuikseeSnackBarWidget(getTranslated('file_already_downloaded', Get.context!), Get.context!);
      } else{
        task  = await FlutterDownloader.enqueue(
          url: url,
          savedDir: downloadDirectory.path,
          fileName: fileName,
          showNotification: true,
          saveInPublicStorage: true,
          openFileFromNotification: true,
        );

        if(task != null) {
          if(!fileTypes.contains(getFileExtension(fileName))){
            showQuikseeSnackBarWidget(getTranslated('product_downloaded_successfully', Get.context!), Get.context!, isError: false);
            await openFileManager(
              androidConfig: AndroidConfig(
                folderType: selectedFolderType,
              ),
              iosConfig: IosConfig(
                folderPath: subFolderPathCtrl.text.trim(),
              ),
            );
          }else {

          }
        } else{
          showQuikseeSnackBarWidget(getTranslated('product_download_failed', Get.context!), Get.context!);

        }
      }
      _isDownloadLoading = false;
    }
    notifyListeners();
  }

  String getFileExtension(String fileName) {
    if (fileName.contains('.')) {
      return '.${fileName.split('.').last}';
    }
    return '';
  }

  void emptyOrderDetails() {
    _orderDetails = null;
    notifyListeners();
  }

  Future<bool> setUpOrder({
    required OrderSetupModel orderSetupModel,
    BuildContext? context,
    bool showLoading = true,
    bool showSuccessSnackBar = true,
    bool showErrorSnackBar = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    ApiResponse apiResponse = await orderDetailsServiceInterface.setUpOrder(orderSetupModel);
    final BuildContext? snackContext = context ?? Get.context;

    bool success = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final dynamic body = apiResponse.response!.data;
      if (body is Map) {
        final dynamic flag = body['success'];
        success = flag == 1 || flag == true;
        if (!success && showErrorSnackBar && snackContext != null && snackContext.mounted) {
          final String message = body['message']?.toString() ??
              getTranslated('something_went_wrong', snackContext) ??
              'Update failed';
          showQuikseeSnackBarWidget(message, snackContext, isToaster: true, sanckBarType: SnackBarType.error);
        }
      } else {
        success = true;
      }
    }

    if (showLoading) {
      _isLoading = false;
      notifyListeners();
    }

    if (success) {
      final int? updatedOrderId = orderSetupModel.orderId;

      final status = (orderSetupModel.orderStatus ?? '').toLowerCase();
      final shouldStopKitchenRing = updatedOrderId != null &&
          updatedOrderId > 0 &&
          (status == 'canceled' ||
              status == 'cancelled' ||
              status == 'confirmed' ||
              status == 'processing' ||
              status == 'reached_restaurant' ||
              status == 'out_for_delivery' ||
              status == 'arrived_at_customer' ||
              status == 'delivered' ||
              status == 'returned' ||
              status == 'failed');
      if (shouldStopKitchenRing) {

      }

      if (showSuccessSnackBar && snackContext != null && snackContext.mounted) {
        final String? message = getTranslated('updated_successfully', snackContext);
        showQuikseeSnackBarWidget(message, snackContext, isToaster: true, isError: false,  sanckBarType: SnackBarType.success);
      }

      unawaited(getOrderDetails(orderSetupModel.orderId.toString()));
      if (Get.context != null) {
        unawaited(Provider.of<OrderController>(Get.context!, listen: false).getOrderList(
          Get.context!,
          1,
          'all',
          Provider.of<OrderController>(Get.context!, listen: false).filterModel,
        ));
      }
    } else if (apiResponse.response == null && showErrorSnackBar) {
      ApiChecker.checkApi(apiResponse);
    }
    return success;
  }

  Future<bool> notifyDeliveryManReady({required int orderId, BuildContext? context}) async {
    _isLoading = true;
    notifyListeners();
    final ApiResponse apiResponse =
        await orderDetailsServiceInterface.notifyDeliveryManReady(orderId);
    final BuildContext? snackContext = context ?? Get.context;
    bool success = false;

    if (apiResponse.response != null &&
        (apiResponse.response!.statusCode == 200 ||
            apiResponse.response!.statusCode == 201)) {
      final dynamic body = apiResponse.response!.data;
      if (body is Map) {
        success = body['success'] == true || body['success'] == 1;
        if (snackContext != null && snackContext.mounted) {
          showQuikseeSnackBarWidget(
            body['message']?.toString() ??
                (success
                    ? (getTranslated('updated_successfully', snackContext) ??
                        'Ready — delivery boy notified')
                    : (getTranslated('something_went_wrong', snackContext) ??
                        'Failed')),
            snackContext,
            isToaster: true,
            isError: !success,
            sanckBarType: success ? SnackBarType.success : SnackBarType.error,
          );
        }
      } else {
        success = true;
      }
    } else if (apiResponse.response == null) {
      ApiChecker.checkApi(apiResponse);
    }

    if (success) {
      await getOrderDetails(orderId.toString());
      if (Get.context != null) {
        Provider.of<OrderController>(Get.context!, listen: false).getOrderList(
          Get.context!,
          1,
          'all',
          Provider.of<OrderController>(Get.context!, listen: false).filterModel,
        );
      }
    } else if (apiResponse.response != null &&
        snackContext != null &&
        snackContext.mounted) {
      final dynamic body = apiResponse.response!.data;
      final message = body is Map
          ? (body['message']?.toString() ??
              getTranslated('something_went_wrong', snackContext) ??
              'Failed')
          : (getTranslated('something_went_wrong', snackContext) ?? 'Failed');
      showQuikseeSnackBarWidget(
        message,
        snackContext,
        isToaster: true,
        isError: true,
        sanckBarType: SnackBarType.error,
      );
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> verifyPickupOtp({
    required int orderId,
    required String otp,
    BuildContext? context,
  }) async {
    _isLoading = true;
    notifyListeners();
    final ApiResponse apiResponse =
        await orderDetailsServiceInterface.verifyPickupOtp(
      orderId: orderId,
      otp: otp,
    );
    final BuildContext? snackContext = context ?? Get.context;
    bool success = false;

    if (apiResponse.response != null &&
        (apiResponse.response!.statusCode == 200 ||
            apiResponse.response!.statusCode == 201)) {
      final dynamic body = apiResponse.response!.data;
      if (body is Map) {
        success = body['success'] == true || body['success'] == 1;
        if (snackContext != null && snackContext.mounted) {
          showQuikseeSnackBarWidget(
            body['message']?.toString() ??
                (success
                    ? (getTranslated('otp_verified_successfully', snackContext) ??
                        'OTP verified successfully')
                    : (getTranslated('invalid_otp', snackContext) ??
                        'Invalid OTP')),
            snackContext,
            isToaster: true,
            isError: !success,
            sanckBarType: success ? SnackBarType.success : SnackBarType.error,
          );
        }
      } else {
        success = true;
      }
    } else if (apiResponse.response != null &&
        snackContext != null &&
        snackContext.mounted) {
      final dynamic body = apiResponse.response!.data;
      final message = body is Map
          ? (body['message']?.toString() ??
              getTranslated('invalid_otp', snackContext) ??
              'Invalid OTP')
          : (getTranslated('invalid_otp', snackContext) ?? 'Invalid OTP');
      showQuikseeSnackBarWidget(
        message,
        snackContext,
        isToaster: true,
        isError: true,
        sanckBarType: SnackBarType.error,
      );
    } else if (apiResponse.response == null) {
      ApiChecker.checkApi(apiResponse);
    }

    if (success) {

      if (_orderDetails != null) {
        for (final detail in _orderDetails!) {
          final order = detail.order;
          if (order != null && order.id == orderId) {
            order.pickupVerificationStatus = 1;
            order.pickupOtpVerified = 1;
            order.pickupOtpRequired = 0;
          }
        }
      }
      notifyListeners();

      unawaited(getOrderDetails(orderId.toString()));
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void initializeOrderSetupModel({required Order? order, bool notify = true}){
    orderSetupModel = OrderSetupModel(
      orderId: order?.id,
      paymentStatus: order?.paymentStatus,
      orderStatus: order?.orderStatus,
    );
    _paymentMethodIndex = order?.paymentStatus == 'paid' ? 0 : 1;
    if (notify) {
      notifyListeners();
    }
  }

  Future <ApiResponse> getOrderInvoice(String orderID, context) async {
    _isInvoiceLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await orderDetailsServiceInterface.getOrderInvoice(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      await requestPermissions();
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      List<int> intList = List<int>.from(apiResponse.response!.data);

      String fileName = '$orderID.pdf';
      var filePath = path.join(downloadsDirectory.path, '$orderID.pdf');

      int fileCounter = 1;

      while (await File(filePath).exists()) {
        fileName = '$orderID($fileCounter).pdf';
        filePath = path.join(downloadsDirectory.path, fileName);
        fileCounter++;
      }

      final file = File(filePath);
      await file.writeAsBytes(intList);
      await OpenFile.open(filePath);
      showQuikseeSnackBarWidget(getTranslated('invoice_downloaded_successfully', context), Get.context!, sanckBarType : SnackBarType.success);
    } else {
      showQuikseeSnackBarWidget(getTranslated('invoice_download_failed', context), Get.context!, sanckBarType: SnackBarType.success);
    }
    _isInvoiceLoading = false;
    notifyListeners();
    return apiResponse;
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

}
