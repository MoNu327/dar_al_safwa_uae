import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

Future<String> getAccessToken(Map<String, dynamic> serviceAccount) async {
  try {
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);
    final token = client.credentials.accessToken.data;

    client.close();
    debugPrint("jose==> ${token.toString()}");
    return token;
  } catch (e, stack) {
    debugPrint('Error getting access token: $e');
    debugPrint('Stack trace: $stack');
    throw Exception('Failed to get access token');
  }
}
