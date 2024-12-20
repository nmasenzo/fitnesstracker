import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'activity_log_screen.dart';
import 'profile_screen.dart';
import 'add_log.dart';
import 'model_back.dart'; // Replace with your modelBack.dart file path
import 'model_front.dart'; // Replace with your modelFront.dart file path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String backendBaseUrl = dotenv.env['BACKEND_BASE_URL']!;

class HeatModel extends StatefulWidget {
  const HeatModel({super.key});

  @override
  _HeatModel createState() => _HeatModel();
}

class _HeatModel extends State<HeatModel> {
  static DateTime? selectedDt;
  static String? weekRange;
  static int time = 0; // 0 for Day, 1 for Week
  static int viewMode = 0; // 0 for Front, 1 for Back

  Map<String, double> muscleData = {};

  Future<void> pickDate() async {
    try {
      DateTime? chosenDate = await showDatePicker(
        context: context,
        initialDate: selectedDt ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2050),
      );
      if (chosenDate != null) {
        setState(() {
          selectedDt = chosenDate;
        });
        await fetchMusclePercentages();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick a date: $e')),
      );
    }
  }

  Future<void> pickWeek() async {
    try {
      DateTimeRange? chosenDateRange = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 7)),
        ),
        firstDate: DateTime(2000),
        lastDate: DateTime(2050),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                onSurface: Colors.blueAccent,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (chosenDateRange != null) {
        setState(() {
          DateTime startOfRange = chosenDateRange.start;
          DateTime endOfRange = chosenDateRange.end;

          selectedDt = startOfRange; // Save the start date for single date selection logic
          weekRange =
              '${DateFormat('MMM d').format(startOfRange)} - ${DateFormat('MMM d').format(endOfRange)}';
        });
        await fetchMusclePercentagesByDateRange(chosenDateRange.start, chosenDateRange.end);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick a date range: $e')),
      );
    }
  }

  Future<void> fetchMusclePercentages() async {
    try {
      if (selectedDt == null) {
        throw Exception('Selected date is null.');
      }

      print('Fetching muscle percentages for date: $selectedDt');
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken();
        final url = Uri.parse('${backendBaseUrl}/api/exercises/muscle-percentage/by-date/?workout_date=${DateFormat('yyyy-MM-dd').format(selectedDt!)}');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        setState(() {
          muscleData = {}; // Clear the old data to avoid stale display
        });

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            muscleData = (data['muscle_percentages'] as Map<String, dynamic>).map((key, value) {
              return MapEntry(key, (value as num).toDouble()); // Convert int or double to double
            });
          });
          print('Updated muscleData: $muscleData');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch muscle percentages: ${response.body}')),
          );
        }

      }
    } catch (e) {
      print('Error fetching muscle percentages: $e');
    }
  }



  Future<void> fetchMusclePercentagesByDateRange(DateTime? startDate, DateTime? endDate) async {
    try {
      if (startDate == null || endDate == null) {
        throw Exception('Start or end date is null.');
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken();
        final url = Uri.parse('${backendBaseUrl}/api/exercises/muscle-percentage/by-date-range/?start_date=${DateFormat('yyyy-MM-dd').format(startDate)}&end_date=${DateFormat('yyyy-MM-dd').format(endDate)}');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            muscleData = (data['muscle_percentages'] as Map<String, dynamic>).map((key, value) {
              return MapEntry(key, (value as num).toDouble()); // Convert int or double to double
            });
          });
          print('Updated muscleData: $muscleData');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch muscle percentages by date range: ${response.body}')),
          );
        }

      }
    } catch (e) {
      print('Error fetching muscle percentages by date range: $e');
    }
  }



  String dateText() {
    if (time == 0) {
      return selectedDt != null
          ? DateFormat('EEE, MMM d, yyyy').format(selectedDt!)
          : 'Pick a Date';
    } else {
      return weekRange ?? 'Pick a Week';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Heat Map', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Day/Week Toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ToggleButtons(
              isSelected: [time == 0, time == 1],
              onPressed: (index) {
                setState(() {
                  time = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              selectedBorderColor: Colors.blue,
              selectedColor: Colors.white,
              fillColor: Colors.blue,
              color: Colors.black,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
              children: const [
                Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Week', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Date Picker and Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: time == 0 ? pickDate : pickWeek,
                icon: const Icon(Icons.calendar_today, color: Colors.black),
                label: Text(
                  dateText(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // Front/Back Toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ToggleButtons(
              isSelected: [viewMode == 0, viewMode == 1],
              onPressed: (index) {
                setState(() {
                  viewMode = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              selectedBorderColor: Colors.blue,
              selectedColor: Colors.white,
              fillColor: Colors.blue,
              color: Colors.black,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
              children: const [
                Text('Front', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Model Container based on viewMode
          Expanded(
            child: Center(
              child: viewMode == 0
                  ? Modelfront(
                      key: ValueKey(time == 0 ? selectedDt : weekRange), // Add ValueKey to force refresh
                      selectedDate: time == 0 ? selectedDt : null,
                      selectedDateRange: time == 1
                          ? (selectedDt != null && weekRange != null
                              ? DateTimeRange(
                                  start: selectedDt!,
                                  end: selectedDt!.add(const Duration(days: 7)),
                                )
                              : null)
                          : null,
                    )
                  : Modelback(
                      key: ValueKey(time == 0 ? selectedDt : weekRange), // Add ValueKey to force refresh
                      selectedDate: time == 0 ? selectedDt : null,
                      selectedDateRange: time == 1
                          ? (selectedDt != null && weekRange != null
                              ? DateTimeRange(
                                  start: selectedDt!,
                                  end: selectedDt!.add(const Duration(days: 7)),
                                )
                              : null)
                          : null,
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Show the heat map bottom sheet
                  _showHeatMap(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'View Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExerciseBottomSheet(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomAppBar(),
    );
  }
void _showHeatMap(BuildContext context) {
  double totalIntensity = muscleData.values.isNotEmpty
    ? muscleData.values.reduce((a, b) => a + b) / muscleData.length
    : 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    backgroundColor: Colors.grey[200],
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8, // 80% of the screen height when first opened
      minChildSize: 0.4, // Minimum height when dragged down
      maxChildSize: 0.9, // Maximum height when dragged up
      builder: (context, scrollController) {
        return SingleChildScrollView(
          key: ValueKey(selectedDt), // Force rebuild when date changes
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center everything
              children: [
                const Center(
                  child: Text(
                    "Heat Map Overview",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildMuscleGroups(), // Separate logic into a helper method
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Total Intensity:",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Center(child: _buildTotalIntensity(totalIntensity)),
              ],
            ),
          ),
        );
      },
    ),
  );
}

List<Widget> _buildMuscleGroups() {
  Map<String, List<String>> muscleGroups = {
    'Upper Body': ['biceps', 'triceps', 'forearms', 'shoulders', 'neck', 'chest'],
    'Back': ['traps', 'lats', 'middle back', 'lower back'],
    'Core': ['abdominals'],
    'Lower Body': ['quadriceps', 'hamstrings', 'calves', 'glutes', 'adductors', 'abductors'],
  };

  return muscleGroups.entries.map((entry) {
    return _buildMuscleGroup(entry.key, entry.value, muscleData);
  }).toList();
}



  Widget _buildMuscleGroup(String groupName, List<String> muscles, Map<String, double> muscleData) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Center the group name
      children: [
        Center(
          child: Text(
            groupName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center, // Center the rings horizontally
            children: muscles.map((muscle) {
              double level = muscleData[muscle] ?? 0;
              return _buildCircle(muscle, level);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}





  Widget _buildCircle(String muscle, double level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: level / 100,
                strokeWidth: 6,
                color: Colors.red,
                backgroundColor: Colors.grey[300],
              ),
            ),
            Text(
              "${level.toStringAsFixed(1)}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          muscle[0].toUpperCase() + muscle.substring(1), // Capitalize first letter
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTotalIntensity(double totalIntensity) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CircularProgressIndicator(
            value: totalIntensity / 100,
            strokeWidth: 10,
            color: Colors.redAccent,
            backgroundColor: Colors.grey[300],
          ),
        ),
        Text(
          "${totalIntensity.toStringAsFixed(1)}%",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogScreen()),
                    );
                  },
                  icon: const Icon(Icons.article, size: 30, color: Colors.black),
                  tooltip: 'Log',
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
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
      },
      isScrollControlled: true,
    );
  }
