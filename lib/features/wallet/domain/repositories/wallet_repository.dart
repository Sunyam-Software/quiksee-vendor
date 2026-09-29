import 'package:get/get_connect/connect.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/wallet/domain/repositories/wallet_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';


class WalletRepository implements WalletRepositoryInterface{
  final ApiClient apiClient;
  WalletRepository({required this.apiClient});

  @override
  Future<Response> getDeliveryWiseEarned({String? startDate, String? endDate, int? offset, String? type}) async {
    return apiClient.getData('${AppConstants.deliveryWiseEarnedUri}?start_date=$startDate&end_date=$endDate&limit=10&offset=$offset&type=$type');
  }


  @override
  Future<Response> getDepositedList({String? startDate, String? endDate, int? offset, String? type}) async {
    return apiClient.getData('${AppConstants.depositedList}?limit=10&offset=$offset&start_date=$startDate&end_date=$endDate&type=$type');
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }


}
