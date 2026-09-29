import 'package:flutter/material.dart';

class GlobalVisibilityController {

  static ScrollController scrollController = ScrollController();

  static final ValueNotifier<bool> isVisible = ValueNotifier(true);

  static double _lastOffset = 0;
  static VoidCallback? _listener;

  static void initListener() {

    _lastOffset = 0;

    _listener ??= () {
      final offset = scrollController.offset;

      if (offset > _lastOffset + 10) {

        if (isVisible.value) isVisible.value = false;
      } else if (offset < _lastOffset - 10) {

        if (!isVisible.value) isVisible.value = true;
      }

      _lastOffset = offset;
    };

    scrollController.addListener(_listener!);
  }

  static void disposeScrollController() {
    if (_listener != null) {
      scrollController.removeListener(_listener!);
      _listener = null;
    }

    scrollController.dispose();

    scrollController = ScrollController();
  }
}