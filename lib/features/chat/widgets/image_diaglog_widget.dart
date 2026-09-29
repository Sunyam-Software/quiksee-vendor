import 'package:flutter/material.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';


class ImageDialogWidget extends StatelessWidget {
  final String imageUrl;
  const ImageDialogWidget({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
              QuikseeImageWidget(image: imageUrl, fit: BoxFit.contain,),
              Align(alignment: Alignment.centerRight,
                child: IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()))])])
    );
  }
}
