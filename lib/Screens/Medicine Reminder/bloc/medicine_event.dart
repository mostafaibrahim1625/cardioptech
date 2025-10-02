import '../database/medicine_database.dart';

abstract class MedicineEvent {}

class LoadMedicines extends MedicineEvent {}

class AddMedicine extends MedicineEvent {
  final Medicine medicine;

  AddMedicine({required this.medicine});
}

class UpdateMedicine extends MedicineEvent {
  final Medicine medicine;

  UpdateMedicine({required this.medicine});
}

class DeleteMedicine extends MedicineEvent {
  final int id;

  DeleteMedicine({required this.id});
}

class ClearMedicines extends MedicineEvent {}