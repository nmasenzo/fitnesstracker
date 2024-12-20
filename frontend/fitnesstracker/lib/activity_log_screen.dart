import 'package:flutter/material.dart';
import 'package:fitness_tracker_app/add_log.dart';
import 'package:fitness_tracker_app/edit_log.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'model_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String backendBaseUrl = dotenv.env['BACKEND_BASE_URL']!;

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  bool isDayView = true;
  DateTime selectedDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  List<int> expandedLogs = [];
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the ID token of the user
        String? idToken = await user.getIdToken();

        Uri url;

        if (isDayView) {
          url = Uri.parse('${backendBaseUrl}/api/exercises/logs/by-date/?workout_date=${DateFormat('yyyy-MM-dd').format(selectedDate)}');
        } else {
          url = Uri.parse('${backendBaseUrl}/api/exercises/logs/by-date-range/?start_date=${DateFormat('yyyy-MM-dd').format(startDate!)}&end_date=${DateFormat('yyyy-MM-dd').format(endDate!)}');
        }

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          }
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            logs = List<Map<String, dynamic>>.from(data['logs'].map((log) => {
              'log_id': log['log_id'],
              'time': log['workout_time'],
              'activity': log['exercise_name'],
              'sets': log['sets'].length,
              'date': log['workout_date'],
              'details': log['sets'].map<Map<String, dynamic>>((set) => {
                'set': set['set_number'],
                'reps': set['reps'],
                'weight': set['weight'] != null ? "${set['weight']} lbs" : "0 lbs",
              }).toList(),
            }));
          });
        } else {
          // Handle error response
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching logs: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // Handle network or parsing error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Log", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment: isDayView ? Alignment.centerLeft : Alignment.centerRight,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isDayView = true;
                          });
                          _fetchLogs();
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            "Day",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDayView ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTimeRange? pickedDateRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: startDate != null && endDate != null
                                ? DateTimeRange(start: startDate!, end: endDate!)
                                : null,
                          );
                          if (pickedDateRange != null) {
                            setState(() {
                              isDayView = false;
                              startDate = pickedDateRange.start;
                              endDate = pickedDateRange.end;
                            });
                            _fetchLogs();
                          }
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            "Week",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: !isDayView ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (isDayView) {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        _fetchLogs();
                      }
                    } else {
                      DateTimeRange? pickedDateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: startDate != null && endDate != null
                            ? DateTimeRange(start: startDate!, end: endDate!)
                            : null,
                      );
                      if (pickedDateRange != null) {
                        setState(() {
                          startDate = pickedDateRange.start;
                          endDate = pickedDateRange.end;
                        });
                        _fetchLogs();
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          isDayView
                              ? DateFormat("EEE, MMM d, yyyy").format(selectedDate)
                              : "${DateFormat("MMM d, yyyy").format(startDate!)} - ${DateFormat("MMM d, yyyy").format(endDate!)}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, color: Colors.blue),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs List
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text("No logs available"))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isExpanded = expandedLogs.contains(index);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditExercise(logId: log['log_id']),
                            ),
                          ).then((_) => _fetchLogs());
                        },
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              color: Colors.white,
                              child: ListTile(
                                leading: const Icon(Icons.remove, size: 16, color: Colors.black),
                                title: Text(
                                  "${log['time']} • ${log['activity']} • Sets: ${log['sets']}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isExpanded ? Icons.expand_less : Icons.chevron_right,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        expandedLogs.remove(index);
                                      } else {
                                        expandedLogs.add(index);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 64.0, right: 16.0, bottom: 8.0),
                                      child: Column(
                                        children: log['details'].map<Widget>((detail) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.remove, size: 16, color: Colors.black),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Set ${detail['set']} • Reps: ${detail['reps']} • Weight: ${detail['weight']}",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF333333),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _showAddExerciseBottomSheet(context);

          // Refetch logs after adding a new exercise log
          _fetchLogs();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomAppBar(),
    );
  }

  void _showAddExerciseBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddExerciseLog()),
                  ).then((_) => _fetchLogs());
                },
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Log Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
  }
}

class CustomBottomAppBar extends StatelessWidget {
  const CustomBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.dashboard, size: 30, color: Colors.black),
                  tooltip: 'Dashboard',
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.article, size: 30, color: Colors.black),
                  tooltip: 'Log',
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HeatModel()),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar, size: 30, color: Colors.black),
                  tooltip: '2D Model',
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.account_circle, size: 30, color: Colors.black),
                  tooltip: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddExerciseBottomSheet extends StatelessWidget {
  const AddExerciseBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddExerciseLog()),
              );
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Log Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

