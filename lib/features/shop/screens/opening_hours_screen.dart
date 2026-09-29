import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class _TimeSlot {
  TimeOfDay open;
  TimeOfDay close;

  _TimeSlot({
    this.open = const TimeOfDay(hour: 9, minute: 0),
    this.close = const TimeOfDay(hour: 12, minute: 0),
  });

  _TimeSlot copy() => _TimeSlot(open: open, close: close);
}

class _DayHours {
  bool closed;
  List<_TimeSlot> slots;

  _DayHours({
    this.closed = false,
    List<_TimeSlot>? slots,
  }) : slots = slots ??
            [
              _TimeSlot(
                open: const TimeOfDay(hour: 9, minute: 0),
                close: const TimeOfDay(hour: 21, minute: 0),
              ),
            ];
}

class OpeningHoursScreen extends StatefulWidget {
  const OpeningHoursScreen({super.key});

  @override
  State<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends State<OpeningHoursScreen> {
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
  bool _enabled = true;
  final Map<String, _DayHours> _hours = {};

  @override
  void initState() {
    super.initState();
    for (final day in _days) {
      _hours[day] = _DayHours();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ApiResponse response =
        await Provider.of<ShopController>(context, listen: false)
            .fetchOpeningHours();

    if (!mounted) return;

    if (response.response?.statusCode == 200 && response.response?.data is Map) {
      final data = Map<String, dynamic>.from(response.response!.data as Map);
      final raw = data['raw'] is Map
          ? Map<String, dynamic>.from(data['raw'] as Map)
          : <String, dynamic>{};
      final openingHours = data['opening_hours'] is Map
          ? Map<String, dynamic>.from(data['opening_hours'] as Map)
          : <String, dynamic>{};

      _enabled = raw['opening_hours_enabled'] == true ||
          openingHours['opening_hours_enabled'] == true;

      final weekly = openingHours['weekly_schedule'] is List
          ? openingHours['weekly_schedule'] as List
          : (raw['weekly_opening_hours'] is Map
              ? (raw['weekly_opening_hours'] as Map)
                  .entries
                  .map((e) => {
                        'day': e.key,
                        ...(e.value is Map
                            ? Map<String, dynamic>.from(e.value as Map)
                            : <String, dynamic>{}),
                      })
                  .toList()
              : <dynamic>[]);

      for (final item in weekly) {
        if (item is! Map) continue;
        final day = '${item['day'] ?? ''}'.toLowerCase();
        if (!_hours.containsKey(day)) continue;
        final closed = item['closed'] == true ||
            item['closed'] == 1 ||
            item['closed'] == '1';

        final slots = <_TimeSlot>[];
        final rawSlots = item['slots'];
        if (rawSlots is List && rawSlots.isNotEmpty) {
          for (final slot in rawSlots) {
            if (slot is! Map) continue;
            final open = _parseTime(slot['open'] ?? slot['open_display']);
            final close = _parseTime(slot['close'] ?? slot['close_display']);
            if (open != null && close != null) {
              slots.add(_TimeSlot(open: open, close: close));
            }
          }
        }

        if (slots.isEmpty && !closed) {
          final open = _parseTime(item['open'] ?? item['open_display']);
          final close = _parseTime(item['close'] ?? item['close_display']);
          if (open != null && close != null) {
            slots.add(_TimeSlot(open: open, close: close));
          }
        }

        if (slots.isEmpty) {
          slots.add(_TimeSlot());
        }

        _hours[day] = _DayHours(closed: closed, slots: slots);
      }
    } else {
      ApiChecker.checkApi(response);
    }

    setState(() => _loading = false);
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final match24 = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
    if (match24 != null &&
        !text.toLowerCase().contains('am') &&
        !text.toLowerCase().contains('pm')) {
      return TimeOfDay(
        hour: int.parse(match24.group(1)!).clamp(0, 23),
        minute: int.parse(match24.group(2)!).clamp(0, 59),
      );
    }

    final match12 =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])').firstMatch(text);
    if (match12 != null) {
      var hour = int.parse(match12.group(1)!);
      final minute = int.parse(match12.group(2)!);
      final period = match12.group(3)!.toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }
    return null;
  }

  String _formatApiTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDisplay(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Future<void> _pickSlotTime(String day, int index, {required bool isOpen}) async {
    final slot = _hours[day]!.slots[index];
    final current = isOpen ? slot.open : slot.close;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
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

  void _addSlot(String day) {
    final item = _hours[day]!;
    if (item.slots.length >= _maxSlots) return;
    setState(() {
      item.slots.add(_TimeSlot(
        open: const TimeOfDay(hour: 17, minute: 0),
        close: const TimeOfDay(hour: 22, minute: 0),
      ));
    });
  }

  void _removeSlot(String day, int index) {
    final item = _hours[day]!;
    if (item.slots.length <= 1) return;
    setState(() => item.slots.removeAt(index));
  }

  void _copyMondayToAll() {
    final monday = _hours['monday']!;
    setState(() {
      for (final day in _days) {
        if (day == 'monday') continue;
        _hours[day] = _DayHours(
          closed: monday.closed,
          slots: monday.slots.map((s) => s.copy()).toList(),
        );
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final Map<String, dynamic> body = {
      'opening_hours_enabled': _enabled,
    };

    if (_enabled) {
      final weekly = <String, dynamic>{};
      for (final day in _days) {
        final item = _hours[day]!;
        if (item.closed) {
          weekly[day] = {'closed': true, 'slots': <Map<String, String>>[]};
        } else {
          weekly[day] = {
            'closed': false,
            'open': _formatApiTime(item.slots.first.open),
            'close': _formatApiTime(item.slots.first.close),
            'slots': item.slots
                .map((s) => {
                      'open': _formatApiTime(s.open),
                      'close': _formatApiTime(s.close),
                    })
                .toList(),
          };
        }
      }
      body['weekly_hours'] = weekly;
    }

    final ApiResponse response =
        await Provider.of<ShopController>(context, listen: false)
            .saveOpeningHours(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (response.response?.statusCode == 200) {
      showQuikseeSnackBarWidget(
        getTranslated('status_updated_successfully', context) ??
            'Opening hours updated',
        context,
        isError: false,
        isToaster: true,
        sanckBarType: SnackBarType.success,
      );
      await _load();
    } else {
      ApiChecker.checkApi(response);
    }
  }

  String _dayLabel(BuildContext context, String day) {
    return getTranslated(day, context) ??
        '${day[0].toUpperCase()}${day.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: getTranslated('opening_hours', context) ?? 'Store Hours',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    children: [
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
                            color:
                                Theme.of(context).hintColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            getTranslated('enable_opening_hours', context) ??
                                'Enable weekly store hours',
                            style: robotoMedium,
                          ),
                          subtitle: Text(
                            _enabled
                                ? (getTranslated('multi_slot_hours_hint', context) ??
                                    'Add multiple slots e.g. lunch 9–12, dinner 5–10')
                                : (getTranslated('schedule_off_24h_hint', context) ??
                                    'Schedule off = open 24 hours'),
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
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _copyMondayToAll,
                            child: Text(
                              getTranslated('apply_monday_to_all_days', context) ??
                                  'Apply Monday to all days',
                            ),
                          ),
                        ),
                      ],
                      if (_enabled)
                        ..._days.map((day) {
                          final item = _hours[day]!;
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: Dimensions.paddingSizeSmall,
                            ),
                            padding:
                                const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusDefault),
                              border: Border.all(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dayLabel(context, day),
                                        style: robotoBold,
                                      ),
                                    ),
                                    Text(
                                      getTranslated('closed', context) ?? 'Closed',
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                      ),
                                    ),
                                    Switch(
                                      value: item.closed,
                                      onChanged: (value) {
                                        setState(() => item.closed = value);
                                      },
                                    ),
                                  ],
                                ),
                                if (!item.closed) ...[
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  ...List.generate(item.slots.length, (index) {
                                    final slot = item.slots[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: Dimensions.paddingSizeSmall,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _pickSlotTime(
                                                day,
                                                index,
                                                isOpen: true,
                                              ),
                                              child: Text(
                                                '${getTranslated('open', context) ?? 'Open'}: ${_formatDisplay(context, slot.open)}',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: Dimensions.paddingSizeSmall,
                                          ),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _pickSlotTime(
                                                day,
                                                index,
                                                isOpen: false,
                                              ),
                                              child: Text(
                                                '${getTranslated('close', context) ?? 'Close'}: ${_formatDisplay(context, slot.close)}',
                                              ),
                                            ),
                                          ),
                                          if (item.slots.length > 1)
                                            IconButton(
                                              onPressed: () =>
                                                  _removeSlot(day, index),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              tooltip: getTranslated(
                                                    'remove',
                                                    context,
                                                  ) ??
                                                  'Remove',
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (item.slots.length < _maxSlots)
                                    TextButton.icon(
                                      onPressed: () => _addSlot(day),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(
                                        getTranslated('add_time_slot', context) ??
                                            'Add time slot',
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          );
                        }),
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
