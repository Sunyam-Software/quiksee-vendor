import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/controllers/tax_settlement_controller.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/models/tax_settlement_model.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/screens/tax_settlement_detail_screen.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class TaxSettlementScreen extends StatefulWidget {
  const TaxSettlementScreen({super.key});

  @override
  State<TaxSettlementScreen> createState() => _TaxSettlementScreenState();
}

class _TaxSettlementScreenState extends State<TaxSettlementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaxSettlementController>(context, listen: false).loadList(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: getTranslated('tax_settlement', context) ?? 'Tax Settlement',
        useQuikseeBrandedHeader: true,
      ),
      body: Consumer<TaxSettlementController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.listModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = controller.summary;
          final items = controller.listModel?.settlements ?? [];

          return RefreshIndicator(
            onRefresh: () => controller.loadList(reset: true),
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              children: [
                if (summary != null) _SummaryCards(summary: summary),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  getTranslated('monthly_tax_settlement', context) ?? 'Monthly Tax Settlement',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                if (items.isEmpty)
                  const NoDataScreen()
                else
                  ...items.map((item) => _SettlementCard(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final TaxSettlementSummaryModel summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              title: getTranslated('total_collected_tax', context) ?? 'Total Tax',
              amount: summary.totalTaxCollected,
              color: QuikseeBrandColors.forestGreen,
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _StatCard(
              title: getTranslated('pending_remittance', context) ?? 'Pending Remittance',
              amount: summary.pendingRemittance,
              color: Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: getTranslated('pending_tax_payment', context) ?? 'Pending Payment',
              amount: summary.pendingPayment,
              color: Colors.red,
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _StatCard(
              title: getTranslated('pending_clearance', context) ?? 'Pending Clearance',
              amount: summary.pendingClear,
              color: Colors.blue,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _StatCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: 4),
          Text(
            PriceConverter.convertPrice(context, amount),
            style: robotoBold.copyWith(color: color, fontSize: Dimensions.fontSizeLarge),
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final TaxSettlementModel item;

  const _SettlementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: ListTile(
        title: Text(item.periodLabel ?? '', style: robotoMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${getTranslated('tax', context) ?? 'Tax'}: ${PriceConverter.convertPrice(context, item.taxCollected)}'),
            Text('${getTranslated('status', context) ?? 'Status'}: ${item.status ?? ''}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaxSettlementDetailScreen(settlementId: item.id ?? 0),
          ),
        ),
      ),
    );
  }
}
