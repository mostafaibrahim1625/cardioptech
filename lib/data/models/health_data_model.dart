class HealthDataModel {
  final int? steps;
  final double? calories;
  final double? systolicBloodPressure;
  final double? diastolicBloodPressure;
  final double? heartRate;
  final double? oxygenSaturation;
  final double? sleepHours;
  final double? distance;

  HealthDataModel({
    this.steps,
    this.calories,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    this.heartRate,
    this.oxygenSaturation,
    this.sleepHours,
    this.distance,
  });

  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    return HealthDataModel(
      steps: json['steps'],
      calories: json['calories']?.toDouble(),
      systolicBloodPressure: json['systolic_blood_pressure']?.toDouble(),
      diastolicBloodPressure: json['diastolic_blood_pressure']?.toDouble(),
      heartRate: json['heart_rate']?.toDouble(),
      oxygenSaturation: json['oxygen_sat']?.toDouble(),
      sleepHours: json['sleep_hours']?.toDouble(),
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'calories': calories,
      'systolic_blood_pressure': systolicBloodPressure,
      'diastolic_blood_pressure': diastolicBloodPressure,
      'heart_rate': heartRate,
      'oxygen_sat': oxygenSaturation,
      'sleep_hours': sleepHours,
      'distance': distance,
    };
  }

  HealthDataModel copyWith({
    int? steps,
    double? calories,
    double? systolicBloodPressure,
    double? diastolicBloodPressure,
    double? heartRate,
    double? oxygenSaturation,
    double? sleepHours,
    double? distance,
  }) {
    return HealthDataModel(
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      systolicBloodPressure: systolicBloodPressure ?? this.systolicBloodPressure,
      diastolicBloodPressure: diastolicBloodPressure ?? this.diastolicBloodPressure,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      sleepHours: sleepHours ?? this.sleepHours,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() {
    return 'HealthDataModel(steps: $steps, calories: $calories, systolicBloodPressure: $systolicBloodPressure, diastolicBloodPressure: $diastolicBloodPressure, heartRate: $heartRate, oxygenSaturation: $oxygenSaturation, sleepHours: $sleepHours, distance: $distance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthDataModel &&
        other.steps == steps &&
        other.calories == calories &&
        other.systolicBloodPressure == systolicBloodPressure &&
        other.diastolicBloodPressure == diastolicBloodPressure &&
        other.heartRate == heartRate &&
        other.oxygenSaturation == oxygenSaturation &&
        other.sleepHours == sleepHours &&
        other.distance == distance;
  }

  @override
  int get hashCode {
    return steps.hashCode ^
        calories.hashCode ^
        systolicBloodPressure.hashCode ^
        diastolicBloodPressure.hashCode ^
        heartRate.hashCode ^
        oxygenSaturation.hashCode ^
        sleepHours.hashCode ^
        distance.hashCode;
  }
}
