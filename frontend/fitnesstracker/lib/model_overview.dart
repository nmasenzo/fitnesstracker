import 'package:flutter/material.dart';

class HeatMapOverviewScreen extends StatelessWidget {
  final Map<String, double> muscleData = {
    'Chest': 80.0, // placeholders for the actual methods. 
    'Back': 60.0,
    'Arms': 50.0,
    'Legs': 40.0,
    'Shoulders': 70.0,
    'Abs': 30.0,
    'Glutes': 75.0,
    'Calves': 55.0,
  };

  @override
  Widget build(BuildContext context) {
    
    Future.delayed(Duration.zero, () {
      _showHeatMap(context);
    });

    return Scaffold(
      appBar: AppBar(title: Text("Body Heat Map")),
      body: Center(
        child: Text("Your heat map overview is here."),
      ),
    );
  }

  // Maybe a quick debug to ensure data shows properly
  void _showHeatMap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.grey[200],
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          double totalIntensity = muscleData.values.reduce((a, b) => a + b) / muscleData.length;

          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Heat Map Overview",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMuscleColumn(muscleData.keys.take(4)),
                      SizedBox(width: 20),
                      _buildMuscleColumn(muscleData.keys.skip(4)),
                    ],
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Total Intensity:",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  _buildTotalIntense(totalIntensity),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  
  Widget _buildMuscleColumn(Iterable<String> muscles) {
    return Column(
      children: muscles.map((muscle) {
        double level = muscleData[muscle]!;
        return _buildCircle(muscle, level);
      }).toList(),
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
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(muscle, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTotalIntense(double totalIntensity) {
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
