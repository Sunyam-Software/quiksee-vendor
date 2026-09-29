import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class QuikseeBottomSheetWidget extends StatelessWidget {
  final String image;
  final String? title;
  final bool isProfile;
  final bool tintBrandGreen;
  final VoidCallback? onTap;

  const QuikseeBottomSheetWidget({
    super.key,
    required this.image,
    required this.title,
    this.isProfile = false,
    this.tintBrandGreen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: isProfile
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: QuikseeImageWidget(image: image),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(2),
                        child: tintBrandGreen
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  QuikseeBrandColors.seeTextGreen,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(image, fit: BoxFit.contain),
                              )
                            : Image.asset(image, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(height: 5),
              Text(
                title ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
