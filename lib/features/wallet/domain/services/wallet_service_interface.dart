
abstract class WalletServiceInterface {
  Future<dynamic> getDeliveryWiseEarned({String? startDate, String? endDate, int? offset,String? type});
  Future<dynamic> getDepositedList({String? startDate, String? endDate, int? offset, String? type});

}