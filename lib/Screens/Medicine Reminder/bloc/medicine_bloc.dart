import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/medicine_database.dart';
import '../notifications/medicine_notification_service.dart';
import 'medicine_event.dart';
import 'medicine_state.dart';

class MedicineBloc extends Bloc<MedicineEvent, MedicineState> {
  final MedicineDatabase _database = MedicineDatabase();

  MedicineBloc() : super(MedicineInitial()) {
    on<LoadMedicines>(_onLoadMedicines);
    on<AddMedicine>(_onAddMedicine);
    on<UpdateMedicine>(_onUpdateMedicine);
    on<DeleteMedicine>(_onDeleteMedicine);
    on<ClearMedicines>(_onClearMedicines);
  }

  Future<void> _onLoadMedicines(LoadMedicines event, Emitter<MedicineState> emit) async {
    try {
      emit(MedicineLoading());
      final medicines = await _database.getAllMedicines();
      emit(MedicineLoaded(medicines: medicines));
    } catch (e) {
      emit(MedicineError(message: 'Failed to load medicines: $e'));
    }
  }

  Future<void> _onAddMedicine(AddMedicine event, Emitter<MedicineState> emit) async {
    try {
      final id = await _database.insertMedicine(event.medicine);
      final newMedicine = event.medicine.copyWith(id: id);
      
      // Schedule notification if enabled
      if (newMedicine.notificationsEnabled) {
        await MedicineNotificationService().scheduleMedicineReminder(newMedicine);
      }
      
      emit(MedicineAdded(medicine: newMedicine));
      
      // Reload medicines to update the list
      add(LoadMedicines());
    } catch (e) {
      emit(MedicineError(message: 'Failed to add medicine: $e'));
    }
  }

  Future<void> _onUpdateMedicine(UpdateMedicine event, Emitter<MedicineState> emit) async {
    try {
      await _database.updateMedicine(event.medicine);
      
      // Reschedule notification if enabled
      if (event.medicine.notificationsEnabled) {
        await MedicineNotificationService().scheduleMedicineReminder(event.medicine);
      } else {
        await MedicineNotificationService().cancelMedicineReminder(event.medicine.id!);
      }
      
      emit(MedicineUpdated(medicine: event.medicine));
      
      // Reload medicines to update the list
      add(LoadMedicines());
    } catch (e) {
      emit(MedicineError(message: 'Failed to update medicine: $e'));
    }
  }

  Future<void> _onDeleteMedicine(DeleteMedicine event, Emitter<MedicineState> emit) async {
    try {
      await _database.deleteMedicine(event.id);
      
      // Cancel notification
      await MedicineNotificationService().cancelMedicineReminder(event.id);
      
      emit(MedicineDeleted(medicineId: event.id));
      
      // Reload medicines to update the list
      add(LoadMedicines());
    } catch (e) {
      emit(MedicineError(message: 'Failed to delete medicine: $e'));
    }
  }

  Future<void> _onClearMedicines(ClearMedicines event, Emitter<MedicineState> emit) async {
    try {
      await _database.deleteAllMedicines();
      
      // Cancel all notifications
      await MedicineNotificationService().cancelAllMedicineReminders();
      
      emit(MedicineLoaded(medicines: []));
    } catch (e) {
      emit(MedicineError(message: 'Failed to clear medicines: $e'));
    }
  }
}