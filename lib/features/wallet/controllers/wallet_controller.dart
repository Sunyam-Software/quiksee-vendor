import 'dart:async';
import 'package:get/get.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/wallet/domain/models/delivery_wise_earned_model.dart' show DeliveryWiseEarnedModel, Orders, DistanceEarningSummary;
import 'package:quiksee/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:quiksee/features/withdraw/controllers/withdraw_controller.dart';
import 'package:quiksee/features/wallet/domain/models/deposited_model.dart';

class WalletController extends GetxController implements GetxService {
  final WalletServiceInterface walletServiceInterface;
  WalletController({required this.walletServiceInterface});

  List<Orders> _deliveryWiseEarned = [];
  List<Orders> get deliveryWiseEarned => _deliveryWiseEarned;
  DistanceEarningSummary? _distanceEarningSummary;
  DistanceEarningSummary? get distanceEarningSummary => _distanceEarningSummary;
  List<Deposit> _depositedList = [];
  List<Deposit> get depositedList => _depositedList;
   bool _isLoading = false;
   bool get isLoading => _isLoading;


   int _selectedItem = 0;
   int get selectedItem => _selectedItem;
  String _startDate = 'dd-mm-yyyy';
  String get startDate => _startDate;
  String _endDate = 'dd-mm-yyyy';
  String get endDate => _endDate;


   void selectedItemForFilter(int index,{bool fromTop = false, bool fromNotification = false}){
     if(fromTop){
       _startDate = 'dd-mm-yyyy';
       _endDate = 'dd-mm-yyyy';
     }

     _selectedItem = index;
     if(selectedItem == 0 ){
       getOrderWiseDeliveryCharge(startDate == "dd-mm-yyyy"? '' : startDate, endDate == "dd-mm-yyyy" ? '' : endDate, 1, '');
     } else if(selectedItem == 1 ){
       Get.find<WithdrawController>().getWithdrawList(startDate == "dd-mm-yyyy" ? '' :startDate, endDate == "dd-mm-yyyy"? '' : endDate, 1, 'withdrawn', fromNotification: fromNotification);
     }else if(selectedItem == 2 ){
       Get.find<WithdrawController>().getWithdrawList(startDate == "dd-mm-yyyy" ? '' :startDate, endDate == "dd-mm-yyyy" ? '' : endDate, 1, 'pending', fromNotification: fromNotification);
     }else if(selectedItem == 3 ){
       getDepositedList(startDate == "dd-mm-yyyy" ? '' : startDate, endDate == "dd-mm-yyyy" ? '' : endDate, 1, '', fromNotification: fromNotification);
     }
     update();
   }


  Future getOrderWiseDeliveryCharge(String startDate, String endDate, int offset, String type, {bool isUpdate = true}) async {
    _isLoading = true;
     if(isUpdate) {
       update();
    }
    final result = await walletServiceInterface.getDeliveryWiseEarned(startDate: startDate,endDate: endDate, offset: offset, type: type);
    if (result is DeliveryWiseEarnedModel) {
      _deliveryWiseEarned = result.orders ?? [];
      _distanceEarningSummary = result.distanceEarningSummary;
      await _enrichDeliveryEarnings();
    } else {
      _deliveryWiseEarned = [];
      _distanceEarningSummary = null;
    }

    _isLoading = false;
    update();
  }

  Future<void> _enrichDeliveryEarnings() async {
    if (!Get.isRegistered<DistancePaymentController>()) return;

    final needsEnrichment = _deliveryWiseEarned
        .where((o) => o.id != null && o.effectiveDeliveryEarning <= 0)
        .map((o) => o.id!)
        .toList();
    if (needsEnrichment.isEmpty) return;

    final distance = Get.find<DistancePaymentController>();
    await distance.enrichWalletOrderEarnings(needsEnrichment);

    for (final order in _deliveryWiseEarned) {
      if (order.id == null || order.effectiveDeliveryEarning > 0) continue;
      final info = distance.earningInfoForWalletOrder(order.id);
      if (info != null && info.displayEarning > 0) {
        order.deliveryDistanceInfo = info;
      }
    }
  }

  int _orderTypeFilterIndex = 0;
  int get orderTypeFilterIndex => _orderTypeFilterIndex;
  void setEarningFilterIndex(int index, {bool isUpdate = true}) {
    _orderTypeFilterIndex = index;
    if(_orderTypeFilterIndex == 0){
      getOrderWiseDeliveryCharge('', '', 1, '');
    }else if(_orderTypeFilterIndex == 1){
      getOrderWiseDeliveryCharge('', '', 1, 'TodayEarn');
    }
    else if(_orderTypeFilterIndex == 2){
      getOrderWiseDeliveryCharge('', '', 1, 'ThisWeekEarn');
    }
    else if(_orderTypeFilterIndex == 3){
      getOrderWiseDeliveryCharge('', '', 1, 'ThisMonthEarn');
    }

    if(isUpdate){
      update();
    }

  }


  Future<void> getDepositedList(String startDate, String endDate, int offset, String type, {bool reload = true,  bool fromNotification = false}) async {
    if(reload){
      _depositedList = [];
    }
    _isLoading = true;
    if(!fromNotification) {
      update();
    }
    final result = await walletServiceInterface.getDepositedList(
      startDate: startDate,
      endDate: endDate,
      offset: offset,
      type: type,
    );
    _depositedList = result ?? [];
    _isLoading = false;

    update();
  }


  Future <void> selectDate({String startDate = 'dd-mm-yyyy', String endDate = 'dd-mm-yyyy', bool isUpdate = true}) async {
    _startDate = startDate;
    _endDate = endDate;
    
    if(isUpdate) {
      update();
    }
  }

  void getPendingWithdrawList() {
    Get.find<WithdrawController>().getWithdrawList(startDate=="dd-mm-yyyy"? '' : startDate, endDate =="dd-mm-yyyy"? '' : endDate, 1, 'pending', reload: true);
  }

  String get _filterStartDate =>
      startDate == 'dd-mm-yyyy' ? '' : startDate;

  String get _filterEndDate => endDate == 'dd-mm-yyyy' ? '' : endDate;

  /// Reloads pending and/or withdrawn lists (e.g. after admin approve/deny).
  Future<void> refreshWithdrawLists({
    bool pending = true,
    bool withdrawn = true,
  }) async {
    final withdraw = Get.find<WithdrawController>();
    if (pending) {
      await withdraw.getWithdrawList(
        _filterStartDate,
        _filterEndDate,
        1,
        'pending',
        reload: true,
      );
    }
    if (withdrawn) {
      await withdraw.getWithdrawList(
        _filterStartDate,
        _filterEndDate,
        1,
        'withdrawn',
        reload: true,
      );
    }
    update();
  }

}
