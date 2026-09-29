import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_loader_widget.dart';

/// dismiss still works after a second order / overlapping Get routes.
class OverlayLoaderHelper {
  static bool _showing = false;

  static void show() {
    if (_showing) return;
    if (Get.isDialogOpen == true) {
      return;
    }
    _showing = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: const Center(child: QuikseeLoaderWidget()),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      _showing = false;
    });
  }

  static void hide() {
    _showing = false;
    _popIfOpen();
  }

  static void forceHide() {
    _showing = false;
    _popIfOpen();
  }

  static void _popIfOpen() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
