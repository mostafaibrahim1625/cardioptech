import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../../Utils/main_variables.dart';
import '../database/medicine_database.dart';
import '../notifications/medicine_notification_service.dart';

class DatabaseTestWidget extends StatefulWidget {
  const DatabaseTestWidget({Key? key}) : super(key: key);

  @override
  State<DatabaseTestWidget> createState() => _DatabaseTestWidgetState();
}

class _DatabaseTestWidgetState extends State<DatabaseTestWidget> {
  final MedicineDatabase _database = MedicineDatabase();
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String _status = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading medicines...';
    });

    try {
      final medicines = await _database.getAllMedicines();
      setState(() {
        _medicines = medicines;
        _status = 'Loaded ${medicines.length} medicines';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading medicines: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestMedicine() async {
    setState(() {
      _status = 'Adding test medicine...';
    });

    try {
      final testMedicine = Medicine(
        name: 'Test Medicine ${DateTime.now().millisecondsSinceEpoch}',
        dose: '100mg',
        shape: 'Tablet',
        time: '8:00 AM',
        usageInstructions: 'Take with water',
        image: 'assets/medicine_images/pill.png',
        createdAt: DateTime.now(),
        notificationsEnabled: true,
      );

      await _database.insertMedicine(testMedicine);
      await _loadMedicines();
      setState(() {
        _status = 'Test medicine added successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding test medicine: $e';
      });
    }
  }

  Future<void> _testNotifications() async {
    setState(() {
      _status = 'Testing notifications...';
    });

    try {
      await MedicineNotificationService().sendTestNotification();
      setState(() {
        _status = 'Test notification sent successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error sending test notification: $e';
      });
    }
  }

  Future<void> _clearDatabase() async {
    setState(() {
      _status = 'Clearing database...';
    });

    try {
      await _database.deleteAllMedicines();
      await MedicineNotificationService().cancelAllMedicineReminders();
      await _loadMedicines();
      setState(() {
        _status = 'Database cleared successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error clearing database: $e';
      });
    }
  }

  Future<void> _recreateDatabase() async {
    setState(() {
      _status = 'Recreating database...';
    });

    try {
      await _database.recreateDatabase();
      await _loadMedicines();
      setState(() {
        _status = 'Database recreated successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error recreating database: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: HexColor(mainColor)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Database Test',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: HexColor(mainColor),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _status,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Test Buttons
              Text(
                'Database Tests',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HexColor(mainColor),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildTestButton(
                'Add Test Medicine',
                Icons.add,
                _addTestMedicine,
              ),
              
              _buildTestButton(
                'Test Notifications',
                Icons.notifications,
                _testNotifications,
              ),
              
              _buildTestButton(
                'Reload Medicines',
                Icons.refresh,
                _loadMedicines,
              ),
              
              _buildTestButton(
                'Clear Database',
                Icons.clear_all,
                _clearDatabase,
                isDestructive: true,
              ),
              
              _buildTestButton(
                'Recreate Database',
                Icons.build,
                _recreateDatabase,
                isDestructive: true,
              ),
              
              const SizedBox(height: 20),
              
              // Medicines List
              Text(
                'Current Medicines (${_medicines.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HexColor(mainColor),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: HexColor(mainColor),
                        ),
                      )
                    : _medicines.isEmpty
                        ? Center(
                            child: Text(
                              'No medicines found',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _medicines.length,
                            itemBuilder: (context, index) {
                              final medicine = _medicines[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.medication,
                                    color: HexColor(mainColor),
                                  ),
                                  title: Text(
                                    medicine.name,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${medicine.dose} • ${medicine.shape} • ${medicine.time}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Icon(
                                    medicine.notificationsEnabled
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                    color: medicine.notificationsEnabled
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onPressed,
          icon: Icon(icon, size: 20),
          label: Text(title),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red : HexColor(mainColor),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}