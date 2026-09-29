import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class QuikseeCalendarWidget extends StatefulWidget {
  final PickerDateRange? initDateRange;
  final Function(PickerDateRange? dateRange) onSubmit;
  const QuikseeCalendarWidget({super.key, required this.onSubmit, this.initDateRange});

  @override
  State<QuikseeCalendarWidget> createState() => _QuikseeCalendarWidgetState();
}

class _QuikseeCalendarWidgetState extends State<QuikseeCalendarWidget> {

  @override
  Widget build(BuildContext context) {

    return GetBuilder<ThemeController>(
        builder: (themeController) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeDefault, vertical: MediaQuery.of(context).size.height/5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
              child: Container(
                color: themeController.darkTheme ? Theme.of(context).dividerColor : Theme.of(context).canvasColor,
                child: SfDateRangePicker(
                  confirmText: 'ok'.tr,
                  showActionButtons: true,
                  cancelText: 'cancel'.tr,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: (value){

                    if(value is PickerDateRange) {
                      widget.onSubmit(value);
                      Navigator.pop(context);
                    }

                  },
                  todayHighlightColor: themeController.darkTheme ? Colors.white : Theme.of(context).primaryColor,
                  selectionMode: DateRangePickerSelectionMode.range,
                  rangeSelectionColor: Theme.of(context).primaryColor.withValues(alpha:.50),
                  view: DateRangePickerView.month,

                  startRangeSelectionColor: Theme.of(context).colorScheme.primary,
                  endRangeSelectionColor: Theme.of(context).colorScheme.primary,
                  initialSelectedRange:  PickerDateRange(
                    widget.initDateRange?.startDate,
                    widget.initDateRange?.endDate,
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}
