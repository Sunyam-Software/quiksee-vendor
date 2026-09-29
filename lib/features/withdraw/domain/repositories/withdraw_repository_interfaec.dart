

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/interface/repository_interface.dart';

abstract class WithdrawRepositoryInterface implements RepositoryInterface {

  Future<Response> sendWithdrawRequest({String? amount, String? note,});
  Future<Response> getWithdrawList({String? startDate, String? endDate, int? offset, String? type});
}