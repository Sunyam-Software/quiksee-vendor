import 'package:flutter/material.dart';

class QuikseeDirectionalityWidget extends StatelessWidget {
  final Widget child;
  const QuikseeDirectionalityWidget({super.key,  required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }
}