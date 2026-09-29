import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';

class ShopBannerWidget extends StatelessWidget {
  final ShopController? resProvider;
  final bool fromBottom;
  final bool fromOffer;
  const ShopBannerWidget({super.key, this.resProvider, this.fromBottom = false, this.fromOffer = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width/3,
      child: fromBottom? QuikseeImageWidget(image: '${resProvider!.shopModel?.bottomBannerFullUrl?.path}'):
      fromOffer?QuikseeImageWidget(image: '${resProvider!.shopModel?.offerBannerFullUrl?.path}'):
        QuikseeImageWidget(image: '${resProvider!.shopModel?.bannerFullUrl?.path}'),
    );
  }
}
