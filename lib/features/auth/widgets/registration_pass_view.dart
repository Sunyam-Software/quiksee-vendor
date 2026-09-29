import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/registration_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class RegistrationPassView extends StatelessWidget {
  const RegistrationPassView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RegistrationController>(
      builder: (controller) {
        return Padding(
          padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Wrap(children: [
            _rule('8_or_more_character'.tr, controller.lengthCheck),
            _rule('1_number'.tr, controller.numberCheck),
            _rule('1_upper_case'.tr, controller.uppercaseCheck),
            _rule('1_lower_case'.tr, controller.lowercaseCheck),
            _rule('1_special_character'.tr, controller.spatialCheck),
            _rule('no_spaces_in_password'.tr, controller.noSpaceCheck),
          ]),
        );
      },
    );
  }

  Widget _rule(String title, bool done) {
    return Padding(
      padding: EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check : Icons.clear,
            color: done ? Colors.green : Colors.red, size: 12),
        Text(title,
            style: rubikRegular.copyWith(
                color: done ? Colors.green : Colors.red, fontSize: 12)),
      ]),
    );
  }
}
