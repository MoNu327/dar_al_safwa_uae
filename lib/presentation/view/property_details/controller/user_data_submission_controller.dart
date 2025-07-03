import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../data/model/user_data_submission_model.dart';

class UserDataSubmissionController extends GetxController {
  RxBool isEditMode = true.obs;

  Rx<UserDataSubmissionModel> user = UserDataSubmissionModel(
    firstName: '',
    lastName: '',
    address: '',
    poNo: '',
    nationality: '',
    email: '',
    mobile: '',
    passportNo: '',
    visaNo: '',
  ).obs;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final poNoCtrl = TextEditingController();
  final nationalityCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final passportCtrl = TextEditingController();
  final visaCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    firstNameCtrl.text = user.value.firstName;
    lastNameCtrl.text = user.value.lastName;
    addressCtrl.text = user.value.address;
    poNoCtrl.text = user.value.poNo;
    nationalityCtrl.text = user.value.nationality;
    emailCtrl.text = user.value.email;
    mobileCtrl.text = user.value.mobile;
    passportCtrl.text = user.value.passportNo;
    visaCtrl.text = user.value.visaNo;
  }

  void toggleEdit() {
    isEditMode.value = !isEditMode.value;
  }
}
