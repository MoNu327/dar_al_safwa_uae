import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller to handle periodic text switching logic
class PeriodicTextSwitcherController extends GetxController {
  final String text1;
  final String text2;
  final Duration interval;

  final RxString currentText = ''.obs;
  late final Timer _timer;

  PeriodicTextSwitcherController({
    required this.text1,
    required this.text2,
    this.interval = const Duration(minutes: 1),
  });

  @override
  void onInit() {
    super.onInit();
    currentText.value = text1;
    _timer = Timer.periodic(interval, (_) {
      currentText.value = currentText.value == text1 ? text2 : text1;
    });
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }
}
