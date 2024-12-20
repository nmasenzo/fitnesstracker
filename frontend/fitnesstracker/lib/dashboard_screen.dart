import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile_screen.dart';
import 'model_screen.dart';
import 'activity_log_screen.dart';
import 'add_log.dart';

String backendBaseUrl = dotenv.env['BACKEND_BASE_URL']!;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  Map<String, double>? musclePercentages;
  String? userName; // To store the user's name

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchMusclePercentages();
  }

  Future<void> _fetchDashboardData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken();
        final url = Uri.parse('$backendBaseUrl/api/users/me/dashboard/?start_date=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)))}&end_date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            dashboardData = json.decode(response.body);
            userName = data["firstName"];
          });
        } else {
          // Handle error
          print('Failed to load dashboard data: ${response.body}');
        }
      }
    } catch (e) {
      // Handle error
      print('An error occurred: $e');
    }
  }

  Future<void> _fetchMusclePercentages() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken();
        final url = Uri.parse('$backendBaseUrl/api/exercises/muscle-percentage/by-date-range/?start_date=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)))}&end_date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          setState(() {
            musclePercentages = (json.decode(response.body)['muscle_percentages'] as Map<String, dynamic>).map((key, value) => MapEntry(key, (value is int) ? value.toDouble() : value));
          });
        } else {
          // Handle error
          print('Failed to load muscle percentages: ${response.body}');
        }
      }
    } catch (e) {
      // Handle error
      print('An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(userName: userName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WeeklySummary(data: dashboardData),
            const SizedBox(height: 20),
            Container(
              height: 500,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    child: const Text(
                      "9/25 - 10/2",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ProgressRing(musclePercentages: musclePercentages),
                  ),
                  BodyHeatMapSection(musclePercentages: musclePercentages),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExerciseBottomSheet(context);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return const AddExerciseBottomSheet();
      },
      isScrollControlled: true,
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  const CustomAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("Welcome ${userName ?? 'User'}"), 
      backgroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 32,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class WeeklySummary extends StatelessWidget {
  final Map<String, dynamic>? data;

  const WeeklySummary({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Weekly Summary (${data!["start_date"]} - ${data!["end_date"]})',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              SummaryTile("Logs", "${data!["currentWeek"]["numOfLogs"]}", "Prev: ${data!["previousWeek"]["numOfLogs"]}", Colors.blue, true),
              SummaryTile("Muscles", "${data!["currentWeek"]["numOfMuscles"]}", "Prev: ${data!["previousWeek"]["numOfMuscles"]}", Colors.green, true),
              SummaryTile("Sets", "${data!["currentWeek"]["numOfSets"]}", "Prev: ${data!["previousWeek"]["numOfSets"]}", Colors.red, false),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isPositive;

  const SummaryTile(this.title, this.value, this.subtitle, this.color, this.isPositive, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
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
                    // Navigate to Dashboard
                  },
                  icon: const Icon(Icons.dashboard, size: 30, color: Colors.black),
                  tooltip: 'Dashboard',
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogScreen()),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HeatModel()),
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
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
                MaterialPageRoute(builder: (context) => const AddExerciseLog()),
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

class BodyHeatMapSection extends StatelessWidget {
  final Map<String, double>? musclePercentages;

  const BodyHeatMapSection({super.key, this.musclePercentages});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/images/frontmodel.svg'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading SVG'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No data found'));
        } else {
          final svgString = snapshot.data!;
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8, // Adjusted to push the text further up
                  left: 8, // Adjusted to push the text further to the left
                  child: Text(
                    "${DateFormat('MM/dd').format(DateTime.now().subtract(const Duration(days: 7)))} - ${DateFormat('MM/dd').format(DateTime.now())}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ProgressRing(musclePercentages: musclePercentages),
                ),
                Center(
                  child: InteractiveSvg(
                    svgString: svgString,
                    musclePercentages: musclePercentages,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}


class InteractiveSvg extends StatefulWidget {
  final String svgString;
  final Map<String, double>? musclePercentages;

  const InteractiveSvg({required this.svgString, this.musclePercentages});

  @override
  _InteractiveSvgState createState() => _InteractiveSvgState();
}

class _InteractiveSvgState extends State<InteractiveSvg> {
  List<_PathData> paths = [];
  Map<String, String> groupToMuscle = {};
  Rect viewBox = Rect.zero;

  @override
  void initState() {
    super.initState();
    loadSvg(widget.svgString);
  }

  void loadSvg(String svgString) {
    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.findElements('svg').first;
      final viewBoxString = svgElement.getAttribute('viewBox') ?? "0 0 100 100";
      final viewBoxValues = viewBoxString.split(' ').map(double.parse).toList();
      if (viewBoxValues.length == 4) {
        viewBox = Rect.fromLTWH(
          viewBoxValues[0],
          viewBoxValues[1],
          viewBoxValues[2],
          viewBoxValues[3],
        );
      } else {
        viewBox = Rect.fromLTWH(0, 0, 100, 100);
      }

      final groupElements = document.findAllElements('g');
      for (var groupElement in groupElements) {
        final groupId = groupElement.getAttribute('id') ?? '';
        final pathElements = groupElement.findElements('path');

        for (var pathElement in pathElements) {
          final pathData = pathElement.getAttribute('d') ?? '';
          final id = pathElement.getAttribute('id') ?? '';
          if (pathData.isNotEmpty) {
            if (groupId.isNotEmpty) {
              groupToMuscle[id] = groupId;
            }
            paths.add(_PathData(id: id, path: parseSvgPathData(pathData)));
          }
        }
      }

      final rootPathElements = document.findElements('svg').first.findElements('path');
      for (var pathElement in rootPathElements) {
        final pathData = pathElement.getAttribute('d') ?? '';
        final id = pathElement.getAttribute('id') ?? '';
        if (pathData.isNotEmpty) {
          paths.add(_PathData(id: id, path: parseSvgPathData(pathData)));
        }
      }

      setState(() {});
    } catch (e) {
      print("Error loading SVG: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: (viewBox.width > 0 && viewBox.height > 0)
          ? viewBox.width / viewBox.height
          : 1.0,
      child: paths.isNotEmpty
          ? Stack(
              children: paths.map((pathData) {
                String? muscleGroup = groupToMuscle[pathData.id];
                double percentage = muscleGroup != null
                    ? (widget.musclePercentages?[muscleGroup.toLowerCase()] ?? 0.0)
                    : 0.0;
                Color color = percentage > 0.0
                    ? Colors.red.withOpacity(percentage / 100)
                    : Colors.grey.withOpacity(0.5);

                return ClipPath(
                  clipper: _PathClipper(pathData.path, viewBox),
                  child: Container(
                    color: color,
                  ),
                );
              }).toList().reversed.toList(),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PathData {
  final String id;
  final Path path;

  _PathData({required this.id, required this.path});
}

class _PathClipper extends CustomClipper<Path> {
  final Path originalPath;
  final Rect viewBox;

  _PathClipper(this.originalPath, this.viewBox);

  @override
  Path getClip(Size size) {
    final scaleX = size.width / viewBox.width;
    final scaleY = size.height / viewBox.height;

    final matrix = Matrix4.identity()
      ..scale(scaleX, scaleY)
      ..translate(-viewBox.left, -viewBox.top);

    return originalPath.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class ProgressRing extends StatelessWidget {
  final Map<String, double>? musclePercentages;

  const ProgressRing({super.key, this.musclePercentages});

  double _calculateAveragePercentage() {
    if (musclePercentages == null || musclePercentages!.isEmpty) {
      return 0.0;
    }
    final total = musclePercentages!.values.reduce((a, b) => a + b);
    return total / musclePercentages!.length;
  }

  @override
  Widget build(BuildContext context) {
    final averagePercentage = _calculateAveragePercentage();
    return SizedBox(
      width: 75,
      height: 75,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 75,
            height: 75,
            child: CircularProgressIndicator(
              value: averagePercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 8,
            ),
          ),
          Text(
            "${averagePercentage.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
