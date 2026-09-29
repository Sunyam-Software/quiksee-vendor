import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/models/gst_tax_helper.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/models/vat_report_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class GstOrderTaxBreakdownWidget extends StatelessWidget {
  final List<TypeWiseTaxesList>? typeWiseTaxesList;
  final double? totalTax;

  const GstOrderTaxBreakdownWidget({
    super.key,
    required this.typeWiseTaxesList,
    required this.totalTax,
  });

  @override
  Widget build(BuildContext context) {
    final taxItems = <TaxItem>[];
    for (final group in typeWiseTaxesList ?? []) {
      for (final item in group.data ?? []) {
        taxItems.add(item);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QuikseeAssetImageWidget(
                Images.vatReportIcon,
                height: 22,
                width: 22,
                color: QuikseeBrandColors.seeTextGreen,
              ),
              const SizedBox(width: 8),
              Text(
                getTranslated('order_tax', context) ?? 'Order Tax',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: QuikseeBrandColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (taxItems.isNotEmpty)
            Row(
              children: [
                for (var i = 0; i < taxItems.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _TaxChip(tax: taxItems[i])),
                ],
              ],
            ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: QuikseeBrandColors.featuredSectionBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.currency_rupee_rounded,
                  size: 20,
                  color: QuikseeBrandColors.seeTextGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    getTranslated('total_gst_combined', context) ??
                        'Total GST (SGST + CGST)',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: QuikseeBrandColors.forestGreen,
                    ),
                  ),
                ),
                Text(
                  PriceConverter.convertPrice(context, totalTax ?? 0),
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: QuikseeBrandColors.seeTextGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxChip extends StatelessWidget {
  final TaxItem tax;

  const _TaxChip({required this.tax});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: QuikseeBrandColors.featuredSectionBackground.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: QuikseeBrandColors.seeTextGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GstTaxHelper.taxLineLabel(tax),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              fontSize: 11,
              color: QuikseeBrandColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            PriceConverter.convertPrice(context, tax.taxAmount ?? tax.totalAmount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(
              fontSize: 13,
              color: QuikseeBrandColors.seeTextGreen,
            ),
          ),
        ],
      ),
    );
  }
}
