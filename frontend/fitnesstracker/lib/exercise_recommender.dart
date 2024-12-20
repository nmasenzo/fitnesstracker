// exercise_rec.dart
import 'package:flutter/material.dart';

Map<String, List<String>> getMuscleExercises() {
  return {
    'abdominals': ['Plank', 'Crunches', 'Russian Twists'],
    'abductors': ['Side-Lying Leg Raises', 'Clamshells', 'Cable Abductions'],
    'adductors': ['Sumo Squats', 'Cable Adductions', 'Side-Lying Hip Adduction'],
    'biceps': ['Bicep Curls', 'Hammer Curls', 'Chin-Ups'],
    'calves': ['Standing Calf Raises', 'Seated Calf Raises', 'Jump Rope'],
    'chest': ['Push-ups', 'Bench Press', 'Chest Flys'],
    'forearms': ['Wrist Curls', 'Reverse Curls', 'Farmer\'s Carry'],
    'glutes': ['Hip Thrusts', 'Glute Bridges', 'Cable Kickbacks'],
    'hamstrings': ['Romanian Deadlifts', 'Hamstring Curls', 'Glute-Ham Raises'],
    'lats': ['Pull-Ups', 'Lat Pulldowns', 'Barbell Rows'],
    'lower back': ['Deadlifts', 'Superman', 'Back Extensions'],
    'middle back': ['Rows', 'Reverse Flys', 'T-Bar Rows'],
    'neck': ['Neck Flexion', 'Neck Extension', 'Neck Side Bends'],
    'quadriceps': ['Squats', 'Lunges', 'Leg Press'],
    'shoulders': ['Overhead Press', 'Lateral Raises', 'Front Raises'],
    'traps': ['Shrugs', 'Face Pulls', 'Upright Rows'],
    'triceps': ['Tricep Dips', 'Overhead Tricep Extensions', 'Skull Crushers'],
  };
}

List<String> recommendExercises(String muscleGroup) {
  // Map of muscle groups to exercise lists
  const exerciseMap = {
    'abdominals': ['Plank', 'Crunches', 'Russian Twists'],
    'abductors': ['Side-Lying Leg Raises', 'Clamshells', 'Cable Abduction'],
    'adductors': ['Side Lunges', 'Sumo Squats', 'Inner Thigh Leg Lifts'],
    'biceps': ['Bicep Curls', 'Hammer Curls', 'Concentration Curls'],
    'calves': ['Calf Raises', 'Seated Calf Raises', 'Donkey Calf Raises'],
    'chest': ['Push-ups', 'Bench Press', 'Chest Flys'],
    'forearms': ['Wrist Curls', 'Reverse Wrist Curls', 'Farmer’s Carry'],
    'glutes': ['Hip Thrusts', 'Glute Bridges', 'Bulgarian Split Squats'],
    'hamstrings': ['Deadlifts', 'Hamstring Curls', 'Good Mornings'],
    'lats': ['Pull-ups', 'Lat Pulldowns', 'Rows'],
    'lower back': ['Superman', 'Bird Dogs', 'Romanian Deadlifts'],
    'middle back': ['Bent-over Rows', 'T-bar Rows', 'Reverse Flys'],
    'neck': ['Neck Flexion', 'Neck Extensions', 'Side-to-Side Neck Tilts'],
    'quadriceps': ['Squats', 'Lunges', 'Leg Press'],
    'shoulders': ['Overhead Press', 'Lateral Raises', 'Front Raises'],
    'traps': ['Shrugs', 'Face Pulls', 'Upright Rows'],
    'triceps': ['Tricep Dips', 'Overhead Tricep Extensions', 'Skull Crushers'],
  };

  // Normalize muscleGroup input by converting to lowercase and trimming spaces
  final normalizedGroup = muscleGroup.toLowerCase().trim();

  // Debugging line: print the normalized group being searched
  print('Looking for exercises for: $normalizedGroup');

  // Retrieve exercises from the map, if no match found return an empty list
  final exercises = exerciseMap[normalizedGroup];

  // If exercises not found, log and return an empty list
  if (exercises == null) {
    print("No exercises found for: $normalizedGroup");
    return [];
  }

  // Return the exercises for the specified muscle group
  return exercises;
}

// UI function to show exercises in a popup (example use case)
void showExercisePopup(BuildContext context, String muscleGroup) {
  final exercises = recommendExercises(muscleGroup);

  // Print recommended exercises to the console for debugging
  print("Recommended exercises: $exercises");

  // Example: displaying exercises in a dialog (you can modify as per your requirements)
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Exercises for $muscleGroup'),
        content: Column(
          children: exercises.map((exercise) => Text(exercise)).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}