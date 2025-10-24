import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      debugPrint('Connectivity check: ${isConnected ? 'Online' : 'Offline'}');
      return isConnected;
    } on SocketException catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected connectivity error: $e');
      return false;
    }
  }
}
