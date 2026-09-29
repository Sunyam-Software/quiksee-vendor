import 'package:flutter/material.dart';
import 'package:get/get.dart';


class PermissionDialogWidget extends StatelessWidget {
  final bool isDenied;
  final Function onPressed;
  const PermissionDialogWidget({super.key,  required this.isDenied, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('alert'.tr),
      content: Text(isDenied ? 'you_denied'.tr : 'you_denied_forever'.tr),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      actions: [ElevatedButton(onPressed: onPressed as void Function()?,
        child: Text(isDenied ? 'ok'.tr : 'settings'.tr))]);
  }
}
