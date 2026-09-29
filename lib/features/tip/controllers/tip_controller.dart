import 'package:get/get.dart';
import 'package:quiksee/features/tip/domain/models/tip_item_model.dart';
import 'package:quiksee/features/tip/domain/models/tip_summary_model.dart';
import 'package:quiksee/features/tip/domain/services/tip_service_interface.dart';

class TipController extends GetxController implements GetxService {
  final TipServiceInterface tipServiceInterface;

  TipController({required this.tipServiceInterface});

  TipSummaryModel? _summary;
  TipSummaryModel? get summary => _summary;
  bool get isTipSystemEnabled => _summary?.isEnabled == true;

  List<TipItemModel> _tips = [];
  List<TipItemModel> get tips => _tips;

  TipItemModel? _orderTipDetail;
  TipItemModel? get orderTipDetail => _orderTipDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isListLoading = false;
  bool get isListLoading => _isListLoading;

  int _tipStatusFilterIndex = 0;
  int get tipStatusFilterIndex => _tipStatusFilterIndex;

  int? _totalSize;
  int? get totalSize => _totalSize;

  int _offset = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  static const List<String> _statusFilters = ['all', 'pending', 'earned'];
  String get _currentStatus => _statusFilters[_tipStatusFilterIndex];

  Future<void> getTipSummary({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      update();
    }
    final result = await tipServiceInterface.getTipSummary();
    if (result is TipSummaryModel) {
      _summary = result;
    }
    _isLoading = false;
    update();
  }

  void setTipStatusFilter(int index) {
    if (_tipStatusFilterIndex == index) return;
    _tipStatusFilterIndex = index;
    getTipList(reload: true);
  }

  Future<void> getTipList({bool reload = true}) async {
    if (_isListLoading && !reload) return;

    if (reload) {
      _offset = 1;
      _tips = [];
      _hasMore = true;
    }
    if (!_hasMore && !reload) return;

    _isListLoading = true;
    update();

    try {
      final result = await tipServiceInterface.getTipList(
        offset: _offset,
        limit: 20,
        status: _currentStatus,
      );

      if (result is TipListModel) {
        _totalSize = result.totalSize;
        final newTips = result.tips ?? [];
        if (reload) {
          _tips = newTips;
        } else {
          _tips.addAll(newTips);
        }
        _hasMore = newTips.length >= (result.limit ?? 20) &&
            _tips.length < (result.totalSize ?? 0);
        if (newTips.isNotEmpty) _offset++;
      }
    } finally {
      _isListLoading = false;
      update();
    }
  }

  Future<TipItemModel?> getTipOrderDetail(int orderId) async {
    _isLoading = true;
    _orderTipDetail = null;
    update();

    final result = await tipServiceInterface.getTipOrderDetail(orderId: orderId);
    if (result is TipItemModel) {
      _orderTipDetail = result;
    }

    _isLoading = false;
    update();
    return _orderTipDetail;
  }
}
