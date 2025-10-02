import 'dart:math';

class HeartDiseaseService {
  static final HeartDiseaseService _instance = HeartDiseaseService._internal();
  factory HeartDiseaseService() => _instance;
  HeartDiseaseService._internal();

  // Heart rate zones for different age groups and conditions
  static const Map<String, Map<String, int>> _heartRateZones = {
    'normal': {
      'resting_min': 60,
      'resting_max': 100,
      'exercise_min': 100,
      'exercise_max': 180,
    },
    'heart_disease': {
      'resting_min': 50,
      'resting_max': 90,
      'exercise_min': 80,
      'exercise_max': 140,
    },
    'severe_heart_disease': {
      'resting_min': 40,
      'resting_max': 80,
      'exercise_min': 60,
      'exercise_max': 120,
    }
  };

  // Blood pressure categories
  static const Map<String, Map<String, int>> _bloodPressureCategories = {
    'normal': {'systolic': 120, 'diastolic': 80},
    'elevated': {'systolic': 130, 'diastolic': 80},
    'stage1_hypertension': {'systolic': 140, 'diastolic': 90},
    'stage2_hypertension': {'systolic': 160, 'diastolic': 100},
    'hypertensive_crisis': {'systolic': 180, 'diastolic': 120},
  };

  // Heart-healthy food recommendations
  static const List<Map<String, dynamic>> _heartHealthyFoods = [
    {
      'category': 'Vegetables',
      'foods': ['Leafy greens', 'Broccoli', 'Carrots', 'Sweet potatoes', 'Tomatoes'],
      'benefits': 'Rich in potassium, fiber, and antioxidants'
    },
    {
      'category': 'Fruits',
      'foods': ['Berries', 'Citrus fruits', 'Apples', 'Pears', 'Bananas'],
      'benefits': 'High in fiber, vitamins, and antioxidants'
    },
    {
      'category': 'Whole Grains',
      'foods': ['Oatmeal', 'Brown rice', 'Quinoa', 'Whole wheat bread', 'Barley'],
      'benefits': 'High in fiber, helps lower cholesterol'
    },
    {
      'category': 'Lean Proteins',
      'foods': ['Fish (salmon, tuna)', 'Skinless poultry', 'Legumes', 'Nuts', 'Seeds'],
      'benefits': 'Omega-3 fatty acids, lean protein'
    },
    {
      'category': 'Healthy Fats',
      'foods': ['Olive oil', 'Avocados', 'Nuts', 'Seeds', 'Fatty fish'],
      'benefits': 'Monounsaturated and polyunsaturated fats'
    }
  ];

  // Foods to avoid for heart health
  static const List<String> _foodsToAvoid = [
    'Processed meats (bacon, sausage, deli meats)',
    'Fried foods',
    'Trans fats (partially hydrogenated oils)',
    'Excessive sodium (canned soups, processed foods)',
    'Sugary drinks and snacks',
    'Excessive alcohol',
    'High-sodium condiments'
  ];

  // Safe exercise recommendations for heart patients
  static const List<Map<String, dynamic>> _safeExercises = [
    {
      'type': 'Walking',
      'intensity': 'Low to Moderate',
      'duration': '30-60 minutes',
      'frequency': 'Daily',
      'benefits': 'Improves circulation, strengthens heart'
    },
    {
      'type': 'Swimming',
      'intensity': 'Low to Moderate',
      'duration': '20-45 minutes',
      'frequency': '3-4 times/week',
      'benefits': 'Full body workout, low impact'
    },
    {
      'type': 'Cycling',
      'intensity': 'Low to Moderate',
      'duration': '20-45 minutes',
      'frequency': '3-4 times/week',
      'benefits': 'Cardiovascular fitness, joint-friendly'
    },
    {
      'type': 'Yoga',
      'intensity': 'Low',
      'duration': '30-60 minutes',
      'frequency': 'Daily',
      'benefits': 'Stress reduction, flexibility, gentle movement'
    },
    {
      'type': 'Light Strength Training',
      'intensity': 'Low to Moderate',
      'duration': '20-30 minutes',
      'frequency': '2-3 times/week',
      'benefits': 'Muscle strength, bone health'
    }
  ];

  // Warning signs that require immediate medical attention
  static const List<String> _emergencyWarningSigns = [
    'Chest pain or pressure',
    'Shortness of breath',
    'Pain in arms, neck, jaw, or back',
    'Nausea or vomiting',
    'Cold sweat',
    'Lightheadedness or fainting',
    'Irregular heartbeat',
    'Swelling in legs or feet',
    'Persistent fatigue',
    'Dizziness'
  ];

  // Analyze heart rate and provide recommendations
  String analyzeHeartRate(int heartRate, String condition) {
    final zones = _heartRateZones[condition] ?? _heartRateZones['normal']!;
    
    if (heartRate < zones['resting_min']!) {
      return 'Your heart rate is below normal resting range. This could indicate bradycardia. Please consult your cardiologist if this persists.';
    } else if (heartRate > zones['resting_max']!) {
      return 'Your heart rate is above normal resting range. This could indicate tachycardia. Please consult your cardiologist if this persists.';
    } else {
      return 'Your heart rate is within normal range for your condition. Keep monitoring and maintain your healthy lifestyle.';
    }
  }

  // Analyze blood pressure and provide recommendations
  String analyzeBloodPressure(int systolic, int diastolic) {
    String category;
    String recommendation;
    
    if (systolic < 120 && diastolic < 80) {
      category = 'Normal';
      recommendation = 'Excellent! Keep maintaining your healthy lifestyle.';
    } else if (systolic < 130 && diastolic < 80) {
      category = 'Elevated';
      recommendation = 'Consider lifestyle modifications like diet and exercise.';
    } else if (systolic < 140 && diastolic < 90) {
      category = 'Stage 1 Hypertension';
      recommendation = 'Consult your doctor about lifestyle changes and possible medication.';
    } else if (systolic < 160 && diastolic < 100) {
      category = 'Stage 2 Hypertension';
      recommendation = 'Immediate consultation with your cardiologist recommended.';
    } else {
      category = 'Hypertensive Crisis';
      recommendation = 'Seek immediate medical attention.';
    }
    
    return 'Blood Pressure: $systolic/$diastolic mmHg\nCategory: $category\nRecommendation: $recommendation';
  }

  // Get heart-healthy diet recommendations
  List<Map<String, dynamic>> getHeartHealthyDiet() {
    return _heartHealthyFoods;
  }

  // Get foods to avoid
  List<String> getFoodsToAvoid() {
    return _foodsToAvoid;
  }

  // Get safe exercise recommendations
  List<Map<String, dynamic>> getSafeExercises() {
    return _safeExercises;
  }

  // Get emergency warning signs
  List<String> getEmergencyWarningSigns() {
    return _emergencyWarningSigns;
  }

  // Calculate target heart rate for exercise
  Map<String, int> calculateTargetHeartRate(int age, String condition) {
    final maxHeartRate = 220 - age;
    final zones = _heartRateZones[condition] ?? _heartRateZones['normal']!;
    
    return {
      'max_heart_rate': maxHeartRate,
      'target_min': (maxHeartRate * 0.5).round(),
      'target_max': (maxHeartRate * 0.7).round(),
      'safe_max': zones['exercise_max']!,
    };
  }

  // Generate daily heart health tips
  List<String> getDailyHeartHealthTips() {
    final tips = [
      'Take your medications as prescribed by your cardiologist',
      'Monitor your blood pressure daily if recommended',
      'Stay hydrated by drinking plenty of water',
      'Get 7-9 hours of quality sleep each night',
      'Practice stress management techniques like deep breathing',
      'Limit sodium intake to less than 2,300mg per day',
      'Include omega-3 rich foods in your diet',
      'Take regular breaks if you sit for long periods',
      'Avoid smoking and secondhand smoke',
      'Keep emergency contact numbers easily accessible',
      'Track your symptoms and report changes to your doctor',
      'Stay active with doctor-approved exercises',
      'Maintain a healthy weight',
      'Limit alcohol consumption',
      'Eat a variety of colorful fruits and vegetables'
    ];
    
    // Return 3 random tips for daily use
    final random = Random();
    final shuffledTips = List<String>.from(tips)..shuffle(random);
    return shuffledTips.take(3).toList();
  }

  // Check if heart rate is in safe range for exercise
  bool isHeartRateSafeForExercise(int heartRate, int age, String condition) {
    final targetHeartRate = calculateTargetHeartRate(age, condition);
    return heartRate >= targetHeartRate['target_min']! && 
           heartRate <= targetHeartRate['safe_max']!;
  }

  // Get medication adherence tips
  List<String> getMedicationAdherenceTips() {
    return [
      'Set daily reminders on your phone',
      'Use a pill organizer for the week',
      'Take medications at the same time each day',
      'Keep a medication log or diary',
      'Set up automatic refills with your pharmacy',
      'Keep a backup supply of medications',
      'Never skip doses without consulting your doctor',
      'Understand what each medication does',
      'Report any side effects immediately',
      'Keep medications in a cool, dry place'
    ];
  }
}

