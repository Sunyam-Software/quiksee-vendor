
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quiksee/utill/dimensions.dart';

class QuikseeLoaderWidget extends StatelessWidget {
  const QuikseeLoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        ),
        child: const Center(
          child: SpinKitCircle(color: Colors.white, size: 50.0),
        ),
      ),
      ),
    );
  }
}
