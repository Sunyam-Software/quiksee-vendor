class ResponseModel {
  final bool _isSuccess;
  final String? _message;
  final bool verificationRequired;

  ResponseModel(
    this._isSuccess,
    this._message, {
    this.verificationRequired = false,
  });

  String? get message => _message;
  bool get isSuccess => _isSuccess;
}