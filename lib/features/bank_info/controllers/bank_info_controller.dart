import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/business_analytics_filter_data.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/response_model.dart';
import 'package:quiksee_vendor_app/features/bank_info/domain/services/bank_info_service_interface.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class BankInfoController extends ChangeNotifier {
  final BankInfoServiceInterface bankInfoServiceInterface;

  BankInfoController({required this.bankInfoServiceInterface});

  ProfileInfoModel? _bankInfo;
  List<double?>? _userEarnings;
  List<double?>? _userCommissions;
  ProfileInfoModel? get bankInfo => _bankInfo;
  List<double?>? get userEarnings => _userEarnings;
  List<double?>? get userCommissions => _userCommissions;

  String? _analyticsName = '';
  String? get analyticsName => _analyticsName;
  int _analyticsIndex = 0;
  int get analyticsIndex => _analyticsIndex;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isChartLoading = false;
  bool get isChartLoading => _isChartLoading;
  BusinessAnalyticsFilterDataModel? _businessAnalyticsFilterData;
  BusinessAnalyticsFilterDataModel? get businessAnalyticsFilterData => _businessAnalyticsFilterData;
  int _revenueFilterTypeIndex = 0;
  int get revenueFilterTypeIndex => _revenueFilterTypeIndex;
  String? _revenueFilterType = '';
  String? get revenueFilterType => _revenueFilterType;

  bool _showWarning = true;
  bool get showWarning => _showWarning;

  void setRevenueFilterName(BuildContext context, String? filterName, bool notify) {
    _revenueFilterType = filterName;
    String? callingString;
    if(_revenueFilterType == 'this_year'){
      callingString = 'yearEarn';
    }else if(_revenueFilterType == 'this_month'){
      callingString = 'MonthEarn';
    }else if(_revenueFilterType == 'this_week'){
      callingString = 'WeekEarn';
    }
   getDashboardRevenueData(context, callingString);
    if(notify) {
      notifyListeners();
    }
  }

  void setRevenueFilterType(int index, bool notify) {
    _revenueFilterTypeIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  List<dynamic> _earnings = [];
  List<dynamic> get earnings => _earnings;
  List<dynamic> _commission = [];
  List<dynamic> get commission => _commission;
  double _lim = 0.0;
  double get lim => _lim;

  Future<void> getDashboardRevenueData(BuildContext context, String? filterType) async {
    final bool hadCache = _userEarnings != null && _userCommissions != null;
    _isChartLoading = true;

    if (!hadCache) {
      notifyListeners();
    }

    try {
      final ApiResponse apiResponse =
          await bankInfoServiceInterface.chartFilterData(filterType);
      if (apiResponse.response != null &&
          apiResponse.response!.data != null &&
          apiResponse.response!.statusCode == 200) {
        _userEarnings = [];
        _userCommissions = [];
        _earnings = [];
        _commission = [];
        _earnings.addAll(apiResponse.response!.data['seller_earn']);
        _commission.addAll(apiResponse.response!.data['commission_earn']);
        for (dynamic data in _earnings) {
          try {
            _userEarnings!.add(data.toDouble());
          } catch (e) {
            _userEarnings!.add(double.parse(data.toString()));
          }
        }
        for (dynamic data in _commission) {
          try {
            _userCommissions!.add(data.toDouble());
          } catch (e) {
            _userCommissions!.add(double.parse(data.toString()));
          }
        }
        _userEarnings!.insert(0, 0);
        _userCommissions!.insert(0, 0);
        final List<double?> counts = List<double?>.from(_userEarnings!);
        final List<double?> comCounts = List<double?>.from(_userCommissions!);
        counts.sort();
        comCounts.sort();
        final double max = counts.isNotEmpty ? counts[counts.length - 1] ?? 0 : 0;
        final double maxx =
            comCounts.isNotEmpty ? comCounts[comCounts.length - 1] ?? 0 : 0;
        _lim = max > maxx ? max : maxx;
      } else {

        if (!hadCache) {
          _userEarnings = [];
          _userCommissions = [];
          _earnings = [];
          _commission = [];
          _lim = 0;
        }
        ApiChecker.checkApi(apiResponse);
      }
    } catch (_) {
      if (!hadCache) {
        _userEarnings = [];
        _userCommissions = [];
        _earnings = [];
        _commission = [];
        _lim = 0;
      }
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  Future<void> getBankInfo(BuildContext context) async {
    try {
      _bankInfo = await bankInfoServiceInterface.getBankList();
    } catch (_) {}
    notifyListeners();
  }

  Future<ResponseModel?> updateBankInfo(BuildContext context,ProfileInfoModel updateUserModel, ProfileBody seller, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final responseModel =
          await bankInfoServiceInterface.updateBank(updateUserModel, seller, token);
      if (responseModel.isSuccess) {
        await getBankInfo(context);
        if (context.mounted) {
          try {
            await Provider.of<ProfileController>(context, listen: false).getSellerInfo();
          } catch (_) {}
        }
      }
      return responseModel;
    } catch (e) {
      return ResponseModel(false, e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getBankToken() {
    return bankInfoServiceInterface.getBankToken();
  }

  void setAnalyticsFilterName(
    BuildContext context,
    String? filterName,
    bool notify, {
    bool fetch = true,
  }) {
    _analyticsName = filterName;
    if (fetch) {
      getAnalyticsFilterData(context, _analyticsName);
    }
    if (notify) {
      notifyListeners();
    }
  }

  void setAnalyticsFilterType(int index, bool notify) {
    _analyticsIndex = index;
    if(notify) {
      _businessAnalyticsFilterData = null;
      notifyListeners();
    }
  }

  Future<void> getAnalyticsFilterData(BuildContext context, String? type) async {
    _isLoading = true;
    ApiResponse response = await bankInfoServiceInterface.getOrderFilterData(type);
    if(response.response != null && response.response!.statusCode == 200) {
      _businessAnalyticsFilterData = BusinessAnalyticsFilterDataModel.fromJson(response.response!.data);
      _isLoading = false;
    }else {
      _isLoading = false;
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }

  void setWarningValue(bool showWarning, {bool isUpdate = false}) {
    _showWarning = showWarning;
    if(isUpdate) {
      notifyListeners();
    }
  }

  void clearSessionData({bool notify = true}) {
    _bankInfo = null;
    _userEarnings = null;
    _userCommissions = null;
    _earnings = [];
    _commission = [];
    _lim = 0.0;
    _businessAnalyticsFilterData = null;
    _analyticsName = '';
    _analyticsIndex = 0;
    _revenueFilterTypeIndex = 0;
    _revenueFilterType = '';
    _isLoading = false;
    _isChartLoading = false;
    if (notify) {
      notifyListeners();
    }
  }

}
