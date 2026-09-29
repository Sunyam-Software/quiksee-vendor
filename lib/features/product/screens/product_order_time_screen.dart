import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class _OrderTimeSlot {
  TimeOfDay open;
  TimeOfDay close;

  _OrderTimeSlot({required this.open, required this.close});
}

class ProductOrderTimeScreen extends StatefulWidget {
  final int productId;
  final String? productName;

  const ProductOrderTimeScreen({
    super.key,
    required this.productId,
    this.productName,
  });

  @override
  State<ProductOrderTimeScreen> createState() => _ProductOrderTimeScreenState();
}

class _ProductOrderTimeScreenState extends State<ProductOrderTimeScreen> {
  static const int _maxSlots = 5;
  static const List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  bool _supported = true;
  String? _productName;
  final List<_OrderTimeSlot> _slots = [];
  final Set<String> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _productName = widget.productName;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final ApiResponse response =
        await Provider.of<ProductController>(context, listen: false)
            .fetchProductAvailabilityHours(widget.productId);

    if (!mounted) return;

    if (response.response?.statusCode == 200 && response.response?.data is Map) {
      final data = Map<String, dynamic>.from(response.response!.data as Map);
      _supported = data['supported'] != false;
      _productName = data['product_name']?.toString() ?? _productName;
      _enabled = data['availability_hours_enabled'] == true ||
          data['availability_hours_enabled'] == 1;

      _selectedDays.clear();
      if (data['days'] is List) {
        for (final day in data['days'] as List) {
          final value = day is Map ? day['day']?.toString() : day?.toString();
          if (value != null && _days.contains(value.toLowerCase())) {
            _selectedDays.add(value.toLowerCase());
          }
        }
      }

      _slots.clear();
      if (data['slots'] is List) {
        for (final slot in data['slots'] as List) {
          if (slot is! Map) continue;
          final open = _parseTime(slot['open']);
          final close = _parseTime(slot['close']);
          if (open != null && close != null) {
            _slots.add(_OrderTimeSlot(open: open, close: close));
          }
        }
      }
    } else {
      ApiChecker.checkApi(response);
    }

    if (_slots.isEmpty) {
      _slots.add(_OrderTimeSlot(
        open: const TimeOfDay(hour: 9, minute: 0),
        close: const TimeOfDay(hour: 12, minute: 0),
      ));
    }

    setState(() => _loading = false);
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.toString().trim());
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!).clamp(0, 23),
      minute: int.parse(match.group(2)!).clamp(0, 59),
    );
  }

  String _formatApiTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDisplay(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  Future<void> _pickTime(int index, {required bool isOpen}) async {
    final slot = _slots[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? slot.open : slot.close,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isOpen) {
        slot.open = picked;
      } else {
        slot.close = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    if (_enabled && _slots.isEmpty) {
      showQuikseeSnackBarWidget(
        getTranslated('add_time_slot', context) ?? 'Add time slot',
        context,
      );
      return;
    }

    setState(() => _saving = true);

    final Map<String, dynamic> body = {
      'availability_hours_enabled': _enabled,
      'availability_days': _enabled ? _selectedDays.toList() : <String>[],
      'availability_slots': _enabled
          ? _slots
              .map((slot) => {
                    'open': _formatApiTime(slot.open),
                    'close': _formatApiTime(slot.close),
                  })
              .toList()
          : <Map<String, String>>[],
    };

    final ApiResponse response =
        await Provider.of<ProductController>(context, listen: false)
            .saveProductAvailabilityHours(widget.productId, body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (response.response?.statusCode == 200) {

      bool savedEnabled = _enabled;
      final dynamic data = response.response?.data;
      if (data is Map && data['availability_hours'] is Map) {
        savedEnabled = (data['availability_hours'] as Map)['enabled'] == true;
      }

      showQuikseeSnackBarWidget(
        savedEnabled
            ? (getTranslated('product_order_time_updated_successfully', context) ??
                'Order time updated')
            : (getTranslated('product_order_time_removed', context) ??
                'Order time removed, item follows store hours now'),
        context,
        isError: false,
        isToaster: true,
        sanckBarType: SnackBarType.success,
      );
      Navigator.pop(context, savedEnabled);
    } else {
      ApiChecker.checkApi(response);
    }
  }

  String _dayLabel(String day) =>
      getTranslated(day, context) ??
      '${day[0].toUpperCase()}${day.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: getTranslated('product_order_time', context) ?? 'Order time',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_supported
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Text(
                      getTranslated('feature_not_available', context) ??
                          'This feature is not available yet',
                      textAlign: TextAlign.center,
                      style: robotoRegular,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        children: [
                          if (_productName != null && _productName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall,
                              ),
                              child: Text(_productName!, style: robotoBold),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusDefault),
                              border: Border.all(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                getTranslated('limit_order_time', context) ??
                                    'Limit order time for this item',
                                style: robotoMedium,
                              ),
                              subtitle: Text(
                                _enabled
                                    ? (getTranslated('product_order_time_hint', context) ??
                                        'Orders only inside these times')
                                    : (getTranslated('same_as_store_hours', context) ??
                                        'Off = same as store hours'),
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              value: _enabled,
                              onChanged: (value) => setState(() => _enabled = value),
                            ),
                          ),
                          if (_enabled) ...[
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                            Text(
                              getTranslated('order_time', context) ?? 'Order time',
                              style: robotoBold,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            ...List.generate(_slots.length, (index) {
                              final slot = _slots[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Dimensions.paddingSizeSmall,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _pickTime(index, isOpen: true),
                                        child: Text(
                                          '${getTranslated('from', context) ?? 'From'}: ${_formatDisplay(slot.open)}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _pickTime(index, isOpen: false),
                                        child: Text(
                                          '${getTranslated('to', context) ?? 'To'}: ${_formatDisplay(slot.close)}',
                                        ),
                                      ),
                                    ),
                                    if (_slots.length > 1)
                                      IconButton(
                                        onPressed: () =>
                                            setState(() => _slots.removeAt(index)),
                                        icon: const Icon(Icons.remove_circle_outline),
                                        tooltip:
                                            getTranslated('remove', context) ?? 'Remove',
                                      ),
                                  ],
                                ),
                              );
                            }),
                            if (_slots.length < _maxSlots)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _slots.add(_OrderTimeSlot(
                                    open: const TimeOfDay(hour: 17, minute: 0),
                                    close: const TimeOfDay(hour: 22, minute: 0),
                                  ));
                                }),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  getTranslated('add_time_slot', context) ??
                                      'Add time slot',
                                ),
                              ),
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                            Text(
                              getTranslated('available_days', context) ??
                                  'Available days',
                              style: robotoBold,
                            ),
                            Text(
                              getTranslated('leave_all_unchecked_for_every_day', context) ??
                                  'Select none for every day',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Wrap(
                              spacing: Dimensions.paddingSizeSmall,
                              runSpacing: Dimensions.paddingSizeExtraSmall,
                              children: _days.map((day) {
                                final selected = _selectedDays.contains(day);
                                return FilterChip(
                                  label: Text(_dayLabel(day)),
                                  selected: selected,
                                  onSelected: (value) => setState(() {
                                    if (value) {
                                      _selectedDays.add(day);
                                    } else {
                                      _selectedDays.remove(day);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: QuikseeButtonWidget(
                          isLoading: _saving,
                          btnTxt: getTranslated('save', context) ?? 'Save',
                          onTap: _saving ? null : _save,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
