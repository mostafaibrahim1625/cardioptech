import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../Utils/google_auth_test.dart';
import '../../Utils/main_variables.dart';

class GoogleAuthTestScreen extends StatefulWidget {
  const GoogleAuthTestScreen({super.key});

  @override
  State<GoogleAuthTestScreen> createState() => _GoogleAuthTestScreenState();
}

class _GoogleAuthTestScreenState extends State<GoogleAuthTestScreen> {
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  Map<String, dynamic>? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await GoogleAuthTest.getCurrentStatus();
      setState(() {
        _currentStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _isLoading = true);
    try {
      final results = await GoogleAuthTest.runAllTests();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await GoogleAuthTest.testSignInFlow();
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
      
      // Reload status after sign in
      _loadCurrentStatus();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSignOut() async {
    setState(() => _isLoading = true);
    try {
      final result = await GoogleAuthTest.testSignOutFlow();
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
      
      // Reload status after sign out
      _loadCurrentStatus();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Google Auth Test',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: HexColor(mainColor),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status Section
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  
                  // Test Buttons Section
                  _buildTestButtonsSection(),
                  const SizedBox(height: 20),
                  
                  // Test Results Section
                  if (_testResults != null) _buildTestResultsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HexColor(mainColor),
              ),
            ),
            const SizedBox(height: 12),
            if (_currentStatus != null) ...[
              _buildStatusItem('Google Signed In', _currentStatus!['google_signed_in']),
              _buildStatusItem('Firebase Signed In', _currentStatus!['firebase_signed_in']),
              if (_currentStatus!['google_user_email'] != null)
                _buildStatusItem('Google User Email', _currentStatus!['google_user_email']),
              if (_currentStatus!['firebase_user_email'] != null)
                _buildStatusItem('Firebase User Email', _currentStatus!['firebase_user_email']),
              if (_currentStatus!['firebase_user_uid'] != null)
                _buildStatusItem('Firebase User UID', _currentStatus!['firebase_user_uid']),
            ] else
              const Text('Loading status...'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: GoogleFonts.montserrat(
                color: value == true ? Colors.green : 
                       value == false ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtonsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Actions',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HexColor(mainColor),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _runAllTests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor(mainColor),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Run All Tests'),
                ),
                ElevatedButton(
                  onPressed: _testSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Sign In'),
                ),
                ElevatedButton(
                  onPressed: _testSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Sign Out'),
                ),
                ElevatedButton(
                  onPressed: _loadCurrentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HexColor(mainColor),
              ),
            ),
            const SizedBox(height: 12),
            if (_testResults!['overall_success'] == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'All tests passed!',
                      style: GoogleFonts.montserrat(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Some tests failed',
                      style: GoogleFonts.montserrat(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ..._testResults!.entries
                .where((entry) => entry.key != 'overall_success')
                .map((entry) => _buildTestResultItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultItem(String testName, dynamic result) {
    if (result is! Map) return const SizedBox.shrink();
    
    final success = result['success'] == true;
    final message = result['message'] ?? 'No message';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$testName: $message',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: success ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
