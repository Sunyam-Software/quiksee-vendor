import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateConverter {

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
  }

  static String dateToTimeOnly(DateTime dateTime) {
    return DateFormat(_timeFormatter()).format(dateTime);
  }

  static String dateToDateAndTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String dateToDateAndTimeAm(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd ${_timeFormatter()}').format(dateTime);
  }

  static String dateTimeStringToDateTime(String dateTime) {
    return DateFormat('dd MMM yyyy  ${_timeFormatter()}').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static String dateTimeStringToDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static String formatDateToDayMonthYear(DateTime dateTime) {
    return DateFormat('dd-MMM-yyyy').format(dateTime.toLocal());
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateTime.parse(dateTime).toLocal();
  }

  static String isoStringToLocalString(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToDateTimeString(String dateTime) {
    return DateFormat('dd MMM yyyy  ${_timeFormatter()}').format(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(isoStringToLocalDate(dateTime));
  }

  static String stringToLocalDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(dateTime));
  }

  static String localDateToIsoString(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime);
  }

  static String convertTimeToTime(String time) {
    return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse(time));
  }


  static String convertStringTimeToDate(DateTime time) {
    return DateFormat('EEE \'at\' ${_timeFormatter()}').format(time.toLocal());
  }

  static String _timeFormatter() {
    return 'hh:mm a';
  }

  static String convertStringTimeToDateChatting(DateTime time) {
    return DateFormat('EEE \'at\' ${_timeFormatter()}').format(time.toLocal());
  }


  static String dateStringMonthYear(DateTime ? dateTime) {
    return DateFormat('d MMM,y').format(dateTime!);
  }

  static DateTime isoUtcStringToLocalTimeOnly(String dateTime) {
    return DateTime.parse(dateTime).toLocal();
  }

  static String isoStringToLocalDateAndTime(String dateTime) {
    return DateFormat('dd-MMM-yyyy hh:mm a').format(isoStringToLocalDate(dateTime));
  }

  static String convert24HourTimeTo12HourTimeWithDay(DateTime time, bool isToday) {
    if(isToday){
      return DateFormat('\'Today at\' ${_timeFormatter()}').format(time);
    }else{
      return DateFormat('\'Yesterday at\' ${_timeFormatter()}').format(time);
    }
  }

  static String convert24HourTimeTo12HourTime(DateTime time) {
    return DateFormat(_timeFormatter()).format(time);
  }


  static String convertFromMinute(int minMinute, int maxMinute) {
    int firstValue = minMinute;
    int secondValue = maxMinute;
    String type = 'min';
    if(minMinute >= 525600) {
      firstValue = (minMinute / 525600).floor();
      secondValue = (maxMinute / 525600).floor();
      type = 'year';
    }else if(minMinute >= 43200) {
      firstValue = (minMinute / 43200).floor();
      secondValue = (maxMinute / 43200).floor();
      type = 'month';
    }else if(minMinute >= 10080) {
      firstValue = (minMinute / 10080).floor();
      secondValue = (maxMinute / 10080).floor();
      type = 'week';
    }else if(minMinute >= 1440) {
      firstValue = (minMinute / 1440).floor();
      secondValue = (maxMinute / 1440).floor();
      type = 'day';
    }else if(minMinute >= 60) {
      firstValue = (minMinute / 60).floor();
      secondValue = (maxMinute / 60).floor();
      type = 'hour';
    }
    return '$firstValue-$secondValue ${type.tr}';
  }

  static String localDateToIsoStringAMPM(DateTime dateTime) {
    return DateFormat('${_timeFormatter()} | d-MMM-yyyy ').format(dateTime.toLocal());
  }
  static String localToIsoString(DateTime dateTime) {
    return DateFormat('d MMMM, yyyy ').format(dateTime.toLocal());
  }

  static int countDays(DateTime ? dateTime) {
    final startDate = dateTime!;
    final endDate = DateTime.now();
    final difference = endDate.difference(startDate).inDays;
    return difference;
  }

  static String getRelativeDateStatus(String inputDate, BuildContext context) {
    try {
      final parsedDate = DateTime.parse(inputDate);
      final currentDate = DateTime.now();
      final normalizedParsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final normalizedCurrentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final difference = normalizedCurrentDate.difference(normalizedParsedDate).inDays;

      if (difference == 0) {
        return 'today'.tr;
      } else if (difference == 1) {
        return 'yesterday'.tr;
      } else {
        return DateFormat('MM/dd/yyyy').format(parsedDate);
      }
    } catch (e) {
      return 'invalid_date'.tr; // Localized "Invalid date"
    }
  }

  static String compareDates(String inputDate) {
    DateTime currentDate = DateTime.now();
    DateTime parsedDate = DateTime.parse(inputDate);

    Duration difference = currentDate.difference(parsedDate);
    int hoursDifference = difference.inHours;
    int daysDifference = difference.inDays;

    if (hoursDifference < 1) {
      return DateFormat('hh:mm a').format(parsedDate);
    } else if (hoursDifference >= 1 && hoursDifference <= 23) {
      return 'hr_ago'.tr;
    } else if (daysDifference == 1) {
      return 'yesterday'.tr;
    } else if (daysDifference >= 2 && daysDifference <= 7) {
      return 'days_ago'.tr;
    } else {
      return DateFormat('MM/dd/yyyy').format(parsedDate);
    }
  }

  static String getLocalTimeWithAMPM(String dateTime) {
    return DateFormat('hh:mm a ').format(isoStringToLocalDate(dateTime));
  }


}