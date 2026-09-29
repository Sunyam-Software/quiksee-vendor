import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/data/model/response/base/error_response.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class ApiErrorHandler {
  static String? _readValidationMessage(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final message = data['message'];
    if (message != null) {
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        return first is Map ? first['message']?.toString() : first.toString();
      }
      final text = message.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    if (data['errors'] != null) {
      final errorResponse = ErrorResponse.fromJson(data);
      final first = errorResponse.errors?.isNotEmpty == true
          ? errorResponse.errors!.first.message
          : null;
      if (first != null && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    return null;
  }

  static dynamic getMessage(dynamic error) {
    dynamic errorDescription = "";
    if (error is Exception) {
      try {
        if (error is DioException) {
          switch (error.type) {
            case DioExceptionType.cancel:
              errorDescription = "Request to API server was cancelled";
              break;
            case DioExceptionType.connectionTimeout:
              errorDescription = "Connection timeout with API server";
              break;
            case DioExceptionType.sendTimeout:
              errorDescription = "Send timeout";
              break;
            case DioExceptionType.receiveTimeout:
              errorDescription = "Receive timeout in connection with API server";
              break;
            case DioExceptionType.badResponse:
              switch (error.response!.statusCode) {
              case 403:
                if (kDebugMode) {
                  print("===403===>>${error.response!.data}");
                }
                  if(error.response!.data.containsKey('key')){
                    errorDescription = error.response!.data['key'];
                  }else if(error.response!.data['errors'] != null){
                    ErrorResponse errorResponse = ErrorResponse.fromJson(error.response?.data);
                    errorDescription = errorResponse.errors?[0].message;
                  }else{
                    errorDescription = error.response!.data['message'];
                  }
                  break;
                case 401:

                  if (kDebugMode) {
                    print("==401==>>401");
                    print("====>>${Provider.of<AuthController>(Get.context!,listen: false).isUnAuthorize}");
                  }

                  final data = error.response?.data;
                  if (data is Map && data.containsKey('auth-001')) {

                    errorDescription = 'unauthorized';
                    break;
                  }

                  if(data is Map && data.containsKey('loginStatus')) {
                    errorDescription = data['loginStatus'];
                  } else if(data is Map && data['errors'] != null){
                    ErrorResponse errorResponse = ErrorResponse.fromJson(data);
                    errorDescription = errorResponse.errors?[0].message;
                  } else if (data is Map){
                    errorDescription = data['message'];
                  }

                  errorDescription ??= 'unauthorized';

                  if (kDebugMode) {
                    print("===ErrorDescription====>>$errorDescription");
                  }

                  break;
                case 405:
                  if (kDebugMode) {
                    print("==Responce=405=>>${error.response!.data}");
                  }
                case 404:
                  if(error.response!.data['errors'] != null){
                    ErrorResponse errorResponse = ErrorResponse.fromJson(error.response?.data);
                    errorDescription = errorResponse.errors?[0].message;
                  }else{
                    errorDescription = error.response!.data['message'];
                  }
                  break;
                case 422:
                  errorDescription = _readValidationMessage(error.response?.data);
                  break;
                case 500:
                  if (kDebugMode) {
                    print("==Responce=500=>>${error.response!.data}");
                  }
                case 503:
                  if(error.response!.data['message'] != null){
                    errorDescription = error.response!.data['message'];
                  }
                case 429:

                  break;
                default:
                  ErrorResponse errorResponse = ErrorResponse.fromJson(error.response!.data);
                  if (errorResponse.errors != null && errorResponse.errors!.isNotEmpty) {
                    errorDescription = errorResponse;
                  } else {errorDescription = "Failed to load data - status code: ${error.response!.statusCode}";
                  }
              }
              break;
            case DioExceptionType.badCertificate:
              errorDescription = 'Unable to verify server SSL certificate. Check your server URL or certificate.';
              break;
            case DioExceptionType.connectionError:
              errorDescription = 'Cannot connect to server. Check Wi-Fi and that ${AppConstants.baseUrl} is reachable.';
              break;
            case DioExceptionType.unknown:
              errorDescription = error.message ?? 'Network request failed';
              break;
          }
        } else {
          errorDescription = "Unexpected error occured";
        }
      } on FormatException catch (e) {
        errorDescription = e.toString();
      }
    } else {
      errorDescription = "is not a subtype of exception";
    }
    return errorDescription;
  }
}
