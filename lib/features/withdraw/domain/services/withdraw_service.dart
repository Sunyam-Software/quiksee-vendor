import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/withdraw/domain/models/withdraw_model.dart';
import 'package:quiksee/features/withdraw/domain/repositories/withdraw_repository_interfaec.dart';
import 'package:quiksee/features/withdraw/domain/services/withdraw_service_interface.dart';

class WithdrawService implements WithdrawServiceInterface {
  final WithdrawRepositoryInterface withdrawRepoInterface;
  WithdrawService({required this.withdrawRepoInterface});


  @override
  Future<Response> sendWithdrawRequest({String? amount, String? note}) async {
    Response response = await withdrawRepoInterface.sendWithdrawRequest(amount: amount, note: note);
    if (response.statusCode != 200) {
      ApiChecker.checkApi(response);
    }
    return response;
  }

  @override
  Future getWithdrawList({String? startDate, String? endDate, int? offset, String? type}) async {
    Response response = await withdrawRepoInterface.getWithdrawList(startDate: startDate, endDate: endDate, offset: offset, type: type);
    if (response.body != null && response.statusCode == 200) {
      return WithdrawModel.fromJson(response.body).withdraws ?? [];
    }
    ApiChecker.checkApi(response);
    return [];
  }

}