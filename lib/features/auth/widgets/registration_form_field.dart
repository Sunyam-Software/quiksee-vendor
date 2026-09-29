import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class RegistrationFormField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType inputType;
  final bool isPassword;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  const RegistrationFormField({
    super.key,
    required this.hint,
    required this.controller,
    this.validator,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<RegistrationFormField> createState() => _RegistrationFormFieldState();
}

class _RegistrationFormFieldState extends State<RegistrationFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.inputType,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.isPassword ? _obscureText : false,
      onChanged: widget.onChanged,
      style: Theme.of(context).textTheme.displayMedium!.copyWith(
            color: Get.isDarkMode
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).primaryColorDark,
            fontSize: Dimensions.fontSizeDefault,
          ),
      cursorColor: Get.isDarkMode
          ? Theme.of(context).primaryColorLight
          : Theme.of(context).primaryColor,
      decoration: InputDecoration(
        counterText: '',
        contentPadding: EdgeInsets.symmetric(
          vertical: Get.context!.width <= 400 ? 14 : 16,
          horizontal: 16,
        ),
        hintText: widget.hint,
        hintStyle: rubikRegular.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).hintColor,
        ),
        errorStyle: rubikRegular.copyWith(
          color: Colors.red,
          fontSize: Dimensions.fontSizeSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
    );
  }
}
