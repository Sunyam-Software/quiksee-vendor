import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/controllers/dynamic_field_controller.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/domain/models/dynamic_field_models.dart';
import 'package:quiksee_vendor_app/helper/date_converter.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class DynamicFieldsFormWidget extends StatelessWidget {
  const DynamicFieldsFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicFieldController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.definitions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: controller.definitions
              .map((def) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeDefault,
                    ),
                    child: _buildField(context, controller, def),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildField(
    BuildContext context,
    DynamicFieldController controller,
    DynamicFieldDefinition def,
  ) {
    switch (def.fieldType) {
      case 'textarea':
        return QuikseeTextFieldWidget(
          labelText: def.label,
          hintText: def.label,
          controller: controller.controllerFor(def.fieldKey),
          maxLine: 4,
          onChanged: (value) => controller.setValue(def.fieldKey, value),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          value: def.options.contains(controller.getPayload()[def.fieldKey])
              ? controller.getPayload()[def.fieldKey]
              : null,
          decoration: InputDecoration(
            labelText: def.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
          ),
          items: def.options
              .map((option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: robotoRegular),
                  ))
              .toList(),
          onChanged: (value) => controller.setValue(def.fieldKey, value ?? ''),
        );
      case 'checkbox':
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(def.label, style: robotoMedium),
          value: controller.isChecked(def.fieldKey),
          onChanged: (value) =>
              controller.setCheckbox(def.fieldKey, value == true),
        );
      case 'number':
        return QuikseeTextFieldWidget(
          labelText: def.label,
          hintText: def.label,
          controller: controller.controllerFor(def.fieldKey),
          textInputType: TextInputType.number,
          onChanged: (value) => controller.setValue(def.fieldKey, value),
        );
      case 'email':
        return QuikseeTextFieldWidget(
          labelText: def.label,
          hintText: def.label,
          controller: controller.controllerFor(def.fieldKey),
          textInputType: TextInputType.emailAddress,
          onChanged: (value) => controller.setValue(def.fieldKey, value),
        );
      case 'url':
        return QuikseeTextFieldWidget(
          labelText: def.label,
          hintText: def.label,
          controller: controller.controllerFor(def.fieldKey),
          textInputType: TextInputType.url,
          onChanged: (value) => controller.setValue(def.fieldKey, value),
        );
      case 'date':
        final date = controller.dateFor(def.fieldKey);
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.setDate(def.fieldKey, picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: def.label,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
              ),
            ),
            child: Text(
              date != null
                  ? DateConverter.localDateToIsoStringDate(date)
                  : 'Select date',
              style: robotoRegular,
            ),
          ),
        );
      default:
        return QuikseeTextFieldWidget(
          labelText: def.label,
          hintText: def.label,
          controller: controller.controllerFor(def.fieldKey),
          onChanged: (value) => controller.setValue(def.fieldKey, value),
        );
    }
  }
}
