import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/clearance_sale/controllers/clearance_sale_controller.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class ClearanceProductPickListWidget extends StatelessWidget {
  const ClearanceProductPickListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClearanceSaleController>(
      builder: (context, controller, _) {
        if (controller.isProductSearchLoading && controller.sellerProductModel == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = controller.getPickableProducts();
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeLarge,
            ),
            child: Column(
              children: [
                Image.asset(Images.noProductImage, height: 45, width: 45),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  getTranslated('no_product_found', context)!,
                  textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          itemBuilder: (context, index) => _PickListItem(product: products[index]),
        );
      },
    );
  }
}

class _PickListItem extends StatelessWidget {
  final Product product;
  const _PickListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Provider.of<ClearanceSaleController>(context, listen: false)
            .setSelectedProduct(product, 0);
      },
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            width: .75,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  width: .75,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: QuikseeImageWidget(image: product.thumbnailFullUrl?.path ?? ''),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    PriceConverter.convertPrice(
                      context,
                      product.unitPrice,
                      discount: product.discount,
                      discountType: product.discountType,
                    ),
                    style: robotoBold.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}
