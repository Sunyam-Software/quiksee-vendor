

import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/withdraw/domain/repositories/withdraw_repository_interfaec.dart';
import 'package:quiksee/utill/app_constants.dart';

class WithdrawRepository implements WithdrawRepositoryInterface {
 final ApiClient apiClient;
 WithdrawRepository({required this.apiClient});

 @override
 Future<Response> sendWithdrawRequest({String? amount, String? note,}) async {
  return apiClient.postData(AppConstants.withdrawRequestUri,{
   // "amount": PriceConverter.convertPriceWithoutSymbol(Get.context!, double.tryParse(amount!)),
   "amount": amount,
   "note": note,
  });
 }

 @override
 Future<Response> getWithdrawList({String? startDate, String? endDate, int? offset, String? type}) async {
  return apiClient.getData('${AppConstants.withdrawListUri}?limit=10&offset=$offset&start_date=$startDate&end_date=$endDate&type=$type');
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