import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/interface/repository_interface.dart';

abstract class VatRepositoryInterface implements RepositoryInterface {

  Future<ApiResponse> getVatReport(int? limit, int? offset, String? startDate, String? endDate, {String? orderType});

}