
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/profile/widgets/account_info_widget.dart';
import 'package:quiksee/features/profile/widgets/general_info_widget.dart';
import 'package:quiksee/features/profile/widgets/profile_header.dart';


class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>  with TickerProviderStateMixin {


  void _updateUserAccount() async {

    if(Get.find<ProfileController>().profileModel!.fName ==  Get.find<ProfileController>().firstNameController.text
        && Get.find<ProfileController>().profileModel!.lName ==  Get.find<ProfileController>().lastNameController.text
        && Get.find<ProfileController>().profileModel!.address ==  Get.find<ProfileController>().addressController.text &&
        Get.find<ProfileController>().file == null
        &&  Get.find<ProfileController>().passwordController.text.isEmpty &&
        Get.find<ProfileController>().confirmPasswordController.text.isEmpty) {
      showQuikseeSnackBarWidget('change_something_to_update'.tr);
    } else if(Get.find<ProfileController>().passwordController.text.isNotEmpty && !Get.find<ProfileController>().isPasswordValid()){
      showQuikseeSnackBarWidget('enter_valid_password'.tr);
    } else if(Get.find<ProfileController>().passwordController.text.isNotEmpty &&
        Get.find<ProfileController>().passwordController.text.length <8){
      showQuikseeSnackBarWidget('password_be_at_least_8_character'.tr);
    }else if(Get.find<ProfileController>().passwordController.text.isNotEmpty  &&
        Get.find<ProfileController>().passwordController.text != Get.find<ProfileController>().confirmPasswordController.text){
      showQuikseeSnackBarWidget('password_not_match'.tr);
    } else {
      UserInfoModel updateUserInfoModel = Get.find<ProfileController>().profileModel!;
      updateUserInfoModel.fName =  Get.find<ProfileController>().firstNameController.text;
      updateUserInfoModel.lName =  Get.find<ProfileController>().lastNameController.text;
      updateUserInfoModel.address =  Get.find<ProfileController>().addressController.text;
      String password =  Get.find<ProfileController>().passwordController.text;
      Get.find<ProfileController>().updateUserInfo(updateUserInfoModel, password);

    }
  }

  TabController? _tabController;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().clearPassword();
    if(Get.find<ProfileController>().showPassView){
      Get.find<ProfileController>().showHidePass(isUpdate: false);
    }
    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _tabController?.addListener((){
      switch (_tabController!.index){
        case 0:
          Get.find<AuthController>().setIndexForTabBar(1, notify: true);
          break;
        case 1:
          Get.find<AuthController>().setIndexForTabBar(0, notify: true);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: GetBuilder<ProfileController>(
        builder: (profile) {
          int idImageSize = profile.profileModel?.identityImageFullUrl?.length ?? 0;
          if(profile.firstNameController.text.isEmpty ||  profile.lastNameController.text.isEmpty) {
            profile.firstNameController.text = profile.profileModel!.fName!;
            profile.lastNameController.text = profile.profileModel!.lName!;
            profile.addressController.text = profile.profileModel!.address!;
          }
          return ListView(
            children: [

              ProfileHeaderWidget(profileController: profile),

              Center(child: Container(width: MediaQuery.of(context).size.width,
                  color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).canvasColor,
                  child: TabBar(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                    controller: _tabController,
                    labelColor:Get.isDarkMode ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8) : Theme.of(context).primaryColor,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    indicatorColor: Get.isDarkMode ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8) : Theme.of(context).primaryColor,
                    dividerColor: Colors.transparent,
                    indicatorWeight: 1,
                    onTap: (val){
                      setState(() {
                        selectedIndex  = val;
                      });
                    },
                    unselectedLabelStyle: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, fontWeight: FontWeight.w400),
                    labelStyle: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, fontWeight: FontWeight.w700),
                    tabs: [Tab(text: 'general_info'.tr), Tab(text: 'login_info'.tr)]))),


              SizedBox(height: selectedIndex == 0 ? (idImageSize > 4 ? 950 : idImageSize > 2 ? 815 : 750) : 350,
                child: Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,
                    horizontal: Dimensions.paddingSizeDefault),
                  child: TabBarView(physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController, children: const [
                      SizedBox(child: GeneralInfoWidget()),
                      AccountInfoWidget()])),
              ),

              Padding(padding:  EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeDefault),
                child: Container(width: MediaQuery.of(context).size.width,
                  margin:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                  child: !profile.isLoading ?
                  QuikseeButtonWidget(onTap: _updateUserAccount, btnTxt: 'update_profile'.tr) :
                  Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
