import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' as foundation;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:quiksee/data/models/response/error_response.dart';
import 'package:quiksee/utill/app_constants.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static const String noInternetMessage = 'Connection to API server failed due to internet connection';
  static const String timeoutMessage = 'Server is taking too long. Please try again.';
  static const String requestFailedMessage = 'Could not reach server. Please try again.';
  final int timeoutInSeconds = 30;
  final int multipartTimeoutInSeconds = 45;

  String? token;
  late Map<String, String>? _mainHeaders;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);
    debugPrint('Token: $token');

    updateHeader(token, sharedPreferences.getString(AppConstants.languageCode));
  }

  void updateHeader(String? token, String? languageCode) {
    _mainHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode ?? 'en',
      'Authorization': 'Bearer $token'
    };
  }

  String _fullUri(String uri) => '$appBaseUrl$uri';

  Response _errorResponse(Object e) {
    final text = e.toString().toLowerCase();
    if (e is TimeoutException || text.contains('timeout')) {
      return const Response(statusCode: 1, statusText: timeoutMessage);
    }
    if (e is SocketException ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('no address associated')) {
      return const Response(statusCode: 1, statusText: noInternetMessage);
    }
    return const Response(statusCode: 1, statusText: requestFailedMessage);
  }

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    int? timeoutSeconds,
  }) async {
    final String fullUri = _fullUri(uri);
    try {
      debugPrint('====> API Call: $fullUri\nHeader: $_mainHeaders');
      http.Response _response = await http.get(
        Uri.parse(fullUri),
        headers: headers ?? _mainHeaders,
      ).timeout(Duration(seconds: timeoutSeconds ?? timeoutInSeconds));
      return handleResponse(_response, fullUri);
    } catch (e) {
      debugPrint('====> API Error: $fullUri\n$e');
      return _errorResponse(e);
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    int? timeoutSeconds,
  }) async {
    final String fullUri = _fullUri(uri);
    try {
      debugPrint('====> API Call: $fullUri\nHeader: $_mainHeaders');
      debugPrint('====> API Body: $body');
      http.Response _response = await http.post(
        Uri.parse(fullUri),
        body: jsonEncode(body),
        headers: headers ?? _mainHeaders,
      ).timeout(Duration(seconds: timeoutSeconds ?? timeoutInSeconds));
      return handleResponse(_response, fullUri);
    } catch (e) {
      debugPrint('====> API Error: $fullUri\n$e');
      return _errorResponse(e);
    }
  }

  Future<Response> postMultipartData(String uri, Map<String, String> body, List<MultipartBody> multipartBody, {Map<String, String>? headers, List<PlatformFile>? platformFile}) async {
    final String fullUri = _fullUri(uri);
    try {
      debugPrint('====> API Call: $fullUri\nHeader: $_mainHeaders');
      debugPrint('====> API Body: $body with ${multipartBody.length} files');
      http.MultipartRequest _request = http.MultipartRequest('POST', Uri.parse(fullUri));
      _request.headers.addAll(headers ?? _mainHeaders as Map<String, String>);
      for(MultipartBody multipart in multipartBody) {
        if(foundation.kIsWeb) {
          Uint8List _list = await multipart.file.readAsBytes();
          http.MultipartFile _part = http.MultipartFile(
            multipart.key, multipart.file.readAsBytes().asStream(), _list.length,
            filename: basename(multipart.file.path), contentType: MediaType('image', 'jpg'),
          );
          _request.files.add(_part);
        }else {
          File _file = File(multipart.file.path);
          _request.files.add(http.MultipartFile(
            multipart.key, _file.readAsBytes().asStream(), _file.lengthSync(), filename: _file.path.split('/').last,
          ));
        }
      }

      if(platformFile != null ) {
        if(platformFile.isNotEmpty){
          for(PlatformFile pfile in platformFile) {
            _request.files.add(http.MultipartFile('file[]', pfile.readStream!, pfile.size, filename: basename(pfile.name)));
          }
        }
      }

      _request.fields.addAll(body);
      final streamed = await _request.send().timeout(
        Duration(seconds: multipartTimeoutInSeconds),
      );
      http.Response response = await http.Response.fromStream(
        streamed,
      ).timeout(Duration(seconds: multipartTimeoutInSeconds));
      return handleResponse(response, fullUri);
    } catch (e) {
      debugPrint('====> API Error: $fullUri\n$e');
      return _errorResponse(e);
    }
  }

  Future<Response> putData(String uri, dynamic body, {Map<String, String>? headers}) async {
    final String fullUri = _fullUri(uri);
    try {
      debugPrint('====> API Call: $fullUri\nHeader: $_mainHeaders');
      debugPrint('====> API Body: $body');
      http.Response _response = await http.put(
        Uri.parse(fullUri),
        body: jsonEncode(body),
        headers: headers ?? _mainHeaders,
      ).timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(_response, fullUri);
    } catch (e) {
      debugPrint('====> API Error: $fullUri\n$e');
      return _errorResponse(e);
    }
  }

  Future<Response> deleteData(String uri, {Map<String, String>? headers}) async {
    final String fullUri = _fullUri(uri);
    try {
      debugPrint('====> API Call: $fullUri\nHeader: $_mainHeaders');
      http.Response _response = await http.delete(
        Uri.parse(fullUri),
        headers: headers ?? _mainHeaders,
      ).timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(_response, fullUri);
    } catch (e) {
      debugPrint('====> API Error: $fullUri\n$e');
      return _errorResponse(e);
    }
  }

  Response handleResponse(http.Response response, String uri) {

    dynamic _body;
    try {
      _body = jsonDecode(response.body);
    }catch(e) {
      debugPrint(e.toString());
    }
    Response _response = Response(
      body: _body ?? response.body, bodyString: response.body.toString(),
      headers: response.headers, statusCode: response.statusCode, statusText: response.reasonPhrase,
    );
    if(_response.statusCode != 200 && _response.body != null && _response.body is !String) {
      if(_response.body.toString().startsWith('{errors: [{code:')) {
        ErrorResponse _errorResponse = ErrorResponse.fromJson(_response.body);
        _response = Response(statusCode: _response.statusCode, body: _response.body, statusText: _errorResponse.errors![0].message);
      } else if(_response.body.toString().startsWith('{errors: [{error_code:')) {
        ErrorResponse _errorResponse = ErrorResponse.fromJson(_response.body);
        _response = Response(statusCode: _response.statusCode, body: _response.body, statusText: _errorResponse.errors![0].message);
      } else if(_response.body.toString().startsWith('{message')) {
        _response = Response(statusCode: _response.statusCode, body: _response.body, statusText: _response.body['message']);
      }
    } else if (_response.statusCode != 200 && _response.body == null) {
      _response = const Response(statusCode: 0, statusText: noInternetMessage);
    }
    final String preview = _response.body is String
        ? (_response.body as String).substring(
            0,
            (_response.body as String).length > 300
                ? 300
                : (_response.body as String).length,
          )
        : '${_response.body}';
    debugPrint('====> API Response: [${_response.statusCode}] $uri\n$preview');
    return _response;
  }
}

class MultipartBody {
  String key;
  XFile file;

  MultipartBody(this.key, this.file);
}