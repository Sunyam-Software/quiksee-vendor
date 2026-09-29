import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/tip/domain/repositories/tip_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class TipRepository implements TipRepositoryInterface {
  final ApiClient apiClient;

  TipRepository({required this.apiClient});

  @override
  Future<Response> getTipSummary() {
    return apiClient.getData(AppConstants.tipSummaryUri);
  }

  @override
  Future<Response> getTipList(
      {required int offset, required int limit, String? status}) {
    final filter = status ?? 'all';
    return apiClient.getData(
      '${AppConstants.tipListUri}?offset=$offset&limit=$limit&status=$filter',
    );
  }

  @override
  Future<Response> getTipOrderDetail({required int orderId}) {
    return apiClient.getData('${AppConstants.tipOrderUri}?order_id=$orderId');
  }
}
