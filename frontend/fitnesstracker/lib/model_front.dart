import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'exercise_recommender.dart';

String backendBaseUrl = dotenv.env['BACKEND_BASE_URL']!;

class Modelfront extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTimeRange? selectedDateRange;

  const Modelfront({Key? key, this.selectedDate, this.selectedDateRange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InteractiveSvgPage(selectedDate: selectedDate, selectedDateRange: selectedDateRange),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InteractiveSvgPage extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTimeRange? selectedDateRange;

  const InteractiveSvgPage({Key? key, this.selectedDate, this.selectedDateRange}) : super(key: key);

  @override
  _InteractiveSvgPageState createState() => _InteractiveSvgPageState();
}

class _InteractiveSvgPageState extends State<InteractiveSvgPage> {
  String svgPath = "assets/images/frontmodel.svg"; // Path to SVG
  Map<String, double> musclePercentages = {
    "adductors": 0.0,
    "hamstrings": 0.0,
    "quads": 0.0,
    "calves": 0.0,
    "glutes": 0.0,
    "lower back": 0.0,
    "forearms": 0.0,
    "triceps": 0.0,
    "lats": 0.0,
    "shoulders": 0.0,
    "middle back": 0.0,
    "neck": 0.0,
  }; // Default data for muscle percentages
  List<_PathData> paths = [];
  Map<String, String> groupToMuscle = {};
  Rect viewBox = Rect.zero;
  bool isLoading = true;

  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedDateRange = widget.selectedDateRange;
    loadSvg(svgPath);
  }

  Future<void> loadSvg(String path) async {
    try {
      final svgString = await rootBundle.loadString(path);
      final document = XmlDocument.parse(svgString);

      // Parse viewBox
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
        viewBox = Rect.fromLTWH(0, 0, 100, 100); // Fallback if parsing fails
      }

      // Parse <g> elements and associate paths with their group
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

      // Parse <path> elements directly under the root <svg>
      final rootPathElements = document.findElements('svg').first.findElements('path');
      for (var pathElement in rootPathElements) {
        final pathData = pathElement.getAttribute('d') ?? '';
        final id = pathElement.getAttribute('id') ?? '';
        if (pathData.isNotEmpty) {
          paths.add(_PathData(id: id, path: parseSvgPathData(pathData)));
        }
      }

      setState(() {
        isLoading = false; // Set loading to false once SVG is loaded
      });

      // Fetch muscle percentages after loading SVG
      fetchMusclePercentages();
    } catch (e) {
      print("Error loading SVG: $e");
    }
  }

  Future<void> fetchMusclePercentages() async {
    if (_selectedDate == null && _selectedDateRange == null) {
      print("No date or date range selected.");
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not authenticated.");
        return;
      }

      String? idToken = await user.getIdToken();
      final url = Uri.parse(_selectedDate != null
          ? '$backendBaseUrl/api/exercises/muscle-percentage/by-date/?workout_date=${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
          : '$backendBaseUrl/api/exercises/muscle-percentage/by-date-range/?start_date=${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)}&end_date=${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          musclePercentages = (responseData['muscle_percentages'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, (value is int) ? value.toDouble() : value));
        });
      } else {
        print("Failed to fetch data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching muscle percentages: $e");
    }
  }

  void showExerciseBottomSheet(BuildContext context, String muscleGroup) {
    final exercises = recommendExercises(muscleGroup); // Get recommended exercises

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercises for $muscleGroup',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: exercises.map((exercise) {
                    return ListTile(
                      title: Text(exercise),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: (viewBox.width > 0 && viewBox.height > 0)
                ? viewBox.width / viewBox.height
                : 1.0,
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(), // Show spinning animation while loading
                  )
                : paths.isNotEmpty
                    ? Stack(
                        children: paths.map((pathData) {
                          String? muscleGroup = groupToMuscle[pathData.id];
                          double percentage = muscleGroup != null
                              ? (musclePercentages[muscleGroup.toLowerCase()] ?? 0.0)
                              : 0.0;
                          Color color = percentage > 0.0
                              ? Colors.red.withOpacity(percentage / 100)
                              : Colors.grey.withOpacity(0.5);

                          return ClipPath(
                            clipper: _PathClipper(pathData.path, viewBox),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (muscleGroup != null) {
                                  showExerciseBottomSheet(context, muscleGroup); // Show exercises for the muscle group
                                } else {
                                  print("No muscle group found for path: \${pathData.id}");
                                }
                              },
                              child: Container(
                                color: color,
                              ),
                            ),
                          );
                        }).toList().reversed.toList(),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.red,
                        child: Center(child: Text('Loading SVG...')),
                      ),
          ),
        ),
      ),
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
