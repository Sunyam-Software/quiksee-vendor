import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/ai/controllers/ai_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/add_product_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
class TitleAndDescriptionWidget extends StatefulWidget {
  final AddProductController resProvider;
  final int index;
  final String langCode;
  const TitleAndDescriptionWidget({super.key, required this.resProvider, required  this.index, required  this.langCode});

  @override
  State<TitleAndDescriptionWidget> createState() => _TitleAndDescriptionWidgetState();
}

class _TitleAndDescriptionWidgetState extends State<TitleAndDescriptionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal : Dimensions.iconSizeSmall),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        if(Provider.of<SplashController>(context,listen: false).configModel?.isAiFeatureActive == 1)
        Consumer<AiController>(
          builder: (context, aiController, child){
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      if(widget.resProvider.titleControllerList[widget.index].text.isEmpty) {
                        showQuikseeSnackBarWidget('${getTranslated('product_name_required', context)}', context);
                      }else{
                        aiController.generateTitle(
                          title: widget.resProvider.titleControllerList[widget.index].text.trim(),
                          langCode: widget.langCode,
                        ).then((value) {
                          if(aiController.titleModel != null) {
                            widget.resProvider.titleControllerList[widget.index].text = aiController.titleModel?.data ?? '';
                            setState(() {});
                          }
                        });
                      }
                    },
                    child: !aiController.titleLoading ? Icon(Icons.auto_awesome, color: Colors.blue) : Shimmer.fromColors(
                      baseColor: Theme.of(context).primaryColor,
                      highlightColor: Colors.grey[100]!,
                      child: Row(children: [
                        Icon(Icons.auto_awesome, color: Colors.blue),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Text(getTranslated('generating', context) ?? '', style: robotoBold.copyWith(color: Colors.blue)),
                      ]),
                    ),
                  ),
                ],
              );
            }
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          QuikseeTextFieldWidget(
            formProduct: true,
            textInputAction: TextInputAction.next,
            controller: TextEditingController(text: widget.resProvider.titleControllerList[widget.index].text),
            textInputType: TextInputType.name,
            required: true,
            hintText: getTranslated('product_name', context),
            border: true,
            borderColor: Theme.of(context).primaryColor.withValues(alpha: .25),
            onChanged: (String text) {
              widget.resProvider.setTitle(widget.index, text);
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if(Provider.of<SplashController>(context,listen: false).configModel?.isAiFeatureActive == 1)
          Consumer<AiController>(
            builder: (context, aiController, child){
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      if(widget.resProvider.titleControllerList[widget.index].text.isEmpty) {
                        showQuikseeSnackBarWidget('${getTranslated('product_name_required', context)}', context);
                      }else{
                        aiController.generateDescription (
                          title: widget.resProvider.titleControllerList[widget.index].text.trim(),
                          langCode: widget.langCode,
                        ).then((value) {
                          if(aiController.description?.data != null && aiController.description!.data!.isNotEmpty) {
                            widget.resProvider.descriptionControllerList[widget.index].text = aiController.description?.data ?? '';
                            setState(() {});
                          }
                        });
                      }
                    },
                    child: !aiController.descLoading ? Icon(Icons.auto_awesome, color: Colors.blue) : Shimmer.fromColors(
                      baseColor: Theme.of(context).primaryColor,
                      highlightColor: Colors.grey[100]!,
                      child: Row(children: [
                        Icon(Icons.auto_awesome, color: Colors.blue),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Text(getTranslated('generating', context) ?? '', style: robotoBold.copyWith(color: Colors.blue)),
                      ]),
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          QuikseeTextFieldWidget(
            formProduct: true,
            required: true,
            isDescription: true,
            controller: TextEditingController(text: widget.resProvider.descriptionControllerList[widget.index].text),
            onChanged: (String text) => widget.resProvider.setDescription(widget.index, text),
            textInputType: TextInputType.multiline,
            maxLine: 3,
            border: true,
            borderColor: Theme.of(context).primaryColor.withValues(alpha: .25),
            hintText: getTranslated('product_description', context),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall,),

        ],
      ),
    );
  }
}
