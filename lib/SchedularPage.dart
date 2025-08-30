import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// ✅ Load saved preferences
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

  /// ✅ Save preferences whenever a value changes
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _savePreferences(); // ✅ Save immediately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Frequency")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frequency Dropdown
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
                  _savePreferences(); // ✅ Save when changed
                },
              ),
              const SizedBox(height: 16),

              // Time Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? "No time selected"
                          : "Selected Time: ${_selectedTime!.format(context)}",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickTime,
                    child: const Text("Select Time"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Extra fields for Weekly / Monthly
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
                    _savePreferences(); // ✅ Save when changed
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
                    _savePreferences(); // ✅ Save when changed
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
