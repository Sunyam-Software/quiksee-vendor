import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class QuikseeSearchFieldWidget extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final String prefix;
  final Function iconPressed;
  final Function(String text)? onSubmit;
  final Function? onChanged;
  final Function? filterAction;
  final VoidCallback? onTap;
  final bool isFilter;
  const QuikseeSearchFieldWidget({super.key,
    required this.controller,
    required this.hint,
    required this.prefix,
    required this.iconPressed,
    this.onSubmit,
    this.onChanged,
    this.filterAction,
    this.onTap,
    this.isFilter = false,
  });

  @override
  State<QuikseeSearchFieldWidget> createState() => _CustomSearchFieldWidgetState();
}

class _CustomSearchFieldWidgetState extends State<QuikseeSearchFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: widget.controller,
            onTap: widget.onTap,
            textInputAction: TextInputAction.search,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 12),

              suffixIconConstraints: const BoxConstraints(
                minHeight: 48,
                minWidth: 60,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: IconButton(
                    tooltip: 'Search',
                    splashRadius: 22,
                    onPressed: () => widget.iconPressed(),
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            onSubmitted: widget.onSubmit,
            onChanged: widget.onChanged as void Function(String)?,
          ),
        ),
      ),

      widget.isFilter ? Padding(
        padding:  EdgeInsets.only(
          left :  Provider.of<LocalizationController>(context, listen: false).isLtr? Dimensions.paddingSizeSmall : 0,
          right :  Provider.of<LocalizationController>(context, listen: false).isLtr? 0 : Dimensions.paddingSizeSmall
        ),
        child: GestureDetector(
          onTap: widget.filterAction as void Function()?,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(Images.filterIcon, color: Colors.white),
          ),
        ),
      ) : const SizedBox(),
    ],);
  }
}