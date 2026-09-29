import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';

class PriceConverter {
  /// Round money to [decimal] places.
  static double _roundToDecimal(double value, int decimal) {
    final places = decimal < 0 ? 0 : decimal;
    final mod = pow(10.0, places).toDouble();
    return (value * mod).round() / mod;
  }

  static String convertPrice(double? price, {double? discount, String? discountType}) {
    double amount = price ?? 0;
    if (discount != null && discountType != null) {
      if (discountType == 'amount' || discountType == 'flat') {
        amount = amount - discount;
      } else if (discountType == 'percent' || discountType == 'percentage') {
        amount = amount - ((discount / 100) * amount);
      }
    }

    try {
      final splash = Get.find<SplashController>();
      final config = splash.configModel;
      final currency = splash.myCurrency;
      final usd = splash.usdCurrency;

      if (config == null || currency == null) {
        return amount.toStringAsFixed(2);
      }

      final singleCurrency = config.currencyModel == 'single_currency';
      final inRight = config.currencySymbolPosition == 'right';
      final decimal = max(2, config.decimalPointSettings ?? 2);
      final exchangeRate = currency.exchangeRate ?? 1;
      final usdRate = usd?.exchangeRate ?? 1;

      double finalPrice = singleCurrency
          ? amount
          : amount * exchangeRate * (1 / (usdRate == 0 ? 1 : usdRate));

      finalPrice = _roundToDecimal(finalPrice, decimal);

      final formatted = finalPrice.toStringAsFixed(decimal).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );

      final symbol = currency.symbol ?? '';
      return '${inRight ? '' : symbol}$formatted${inRight ? symbol : ''}';
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  static String convertPriceWithoutSymbol(
    BuildContext context,
    double? price, {
    double? discount,
    String? discountType,
  }) {
    double amount = price ?? 0;
    if (discount != null && discountType != null) {
      if (discountType == 'amount' || discountType == 'flat') {
        amount = amount - discount;
      } else if (discountType == 'percent' || discountType == 'percentage') {
        amount = amount - ((discount / 100) * amount);
      }
    }

    try {
      final splash = Get.find<SplashController>();
      final config = splash.configModel;
      final currency = splash.myCurrency;
      final usd = splash.usdCurrency;
      final decimal = max(2, config?.decimalPointSettings ?? 2);
      final singleCurrency = config?.currencyModel == 'single_currency';
      final exchangeRate = currency?.exchangeRate ?? 1;
      final usdRate = usd?.exchangeRate ?? 1;

      double finalPrice = singleCurrency
          ? amount
          : amount * exchangeRate * (1 / (usdRate == 0 ? 1 : usdRate));

      finalPrice = _roundToDecimal(finalPrice, decimal);
      return finalPrice.toStringAsFixed(decimal);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  static double convertWithDiscount(double price, double discount, String discountType) {
    if (discountType == 'amount') {
      price = price - discount;
    } else if (discountType == 'percent') {
      price = price - ((discount / 100) * price);
    }
    return price;
  }

  static double calculation(double amount, double discount, String type, int quantity) {
    double calculatedAmount = 0;
    if (type == 'amount') {
      calculatedAmount = discount * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (discount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(
    String price,
    String discount,
    String discountType,
  ) {
    return '$discount${discountType == 'percent' ? '%' : (Get.find<SplashController>().myCurrency?.symbol ?? '')} OFF';
  }
}
