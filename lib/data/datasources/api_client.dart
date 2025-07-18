import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;

class ApiClient {
  final Dio _dio = Dio();
  final String baseUrl =
      "https://webdesignilluminati.in/Projects/websites/daralsafwa/api/0/";

  final _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 60)
      ..receiveTimeout = const Duration(seconds: 60)
      ..responseType = ResponseType.json;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? accessToken = await _secureStorage.read(key: 'access_token');
        if (accessToken != null &&
            !options.headers.containsKey("Authorization")) {
          options.headers["Authorization"] = "Bearer $accessToken";
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          debugPrint(
              "🔄 401 Unauthorized detected. Trying to refresh token...");

          bool success = await refreshToken();
          if (success) {
            debugPrint("✅ Token refreshed! Retrying request...");
            String? newAccessToken =
                await _secureStorage.read(key: 'access_token');
            e.requestOptions.headers["Authorization"] =
                "Bearer $newAccessToken";
            try {
              final response = await _dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              debugPrint("⚠️ Retried request failed: $retryError");
            }
          }
          debugPrint("🚨 Refresh token failed! Logging out...");
          // getx.Get.offAllNamed(AppRoutes.login);
        }
        return handler.next(e);
      },
    ));
  }

Future<Response> request(
  String endpoint, {
  dynamic data,
  String? method,
  Map<String, String>? headers,
  bool isFormData = false,
  Options? options, // ✅ Change from required to optional
}) async {
  try {
    final response = await _dio.request(
      '$baseUrl$endpoint',
      data: (method == 'get') ? null : data,
      options: options ??
          Options(
            method: method ?? 'post',
            headers: {
              "Content-Type":
                  isFormData ? "multipart/form-data" : "application/json",
              ...?headers,
            },
          ),
    );
    debugPrint("Response Status: ${response.statusCode}");
    return response;
  } on DioException catch (e) {
    debugPrint('Dio Error: ${e.message}, ${e.type}');
    if (e.type == DioExceptionType.connectionTimeout) {
      return _handleTimeoutError();
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return _handleTimeoutError();
    } else if (e.type == DioExceptionType.badResponse) {
      return _handleErrorResponse(e.response);
    } else if (e.type == DioExceptionType.connectionError) {
      return _handleNetworkError();
    } else {
      return _handleUnexpectedError(e);
    }
  } catch (e) {
    return _handleUnexpectedError(e);
  }
}


  Future<bool> refreshToken() async {
    debugPrint("🚀 Calling refresh token API...");
    String? refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (refreshToken == null) {
      debugPrint("❌ No refresh token found! Logging out user.");
      // getx.Get.offAllNamed(AppRoutes.login);
      return false;
    }

    try {
      Dio dioRefresh = Dio();
      final response = await dioRefresh.post(
        "${baseUrl}refresh-tokenuser",
        options: Options(headers: {"Authorization": "Bearer $refreshToken"}),
      );

      if (response.statusCode == 200 && response.data != null) {
        String newAccessToken = response.data["data"]["token"];
        String newRefreshToken = response.data["data"]["refreshtoken"];

        // if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        //   debugPrint("⚠️ Invalid token format received from server");
        //   getx.Get.find<AuthController>().logout();
        //   return false;
        // }

        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        await _secureStorage.write(
            key: 'refresh_token', value: newRefreshToken);

        return true;
      } else if (response.statusCode == 401) {
        debugPrint("❌ Refresh token expired or invalid! Logging out user.");
        // getx.Get.find<AuthController>().logoutWithoutApi();
        return false;
      } else {
        debugPrint("❌ Failed to refresh token: ${response.statusCode}");
        // getx.Get.find<AuthController>().logoutWithoutApi();
        return false;
      }
    } catch (e) {
      // getx.Get.find<AuthController>().logoutWithoutApi();
      return false;
    }
  }

  Response _handleTimeoutError() => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 408,
      statusMessage: 'Request Timeout');
  Response _handleNetworkError() => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 503,
      statusMessage: 'Network Error');
  Response _handleErrorResponse(Response? response) =>
      response ??
      Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          statusMessage: 'Internal Server Error');
  Response _handleUnexpectedError(Object e) => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 500,
      statusMessage: 'Unexpected Error: $e');
}
