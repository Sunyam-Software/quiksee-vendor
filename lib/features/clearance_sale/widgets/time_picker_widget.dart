import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiksee_vendor_app/features/clearance_sale/widgets/show_quiksee_time_picker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class TimePickerWidget extends StatefulWidget {
  final String title;
  final String? time;
  final Function(String?) onTimeChanged;
  const TimePickerWidget({super.key, required this.title, required this.time, required this.onTimeChanged});

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {

  String formatTimeOfDay(TimeOfDay time) {
    final DateTime dateTime = DateTime(0, 1, 1, time.hour, time.minute);

    return DateFormat.jm().format(dateTime);
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () async {

        TimeOfDay? time = await showQuikseeTimePicker();

        if(time != null) {
          widget.onTimeChanged(formatTimeOfDay(time));
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),

        ),
        child: Row(children: [

          Text(
            widget.time != null ? widget.time!: getTranslated('pick_time', context)!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            maxLines: 1,
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall,),

          const Icon(Icons.access_time, size: 20),

        ]),
      ),
    );
  }
}