import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Utils/main_variables.dart';
import 'bloc/medicine_bloc.dart';
import 'bloc/medicine_event.dart';
import 'bloc/medicine_state.dart';
import 'database/medicine_database.dart';
import 'widgets/simple_add_medicine.dart';
import 'widgets/simple_medicine_card.dart';
import 'widgets/simple_empty_state.dart';

class CleanMedicineReminderScreen extends StatelessWidget {
  const CleanMedicineReminderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MedicineBloc()..add(LoadMedicines()),
      child: _CleanMedicineReminderContent(),
    );
  }
}

class _CleanMedicineReminderContent extends StatefulWidget {
  @override
  _CleanMedicineReminderContentState createState() => _CleanMedicineReminderContentState();
}

class _CleanMedicineReminderContentState extends State<_CleanMedicineReminderContent> {
  bool _isSelectionMode = false;
  Set<int> _selectedMedicines = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              // Title Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 40, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medicine Reminder',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HexColor(mainColor),
                      ),
                    ),
                    // Selection mode controls
                    if (_isSelectionMode) ...[
                      Row(
                        children: [
                          Text(
                            '${_selectedMedicines.length} selected',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: HexColor(mainColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: HexColor(mainColor)),
                            onPressed: _exitSelectionMode,
                          ),
                          if (_selectedMedicines.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: _deleteSelectedMedicines,
                            ),
                        ],
                      ),
                    ] else ...[
                      BlocBuilder<MedicineBloc, MedicineState>(
                        builder: (context, state) {
                          if (state is MedicineLoaded && state.medicines.isNotEmpty) {
                            return IconButton(
                              icon: Icon(Icons.checklist, color: HexColor(mainColor)),
                              onPressed: _enterSelectionMode,
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              
              // Header Icon (Drug image instead of medicine icon)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[50],
                  ),
                  child: Image.asset(
                    'assets/medicine_images/drug.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.medication,
                        size: 50,
                        color: HexColor(mainColor),
                      );
                    },
                  ),
                ),
              ),
              
              // My Medications Title (Left aligned)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  'My Medications',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: HexColor(mainColor),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            
            // Medicine List
            Expanded(
              child: BlocConsumer<MedicineBloc, MedicineState>(
                listener: (context, state) {
                  // No UI feedback for state changes
                },
                builder: (context, state) {
                  if (state is MedicineLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(HexColor(mainColor)),
                      ),
                    );
                  } else if (state is MedicineLoaded) {
                    if (state.medicines.isEmpty) {
                      return SimpleEmptyState();
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                      itemCount: state.medicines.length,
                      itemBuilder: (context, index) {
                        final medicine = state.medicines[index];
                        return SimpleMedicineCard(
                          medicine: medicine,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedMedicines.contains(medicine.id),
                          onSelectionChanged: () => _toggleSelection(medicine.id!),
                          onEdit: () => _editMedicine(medicine),
                          onDelete: () => _deleteMedicine(medicine),
                        );
                      },
                    );
                  } else if (state is MedicineError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error Loading Medicines',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            state.message,
                            style: GoogleFonts.montserrat(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<MedicineBloc>().add(LoadMedicines());
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return SimpleEmptyState();
                },
              ),
            ),
          ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineDialog(context),
        backgroundColor: HexColor(mainColor),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    // Capture the parent context that has access to the BLoC
    final parentContext = context;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.9,
                maxWidth: constraints.maxWidth * 0.95,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: SimpleAddMedicine(
                    onAddMedicine: (AddMedicine event) {
                      // Access the BLoC from the parent context
                      parentContext.read<MedicineBloc>().add(event);
                      Navigator.pop(modalContext);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedMedicines.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMedicines.clear();
    });
  }

  void _toggleSelection(int medicineId) {
    setState(() {
      if (_selectedMedicines.contains(medicineId)) {
        _selectedMedicines.remove(medicineId);
      } else {
        _selectedMedicines.add(medicineId);
      }
    });
  }

  void _deleteSelectedMedicines() {
    if (_selectedMedicines.isEmpty) return;
    
    // Capture the parent context that has access to the BLoC
    final parentContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Selected Medicines',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedMedicines.length} selected medicine(s)? This action cannot be undone.',
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: HexColor(mainColor)),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete selected medicines using parent context
              for (int medicineId in _selectedMedicines) {
                parentContext.read<MedicineBloc>().add(DeleteMedicine(id: medicineId));
              }
              _exitSelectionMode();
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editMedicine(Medicine medicine) {
    // TODO: Implement edit functionality
  }

  void _deleteMedicine(Medicine medicine) {
    // Capture the parent context that has access to the BLoC
    final parentContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Medicine',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${medicine.name}"?',
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: HexColor(mainColor)),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Use parent context to access the BLoC
              parentContext.read<MedicineBloc>().add(DeleteMedicine(id: medicine.id!));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}