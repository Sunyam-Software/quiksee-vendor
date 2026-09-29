

class ErrorResponse {
  List<Errors>? _errors;

  List<Errors>? get errors => _errors;

  ErrorResponse({
      List<Errors>? errors}){
    _errors = errors;
}

  ErrorResponse.fromJson(dynamic json) {
    final rawErrors = json["errors"];
    if (rawErrors == null) {
      return;
    }
    _errors = [];
    if (rawErrors is List) {
      for (final item in rawErrors) {
        _errors!.add(Errors.fromJson(item));
      }
      return;
    }
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        String? message;
        if (value is List && value.isNotEmpty) {
          message = value.first?.toString();
        } else if (value != null) {
          message = value.toString();
        }
        _errors!.add(Errors(code: key?.toString(), message: message));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_errors != null) {
      map["errors"] = _errors!.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

class Errors {
  String? _code;
  String? _message;

  String? get code => _code;
  String? get message => _message;

  Errors({
      String? code,
      String? message}){
    _code = code;
    _message = message;
}

  Errors.fromJson(dynamic json) {
    _code = json["code"];
    _message = json["message"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["code"] = _code;
    map["message"] = _message;
    return map;
  }

}