import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/controllers/tax_settlement_controller.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/models/tax_settlement_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class TaxSettlementDetailScreen extends StatefulWidget {
  final int settlementId;

  const TaxSettlementDetailScreen({super.key, required this.settlementId});

  @override
  State<TaxSettlementDetailScreen> createState() => _TaxSettlementDetailScreenState();
}

class _TaxSettlementDetailScreenState extends State<TaxSettlementDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<TaxSettlementController>(context, listen: false);
      await controller.loadDetails(widget.settlementId);
      final pending = controller.selected?.pendingPayment ?? 0;
      if (pending > 0) {
        _amountController.text = pending.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _receiptPath = result.files.single.path);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final controller = Provider.of<TaxSettlementController>(context, listen: false);
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_amount', context) ?? 'Enter amount', context);
      return;
    }

    final ok = await controller.markPaid(
      id: widget.settlementId,
      amount: amount,
      reference: _referenceController.text.trim(),
      note: _noteController.text.trim(),
      receiptPath: _receiptPath,
    );

    if (ok && mounted) {
      showQuikseeSnackBarWidget(
        getTranslated('tax_payment_marked_successfully', context) ?? 'Tax payment marked successfully',
        context,
        sanckBarType: SnackBarType.success,
      );
    }
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
          if (controller.isLoading && controller.selected == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = controller.selected;
          if (item == null) {
            return Center(child: Text(getTranslated('no_data_found', context) ?? 'No data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.periodLabel ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _InfoRow(label: getTranslated('tax_collected', context) ?? 'Tax Collected', value: PriceConverter.convertPrice(context, item.taxCollected)),
                _InfoRow(label: getTranslated('online', context) ?? 'Online', value: PriceConverter.convertPrice(context, item.onlineTaxCollected)),
                _InfoRow(label: getTranslated('cod', context) ?? 'COD', value: PriceConverter.convertPrice(context, item.codTaxCollected)),
                _InfoRow(label: getTranslated('remitted', context) ?? 'Remitted', value: PriceConverter.convertPrice(context, item.amountRemitted)),
                _InfoRow(label: getTranslated('paid', context) ?? 'Paid', value: PriceConverter.convertPrice(context, item.amountPaid)),
                _InfoRow(label: getTranslated('pending_remittance', context) ?? 'Pending Remittance', value: PriceConverter.convertPrice(context, item.pendingRemittance)),
                _InfoRow(label: getTranslated('pending_tax_payment', context) ?? 'Pending Payment', value: PriceConverter.convertPrice(context, item.pendingPayment)),
                _InfoRow(label: getTranslated('status', context) ?? 'Status', value: item.status ?? ''),
                if (item.canMarkPaid && item.status != 'cleared') ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Text(getTranslated('mark_tax_paid', context) ?? 'Mark Tax Paid', style: robotoMedium),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    hintText: getTranslated('amount', context) ?? 'Amount',
                    controller: _amountController,
                    textInputType: TextInputType.number,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    hintText: getTranslated('reference', context) ?? 'Reference / Challan',
                    controller: _referenceController,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    hintText: getTranslated('note', context) ?? 'Note',
                    controller: _noteController,
                    maxLine: 2,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  OutlinedButton.icon(
                    onPressed: _pickReceipt,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_receiptPath == null
                        ? (getTranslated('upload_receipt', context) ?? 'Upload receipt (optional)')
                        : _receiptPath!.split('/').last),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  QuikseeButtonWidget(
                    btnTxt: getTranslated('mark_paid', context) ?? 'Mark Paid',
                    onTap: controller.isLoading ? null : () => _submit(context),
                  ),
                ] else if (item.pendingRemittance > 0) ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Text(
                    getTranslated('online_tax_remittance_pending', context) ??
                        'Admin remittance pending for online order tax.',
                    style: robotoRegular.copyWith(color: Colors.orange),
                  ),
                ],
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(getTranslated('activity_log', context) ?? 'Activity Log', style: robotoMedium),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                if (item.logs.isEmpty)
                  Text(getTranslated('no_data_found', context) ?? 'No data found')
                else
                  ...item.logs.map((log) => _LogTile(log: log)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
          Text(value, style: robotoMedium),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final TaxSettlementLogModel log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: ListTile(
        title: Text(log.action ?? '', style: robotoMedium),
        subtitle: Text('${log.createdAt ?? ''}${log.reference != null ? '\n${log.reference}' : ''}'),
        trailing: Text(PriceConverter.convertPrice(context, log.amount)),
      ),
    );
  }
}
