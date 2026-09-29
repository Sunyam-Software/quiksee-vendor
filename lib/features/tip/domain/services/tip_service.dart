import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/tip/domain/models/tip_item_model.dart';
import 'package:quiksee/features/tip/domain/models/tip_summary_model.dart';
import 'package:quiksee/features/tip/domain/repositories/tip_repository_interface.dart';
import 'package:quiksee/features/tip/domain/services/tip_service_interface.dart';

class TipService implements TipServiceInterface {
  final TipRepositoryInterface tipRepositoryInterface;

  TipService({required this.tipRepositoryInterface});

  @override
  Future getTipSummary() async {
    final Response response = await tipRepositoryInterface.getTipSummary();
    if (response.body != null && response.statusCode == 200) {
      try {
        return TipSummaryModel.fromJson(response.body);
      } catch (e) {
        debugPrint('tip summary parse error: $e');
      }
    } else {
      ApiChecker.checkApi(response);
    }
  }

  @override
  Future getTipList(
      {required int offset, required int limit, String? status}) async {
    final Response response = await tipRepositoryInterface.getTipList(
      offset: offset,
      limit: limit,
      status: status,
    );
    if (response.body != null && response.statusCode == 200) {
      try {
        return TipListModel.fromJson(response.body);
      } catch (e) {
        debugPrint('tip list parse error: $e');
      }
    } else {
      ApiChecker.checkApi(response);
    }
  }

  @override
  Future getTipOrderDetail({required int orderId}) async {
    final Response response =
        await tipRepositoryInterface.getTipOrderDetail(orderId: orderId);
    if (response.body != null && response.statusCode == 200) {
      try {
        return TipItemModel.fromJson(response.body);
      } catch (e) {
        debugPrint('tip order detail parse error: $e');
      }
    } else {
      ApiChecker.checkApi(response);
    }
  }
}
