import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  
  // Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      print('🔍 Checking internet connectivity...');
      
      // First check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      print('📡 Connectivity result: $connectivityResult');
      
      // If no network connection, return false immediately
      if (connectivityResult == ConnectivityResult.none) {
        print('❌ No network connection detected');
        return false;
      }
      
      // If we have network connection, test actual internet access
      return await _testInternetAccess();
      
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }
  
  // Test actual internet access by making a request
  static Future<bool> _testInternetAccess() async {
    try {
      print('🌐 Testing actual internet access...');
      
      // Try to reach a reliable server with a quick timeout
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));
      
      final hasInternet = response.statusCode == 200;
      print('✅ Internet access test: ${hasInternet ? "SUCCESS" : "FAILED"}');
      return hasInternet;
      
    } catch (e) {
      print('❌ Internet access test failed: $e');
      return false;
    }
  }
  
  // Get current connectivity status
  static Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Return the first result or none if empty
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      print('❌ Error getting connectivity status: $e');
      return ConnectivityResult.none;
    }
  }
  
  // Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
  
  // Get user-friendly connectivity message
  static String getConnectivityMessage(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.other:
        return 'Connected to Other Network';
      case ConnectivityResult.none:
        return 'No Internet Connection';
    }
  }
  
  // Check if connectivity result indicates internet access
  static bool hasNetworkConnection(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
  
  // Comprehensive internet check with detailed logging
  static Future<Map<String, dynamic>> getDetailedConnectivityInfo() async {
    try {
      print('🔍 Performing detailed connectivity check...');
      
      final connectivityResult = await getConnectivityStatus();
      final hasInternet = await hasInternetConnection();
      
      final info = {
        'connectivity': connectivityResult,
        'hasInternet': hasInternet,
        'message': getConnectivityMessage(connectivityResult),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📊 Connectivity Info: $info');
      return info;
      
    } catch (e) {
      print('❌ Error getting detailed connectivity info: $e');
      return {
        'connectivity': ConnectivityResult.none,
        'hasInternet': false,
        'message': 'Connection check failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
