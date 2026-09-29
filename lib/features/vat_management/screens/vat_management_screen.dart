import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/screens/tax_settlement_screen.dart';
import 'package:quiksee_vendor_app/features/vat_management/screens/vat_report_screen.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/management_card_widget.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

class VatManagementScreen extends StatefulWidget {
  const VatManagementScreen({super.key});

  @override
  State<VatManagementScreen> createState() => _VatManagementScreenState();
}

class _VatManagementScreenState extends State<VatManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: QuikseeBrandColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: QuikseeAppBarWidget(
          title: getTranslated('reports', context),
          useQuikseeBrandedHeader: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeMedium,
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: Column(
            children: [
              ManagementCardWidget(
                name: getTranslated('tax_settlement', context) ?? 'Tax Settlement',
                description: getTranslated('tax_settlement_description', context) ??
                    'Pending tax, remittance, mark paid to government, and clearance.',
                image: Images.vatReportIcon,
                screenToRoute: const TaxSettlementScreen(),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              ManagementCardWidget(
                name: getGstTranslated('vat_report', context, fallback: 'GST report')!,
                description: getTranslated(
                      'see_online_gst_report',
                      context,
                    ) ??
                    'Online sales GST with CGST, SGST and tax included/excluded.',
                image: Images.vatReportIcon,
                screenToRoute: const VatReportScreen(orderType: 'default_type'),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              ManagementCardWidget(
                name: getTranslated('pos_sales_report', context) ?? 'POS Sales Report',
                description: getTranslated(
                      'see_pos_sales_and_gst_breakdown',
                      context,
                    ) ??
                    'See POS-only sales with SGST, CGST and GST breakdown.',
                image: Images.pos,
                screenToRoute: const VatReportScreen(orderType: 'POS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
