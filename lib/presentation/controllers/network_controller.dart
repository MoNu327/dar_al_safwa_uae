import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NetworkController extends GetxController {
  final RxBool isConnected = false.obs;
  final RxBool hasInternet = false.obs;
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.none.obs;

  // URL to ping to check internet availability
  static const String _pingUrl = 'https://www.google.com';
  static const Duration _timeOutDuration = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    _checkConnection();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    connectionType.value = results.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );

    isConnected.value = connectionType.value != ConnectivityResult.none;

    // Only check internet if we have a  connection
    if (isConnected.value) {
      hasInternet.value = await _checkInternetAvailability();
    } else {
      hasInternet.value = false;
    }
  }

  Future<void> _checkConnection() async {
    var result = await Connectivity().checkConnectivity();
    await _updateConnectionStatus(result);
  }

  Future<bool> _checkInternetAvailability() async {
    try {
      final response =
          await http.get(Uri.parse(_pingUrl)).timeout(_timeOutDuration);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Helper method to manually trigger connection check
  Future<void> refreshConnection() async {
    await _checkConnection();
  }
}
