import '../database/medicine_database.dart';

abstract class MedicineState {}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicineLoaded extends MedicineState {
  final List<Medicine> medicines;

  MedicineLoaded({required this.medicines});
}

class MedicineAdded extends MedicineState {
  final Medicine medicine;

  MedicineAdded({required this.medicine});
}

class MedicineUpdated extends MedicineState {
  final Medicine medicine;

  MedicineUpdated({required this.medicine});
}

class MedicineDeleted extends MedicineState {
  final int medicineId;

  MedicineDeleted({required this.medicineId});
}

class MedicineError extends MedicineState {
  final String message;

  MedicineError({required this.message});
}