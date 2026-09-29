import 'package:flutter/material.dart';
import 'package:quiksee/features/chat/widgets/dialog_item_widget.dart';

class PopupBannerWidget {
  final BuildContext context;
  final List<String?> images;
  final bool fromNetwork;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry dotsAlignment;
  final Color dotsColorActive;
  final Color dotsColorInactive;
  final double dotsMarginBottom;
  final bool useDots;
  final bool autoSlide;
  final Widget? customCloseButton;
  final Duration slideChangeDuration;
  final Function(int) onClick;
  final int initIndex;
  final bool showDownloadButton;

  PopupBannerWidget(
      {required this.context,
      required this.images,
      this.fromNetwork = true,
      this.height,
      this.fit = BoxFit.fill,
      this.dotsAlignment = Alignment.bottomLeft,
      this.dotsColorActive = Colors.green,
      this.dotsColorInactive = Colors.grey,
      this.dotsMarginBottom = 10,
      this.useDots = true,
      this.autoSlide = true,
      this.slideChangeDuration = const Duration(seconds: 6),
      this.customCloseButton,
      required this.onClick,
      required this.initIndex,
        required this.showDownloadButton
      });

  Future<void> show() {
    return showDialog(
      context: context,
      builder: (context) => DialogItemWidget(
        context: context,
        images: images,
        fromNetwork: fromNetwork,
        fit: fit,
        height: height,
        dotsAlignment: dotsAlignment,
        dotsColorActive: dotsColorActive,
        dotsColorInactive: dotsColorInactive,
        dotsMarginBottom: dotsMarginBottom,
        useDots: useDots,
        autoSlide: autoSlide,
        initIndex: initIndex,
        customCloseButton: customCloseButton,
        onClick: (index) => onClick(index),
        showDownloadButton: showDownloadButton,
      ),
    );
  }
}
