import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class QuikseeSectionTitleWidget extends StatelessWidget {
  final String title;

  const QuikseeSectionTitleWidget(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: robotoBold.copyWith(
        color: QuikseeBrandColors.seeTextGreen,
        fontSize: 16,
      ),
    );
  }
}
