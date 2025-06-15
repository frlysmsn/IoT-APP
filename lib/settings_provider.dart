import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _deviceNameKey = 'device_name';
  static const String _refreshRateKey = 'refresh_rate';
  static const String _temperatureUnitKey = 'temperature_unit';
  static const String _esp32IpKey = 'esp32_ip';

  String _deviceName = 'ESP32 Device';
  int _refreshRate = 5; // seconds
  bool _isCelsius = true;
  String _esp32Ip = '192.168.1.100'; // Default IP, should be updated with actual ESP32 IP

  // Getters
  String get deviceName => _deviceName;
  int get refreshRate => _refreshRate;
  bool get isCelsius => _isCelsius;
  String get esp32Ip => _esp32Ip;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceName = prefs.getString(_deviceNameKey) ?? 'ESP32 Device';
    _refreshRate = prefs.getInt(_refreshRateKey) ?? 5;
    _isCelsius = prefs.getBool(_temperatureUnitKey) ?? true;
    _esp32Ip = prefs.getString(_esp32IpKey) ?? '192.168.1.100';
    notifyListeners();
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, name);
    notifyListeners();
  }

  Future<void> setRefreshRate(int seconds) async {
    _refreshRate = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshRateKey, seconds);
    notifyListeners();
  }

  Future<void> setTemperatureUnit(bool isCelsius) async {
    _isCelsius = isCelsius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_temperatureUnitKey, isCelsius);
    notifyListeners();
  }

  Future<void> setEsp32Ip(String ip) async {
    _esp32Ip = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_esp32IpKey, ip);
    notifyListeners();
  }
} 