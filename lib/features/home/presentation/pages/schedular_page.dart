import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift_cloud_backup/utils/scheduler_service.dart';

class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  String _selectedFrequency = "Daily";
  TimeOfDay? _selectedTime;
  String? _selectedDay;
  int? _selectedDate;

  final List<String> _frequencies = ["Daily", "Weekly", "Monthly"];
  final List<String> _days = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Format time to 12-hour with AM/PM
  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedFrequency = prefs.getString("frequency") ?? "Daily";

      final hour = prefs.getInt("time_hour");
      final minute = prefs.getInt("time_minute");
      if (hour != null && minute != null) {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }

      _selectedDay = prefs.getString("day");
      _selectedDate = prefs.getInt("date");
    });
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("frequency", _selectedFrequency);
    if (_selectedTime != null) {
      await prefs.setInt("time_hour", _selectedTime!.hour);
      await prefs.setInt("time_minute", _selectedTime!.minute);
    }
    if (_selectedDay != null) {
      await prefs.setString("day", _selectedDay!);
    }
    if (_selectedDate != null) {
      await prefs.setInt("date", _selectedDate!);
    }
  }

  /// Check if there are changes compared to saved preferences
  Future<bool> _hasChanges() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFrequency = prefs.getString("frequency") ?? "Daily";
    final savedHour = prefs.getInt("time_hour");
    final savedMinute = prefs.getInt("time_minute");
    final savedDay = prefs.getString("day");
    final savedDate = prefs.getInt("date");

    if (savedFrequency != _selectedFrequency) return true;
    if ((_selectedTime?.hour != savedHour) || (_selectedTime?.minute != savedMinute)) return true;
    if (savedDay != _selectedDay) return true;
    if (savedDate != _selectedDate) return true;

    return false;
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _applySchedule() async {
    final hasChanges = await _hasChanges();

    if (!hasChanges) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ NO changes, already applied"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await _savePreferences();

    SchedulerService schedulerService = SchedulerService();
    schedulerService.start();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Successfully updated!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scheduler")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Frequency selection
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: "Select Frequency",
                  border: OutlineInputBorder(),
                ),
                items: _frequencies
                    .map((freq) => DropdownMenuItem(
                  value: freq,
                  child: Text(freq),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                    _selectedDay = null;
                    _selectedDate = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              /// Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedTime == null
                      ? "No time selected"
                      : "Selected Time: ${_formatTime(context, _selectedTime!)}",
                ),
                trailing: ElevatedButton(
                  onPressed: _pickTime,
                  child: Text(
                    _selectedTime == null
                        ? "Pick Time"
                        : _formatTime(context, _selectedTime!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Weekly / Monthly options
              if (_selectedFrequency == "Weekly")
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: "Select Day",
                    border: OutlineInputBorder(),
                  ),
                  items: _days
                      .map((day) => DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),

              if (_selectedFrequency == "Monthly")
                DropdownButtonFormField<int>(
                  value: _selectedDate,
                  decoration: const InputDecoration(
                    labelText: "Select Date",
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    31,
                        (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text("${i + 1}"),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedDate = value;
                    });
                  },
                ),

              const SizedBox(height: 30),

              /// Apply Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _applySchedule,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Apply"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
