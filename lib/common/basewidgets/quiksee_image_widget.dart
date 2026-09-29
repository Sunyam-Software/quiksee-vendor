import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:quiksee_vendor_app/helper/local_ssl_helper.dart';
import 'package:quiksee_vendor_app/utill/images.dart';

class QuikseeImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? placeholder;
  final String? cacheBuster;
  const QuikseeImageWidget({super.key, required this.image, this.height, this.width, this.fit = BoxFit.cover, this.placeholder = Images.placeholderImage, this.cacheBuster});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = resolveMediaUrl(image);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int? memW = width != null && width! > 0
        ? (width! * dpr).round().clamp(40, 800)
        : null;
    final int? memH = height != null && height! > 0
        ? (height! * dpr).round().clamp(40, 800)
        : null;
    return CachedNetworkImage(
      placeholder: (context, url) => Image.asset(placeholder?? Images.placeholderImage, height: height, width: width, fit: BoxFit.cover),
      imageUrl: imageUrl,
      cacheKey: cacheBuster != null && cacheBuster!.isNotEmpty ? '$image|$cacheBuster' : null,
      fit: fit,
      height: height,
      width: width,
      memCacheWidth: memW,
      memCacheHeight: memH,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      errorWidget: (c, o, s) => Image.asset(placeholder?? Images.placeholderImage, height: height, width: width, fit: BoxFit.cover),
    );
  }
}
