


abstract class WithdrawServiceInterface {
  Future<dynamic> sendWithdrawRequest({String? amount, String? note,});
  Future<dynamic> getWithdrawList({String? startDate, String? endDate, int? offset, String? type});
}