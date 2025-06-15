import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsProvider settings;
  late ThemeProvider themeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    settings = Provider.of<SettingsProvider>(context);
    themeProvider = Provider.of<ThemeProvider>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Settings
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const Divider(),

          // ESP32 Connection Status - Commented out for now
          /*
          ListTile(
            title: const Text('ESP32 Connection'),
            subtitle: Text(settings.esp32Ip),
            trailing: const Icon(Icons.wifi, color: Colors.green),
            onTap: () => _showIpAddressDialog(context),
          ),
          const Divider(),
          */

          // Device Settings - Commented out for now
          /*
          ListTile(
            title: const Text('Device Name'),
            subtitle: Text(settings.deviceName),
            trailing: const Icon(Icons.edit),
            onTap: () => _showDeviceNameDialog(context),
          ),
          const Divider(),
          */

          // Data Display Settings
          ListTile(
            title: const Text('Data Refresh Rate'),
            subtitle: Text('Every ${settings.refreshRate} seconds'),
            trailing: const Icon(Icons.refresh),
            onTap: () => _showRefreshRateDialog(context),
          ),
          const Divider(),

          // Temperature Unit - Commented out for now
          /*
          ListTile(
            title: const Text('Temperature Unit'),
            subtitle: Text(settings.isCelsius ? 'Celsius' : 'Fahrenheit'),
            trailing: Switch(
              value: settings.isCelsius,
              onChanged: (value) => settings.setTemperatureUnit(value),
            ),
          ),
          const Divider(),
          */

          // About Section
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'IoT App',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text('A simple IoT application for ESP32 monitoring.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Commented out for now
  /*
  Future<void> _showDeviceNameDialog(BuildContext context) async {
    final controller = TextEditingController(text: settings.deviceName);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'Enter device name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setDeviceName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  */

  Future<void> _showRefreshRateDialog(BuildContext context) async {
    final controller = TextEditingController(text: settings.refreshRate.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Refresh Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Refresh Rate (seconds)',
            hintText: 'Enter refresh rate in seconds',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final rate = int.tryParse(controller.text);
              if (rate != null && rate > 0) {
                settings.setRefreshRate(rate);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Commented out for now
  /*
  Future<void> _showIpAddressDialog(BuildContext context) async {
    final controller = TextEditingController(text: settings.esp32Ip);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ESP32 IP Address'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'IP Address',
            hintText: 'Enter ESP32 IP address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setEsp32Ip(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  */
} 