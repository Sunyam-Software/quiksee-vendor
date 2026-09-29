import 'package:get/get.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/domain/repositories/order_transfer_repository.dart';

/// Keeps Order Transfer DI alive for the whole app session.
/// Root crash was: controller fenix-recreated after SmartManagement dispose while
/// [OrderTransferRepository] was gone → red "OrderTransferRepository not found"
/// on Order Information / wait timer. Always call [ensure] before find/GetBuilder.
class OrderTransferBinding {
  OrderTransferBinding._();

  static bool ensure() {
    try {
      if (!Get.isRegistered<ApiClient>()) {
        return false;
      }
      _ensureRepo();
      _ensureController();
      Get.find<OrderTransferController>();
      return true;
    } catch (_) {
      return _forceRebind();
    }
  }

  static void _ensureRepo() {
    if (Get.isRegistered<OrderTransferRepository>()) return;
    Get.put(
      OrderTransferRepository(apiClient: Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _ensureController() {
    if (Get.isRegistered<OrderTransferController>()) return;
    Get.put(
      OrderTransferController(
        repository: Get.find<OrderTransferRepository>(),
      ),
      permanent: true,
    );
  }

  /// Last resort after a broken fenix / half-deleted binding.
  static bool _forceRebind() {
    try {
      if (!Get.isRegistered<ApiClient>()) return false;
      if (Get.isRegistered<OrderTransferController>()) {
        Get.delete<OrderTransferController>(force: true);
      }
      if (Get.isRegistered<OrderTransferRepository>()) {
        Get.delete<OrderTransferRepository>(force: true);
      }
      Get.put(
        OrderTransferRepository(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
      Get.put(
        OrderTransferController(
          repository: Get.find<OrderTransferRepository>(),
        ),
        permanent: true,
      );
      Get.find<OrderTransferController>();
      return true;
    } catch (_) {
      return false;
    }
  }
}
