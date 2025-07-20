import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';

class SmartHomeDashboard extends StatefulWidget {
  const SmartHomeDashboard({super.key});

  @override
  State<SmartHomeDashboard> createState() => _SmartHomeDashboardState();
}

class _SmartHomeDashboardState extends State<SmartHomeDashboard> {
  int _selectedIndex = 0;
  bool isLoading = true;
  String? errorMsg;
  Map<String, dynamic>? latestTemperature;
  Map<String, dynamic>? latestSmoke;
  bool? isLightOn;
  bool isLightLoading = false;
  String? motionStatus;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    fetchLightStatus();
    fetchLatestMotionLog();
  }

  Future<void> fetchLatestData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      // Fetch latest temperature
      final tempResponse = await Supabase.instance.client
          .from('temperature_data')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      print('temperature_data response:');
      print(tempResponse);
      // Fetch latest smoke
      final smokeResponse = await Supabase.instance.client
          .from('smoke_data')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      print('smoke_data response:');
      print(smokeResponse);
      setState(() {
        latestTemperature = (tempResponse.isNotEmpty) ? tempResponse.first : null;
        latestSmoke = (smokeResponse.isNotEmpty) ? smokeResponse.first : null;
        if (latestTemperature == null && latestSmoke == null) {
          errorMsg = 'No data found in Supabase tables.';
        }
      });
    } catch (e, st) {
      print('Error fetching data: $e');
      print(st);
      setState(() {
        errorMsg = 'Error fetching data';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchLightStatus() async {
    setState(() => isLightLoading = true);
    final response = await Supabase.instance.client
        .from('control_switch')
        .select()
        .order('created_at', ascending: false)
        .limit(1);
    setState(() {
      isLightOn = (response.isNotEmpty) ? response.first['is_on'] == true : null;
      isLightLoading = false;
    });
  }

  Future<void> toggleLight(bool value) async {
    setState(() => isLightLoading = true);
    await Supabase.instance.client
        .from('control_switch')
        .update({'is_on': value, 'created_at': DateTime.now().toIso8601String()})
        .eq('id', 1);
    setState(() {
      isLightOn = value;
      isLightLoading = false;
    });
  }

  Future<void> fetchLatestMotionLog() async {
    final response = await Supabase.instance.client
        .from('motion_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(1);
    setState(() {
      motionStatus = (response.isNotEmpty) ? response.first['status'] : null;
    });
  }

  List<FlSpot> _prepareTemperatureChartData(List<Map<String, dynamic>> tempHistory) {
    // Sort and limit to last 20
    tempHistory.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
    final last20 = tempHistory.length > 20 ? tempHistory.sublist(tempHistory.length - 20) : tempHistory;
    return List.generate(last20.length, (index) {
      final data = last20[index];
      final temp = data['temperature'] as num;
      return FlSpot(index.toDouble(), temp.toDouble());
    });
  }

  List<BarChartGroupData> _prepareSmokeChartData(List<Map<String, dynamic>> smokeHistory) {
    // Sort and limit to last 20
    smokeHistory.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
    final last20 = smokeHistory.length > 20 ? smokeHistory.sublist(smokeHistory.length - 20) : smokeHistory;
    return List.generate(last20.length, (index) {
      final data = last20[index];
      final ppm = data['ppm'] as num;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: ppm.toDouble(),
            color: data['alert'] == true ? Colors.red : Colors.blue,
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchHistoryData() async {
    final tempResponse = await Supabase.instance.client
        .from('temperature_data')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    final smokeResponse = await Supabase.instance.client
        .from('smoke_data')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return {
      'temperature_data': (tempResponse is List) ? List<Map<String, dynamic>>.from(tempResponse) : [],
      'smoke_data': (smokeResponse is List) ? List<Map<String, dynamic>>.from(smokeResponse) : [],
    };
  }

  @override
  Widget build(BuildContext context) {
    double? temperature = latestTemperature?['temperature'] != null ? (latestTemperature?['temperature'] as num?)?.toDouble() : null;
    int? ppm = latestSmoke?['ppm'] != null ? (latestSmoke?['ppm'] as num?)?.toInt() : null;
    bool alert = latestSmoke?['alert'] == true;
    String smokeStatus = alert ? 'Alert: Smoke Detected' : 'Safe';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchLatestData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : (temperature == null && ppm == null)
                  ? Center(child: Text('No data available.'))
                  : _buildSelectedPage(temperature, ppm, alert, smokeStatus),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage(double? temperature, int? ppm, bool alert, String smokeStatus) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage(temperature, ppm, alert, smokeStatus);
      case 1:
        return _buildChartsPage();
      case 2:
        return _buildHistoryPage();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomePage(temperature, ppm, alert, smokeStatus);
    }
  }

  Widget _buildHomePage(double? temperature, int? ppm, bool alert, String smokeStatus) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SensorCard(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: temperature != null ? '${temperature.toStringAsFixed(1)}°C' : 'N/A',
            ),
            _SensorCard(
              icon: Icons.smoke_free,
              label: 'Smoke (PPM)',
              value: ppm != null ? '$ppm' : 'N/A',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SensorCard(
          icon: Icons.warning,
          label: 'Smoke Status',
          value: smokeStatus,
          valueColor: alert ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 24),
        // --- MOTION LIGHT TOGGLE ---
        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb),
            title: const Text('Motion Light'),
            subtitle: isLightLoading
                ? const Text('Loading...')
                : Text(isLightOn == true ? 'ON' : 'OFF'),
            trailing: isLightLoading
                ? const CircularProgressIndicator()
                : Switch(
                    value: isLightOn ?? false,
                    onChanged: (val) async {
                      await toggleLight(val);
                    },
                  ),
          ),
        ),
        // --- MOTION LOG STATUS ---
        if (motionStatus != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run),
              title: const Text('Latest Motion'),
              subtitle: Text(motionStatus!),
            ),
          ),
        const SizedBox(height: 24),
        Text('Latest Data', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: Icon(Icons.thermostat, color: Theme.of(context).iconTheme.color),
            title: Text('Temperature: ${temperature != null ? '${temperature.toStringAsFixed(1)}°C' : 'N/A'}',
                style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text('Timeline: ${formatDateTime(latestTemperature?['created_at'])}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        Card(
          color: alert ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).cardColor,
          child: ListTile(
            leading: Icon(Icons.smoke_free, color: alert ? Theme.of(context).colorScheme.error : Theme.of(context).iconTheme.color),
            title: Text('Smoke PPM: ${ppm != null ? '$ppm' : 'N/A'}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: alert ? Theme.of(context).colorScheme.onErrorContainer : null,
                )),
            subtitle: Text('Timeline: ${formatDateTime(latestSmoke?['created_at'])}',
                style: Theme.of(context).textTheme.bodySmall),
            trailing: alert ? Icon(Icons.warning, color: Theme.of(context).colorScheme.error) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Temperature'),
              Tab(text: 'Smoke'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTemperatureChart(),
                _buildSmokeChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchHistoryData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tempHistory = snapshot.data!['temperature_data']!;
        final tempSpots = _prepareTemperatureChartData(tempHistory);
        final tempTimestamps = _prepareTimestamps(tempHistory.length > 20 ? tempHistory.sublist(tempHistory.length - 20) : tempHistory);
        final tempMinY = tempSpots.isNotEmpty ? tempSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b) : 0;
        final tempMaxY = tempSpots.isNotEmpty ? tempSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) : 40;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Temperature Chart', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: tempMinY - 1,
                  maxY: tempMaxY + 1,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= tempTimestamps.length) return const SizedBox.shrink();
                          if (idx % 5 != 0) return const SizedBox.shrink();
                          return Text(tempTimestamps[idx], style: Theme.of(context).textTheme.bodySmall);
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: tempSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(enabled: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmokeChart() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchHistoryData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final smokeHistory = snapshot.data!['smoke_data']!;
        final smokeBars = _prepareSmokeChartData(smokeHistory);
        final smokeTimestamps = _prepareTimestamps(smokeHistory.length > 20 ? smokeHistory.sublist(smokeHistory.length - 20) : smokeHistory);
        final smokeMaxY = smokeBars.isNotEmpty ? smokeBars.map((e) => e.barRods.first.toY).reduce((a, b) => a > b ? a : b) : 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Smoke Chart', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: smokeMaxY + 10,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= smokeTimestamps.length) return const SizedBox.shrink();
                          if (idx % 5 != 0) return const SizedBox.shrink();
                          return Text(smokeTimestamps[idx], style: Theme.of(context).textTheme.bodySmall);
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: smokeBars,
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _prepareTimestamps(List<Map<String, dynamic>> history) {
    final DateFormat formatter = DateFormat('HH:mm');
    return history.map((row) {
      final dt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
      return formatter.format(dt);
    }).toList();
  }

  Widget _buildHistoryPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Temperature'),
              Tab(text: 'Smoke'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTemperatureHistory(),
                _buildSmokeHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureHistory() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchHistoryData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tempHistory = snapshot.data!['temperature_data']!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Temperature History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (tempHistory.isEmpty)
              const Text('No temperature data.'),
            ...tempHistory.map((row) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.thermostat),
                    title: Text('Temperature: ${row['temperature']}°C'),
                    subtitle: Text('Timeline: ${formatDateTime(row['created_at'])}'),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSmokeHistory() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchHistoryData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final smokeHistory = snapshot.data!['smoke_data']!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Smoke History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (smokeHistory.isEmpty)
              const Text('No smoke data.'),
            ...smokeHistory.map((row) => Card(
                  child: ListTile(
                    leading: Icon(Icons.smoke_free, color: row['alert'] == true ? Colors.red : Colors.blue),
                    title: Text('PPM: ${row['ppm']}'),
                    subtitle: Text('Timeline: ${formatDateTime(row['created_at'])}'),
                    trailing: row['alert'] == true ? const Icon(Icons.warning, color: Colors.red) : null,
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant SmartHomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkSmokeAlert();
  }

  void _checkSmokeAlert() {
    if (latestSmoke?['alert'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Smoke detected!'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  void _showSmokeAlertDialog() {
    if (latestSmoke?['alert'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Smoke Detected!'),
            content: const Text('Warning: Smoke has been detected in your home.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).iconTheme.color),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDateTime(String? isoString) {
  if (isoString == null) return 'N/A';
  try {
    final dt = DateTime.parse(isoString);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d | $h:$min:$s';
  } catch (e) {
    return isoString;
  }

  
}

