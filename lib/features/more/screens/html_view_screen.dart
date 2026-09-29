import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';

class HtmlViewScreen extends StatelessWidget {
  final BusinessPageModel? page;
  const HtmlViewScreen({super.key, required this.page});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: QuikseeBrandColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      body: Column(
        children: [
          QuikseeAppBarWidget(
            title: page?.title ?? '',
            useQuikseeBrandedHeader: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: SizedBox(
                        height: 70,
                        width: double.infinity,
                        child: QuikseeImageWidget(
                          fit: BoxFit.cover,
                          image: page?.bannerFullUrl?.path ?? "",
                        ),
                      ),
                    ),

                    Html(
                      style: {
                        "body": Style(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: FontSize.medium,
                        ),
                      },
                      data: page?.description ?? '',
                    ),

                  ],
                )
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
