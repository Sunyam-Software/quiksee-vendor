import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/domain/models/dynamic_field_models.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class DynamicFieldsDisplayWidget extends StatelessWidget {
  final List<DynamicFieldDisplayRow> rows;

  const DynamicFieldsDisplayWidget({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.where((row) => row.hasValue).toList();
    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleRows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(
                bottom: Dimensions.paddingSizeSmall,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(row.label, style: robotoMedium),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.value,
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
