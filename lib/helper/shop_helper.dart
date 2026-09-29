import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee/features/chat/domain/enums/vacation_duration_type.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';


class ShopHelper {
  static bool isVacationActive(
      BuildContext context, {
        required DateTime? startDate,
        required DateTime? endDate,
        required VacationDurationType? vacationDurationType,
        required bool? vacationStatus,
        required bool isInHouseSeller,
      }) {
    final now = DateTime.now();

    if (isInHouseSeller) {
      return _checkInHouseVacation(context, now);
    } else {
      return _checkSellerVacation(
        startDate: startDate,
        endDate: endDate,
        currentDate: now,
        vacationDurationType: vacationDurationType,
        vacationStatus: vacationStatus,
      );
    }
  }

  static bool _checkInHouseVacation(BuildContext context, DateTime currentDate) {
    try {
      final configModel = Provider.of<SplashController>(context, listen: false).configModel;

      if (!(configModel?.inHouseVacationAdd?.status ?? false)) return false;

      if (configModel?.inHouseVacationAdd?.vacationDurationType == VacationDurationType.untilChange) {
        return true;
      }

      if(configModel?.inHouseVacationAdd?.vacationStartDate == null || configModel?.inHouseVacationAdd?.vacationEndDate == null) {
        return false;
      }

      return currentDate.isAfter(configModel!.inHouseVacationAdd!.vacationStartDate!) && currentDate.isBefore(configModel.inHouseVacationAdd!.vacationEndDate!);
    } catch (e) {
      debugPrint('Error checking in-house vacation: $e');
      return false;
    }
  }

  static bool _checkSellerVacation({ required DateTime? startDate, required DateTime? endDate, required DateTime currentDate, required VacationDurationType? vacationDurationType, required bool? vacationStatus}) {
    try {


      // Check normal vacation period
      if (!(vacationStatus ?? false)) return false;

      if (vacationDurationType == VacationDurationType.untilChange) {
        return true;
      }
      if (startDate == null || endDate == null) return false;


      return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
    } catch (e) {
      debugPrint('Error checking seller vacation: $e');
      return false;
    }
  }
}