import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Utils/image_preloader.dart';
import '../../Utils/main_variables.dart';
import '../../data/models/doctor_model.dart';
import '../../data/services/api_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({Key? key}) : super(key: key);

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  List<DoctorModel> doctors = [];
  List<DoctorModel> filteredDoctors = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterDoctors();
    });
  }

  void _filterDoctors() {
    if (searchQuery.isEmpty) {
      filteredDoctors = List.from(doctors);
    } else {
      filteredDoctors = doctors.where((doctor) {
        final name = doctor.fullName.toLowerCase();
        final specialization = doctor.specialization?.toLowerCase() ?? '';
        final description = doctor.description?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        
        return name.contains(query) || 
               specialization.contains(query) || 
               description.contains(query);
      }).toList();
    }
  }

  Future<void> _loadDoctors() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Preload specific images while API is loading
      final imagePreloadFuture = Future.wait([
        ImagePreloader.preloadSingleImage(context, "assets/Images/background.jpg"),
        ImagePreloader.preloadSingleImage(context, "assets/medicine_images/Doctor.png"),
      ]);

      // Load both API data and images in parallel
      final results = await Future.wait([
        _apiService.getDoctorsList(),
        imagePreloadFuture,
      ]);

      final doctorsList = results[0] as List<DoctorModel>;
      print('Loaded ${doctorsList.length} doctors from API');
      for (var doctor in doctorsList) {
        print('Doctor: ${doctor.fullName} - ${doctor.specialization}');
      }
      
      setState(() {
        doctors = doctorsList;
        filteredDoctors = List.from(doctorsList);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              // Title
              Text(
                'Find a Doctor',
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: HexColor(mainColor),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              // Search Bar
              SearchBar(controller: _searchController),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              // Information Banner
              InformationBanner(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              // Available Doctors Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Doctors',
                    style: GoogleFonts.montserrat(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: HexColor(mainColor),
                    ),
                  ),
                  if (!isLoading && filteredDoctors.length > 0)
                    Text(
                      '${filteredDoctors.length} Doctors',
                      style: GoogleFonts.montserrat(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: HexColor(mainColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              // Doctor Grid - Now scrollable with the rest of the screen
              _buildDoctorsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsGrid() {
    if (isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: HexColor(mainColor),
              ),
              SizedBox(height: 16),
              Text(
                'Loading doctors...',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Text(
              'Failed to load doctors from API',
              style: GoogleFonts.montserrat(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your internet connection',
              style: GoogleFonts.montserrat(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDoctors,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor(mainColor),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredDoctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              if (searchQuery.isNotEmpty)
                Text(
                  'No doctors found for "$searchQuery"',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                )
              else
                Text(
                  'No doctors available',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              if (searchQuery.isNotEmpty) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  child: Text(
                    'Clear search',
                    style: GoogleFonts.montserrat(
                      color: HexColor(mainColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Create a grid layout using Wrap
        Wrap(
          spacing: MediaQuery.of(context).size.width * 0.04,
          runSpacing: MediaQuery.of(context).size.height * 0.02,
          children: filteredDoctors.map((doctor) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 
                     MediaQuery.of(context).size.width * 0.1 - 
                     MediaQuery.of(context).size.width * 0.04) / 2,
              child: DoctorCard(
                img: doctor.imageUrl ?? 'assets/person.png',
                doctorName: doctor.capitalizedFullName,
                doctorTitle: doctor.specialization ?? 'General Practitioner',
                rating: 4.5, // Default rating since API doesn't provide it
              ),
            );
          }).toList(),
        ),
        // Add bottom padding for better scrolling experience
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  
  const SearchBar({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.06,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Icon(
            Icons.search,
            color: Colors.grey[400],
            size: MediaQuery.of(context).size.width * 0.05,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Find doctor',
                hintStyle: GoogleFonts.montserrat(
                  color: Colors.grey[500],
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InformationBanner extends StatelessWidget {
  const InformationBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: ImagePreloader.getImage("assets/Images/background.jpg"),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        decoration: BoxDecoration(
          color: HexColor(mainColor).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Why is it important to do check-ups?',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.width * 0.2,
              child: Image.asset(
                'assets/medicine_images/Doctor.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width * 0.1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String img;
  final String doctorName;
  final String doctorTitle;
  final double rating;

  const DoctorCard({
    Key? key,
    required this.img,
    required this.doctorName,
    required this.doctorTitle,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.045),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section with image and text
          Column(
            children: [
              // Image section with full-width background
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background area - full width, half height of circle
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 0.09, // Half of circle height
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: ImagePreloader.getImage("assets/Images/background.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: HexColor(mainColor).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  // Circular Profile Image
                  Container(
                    width: MediaQuery.of(context).size.width * 0.18,
                    height: MediaQuery.of(context).size.width * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: img.startsWith('http') 
                        ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: MediaQuery.of(context).size.width * 0.09,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: HexColor(mainColor),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: MediaQuery.of(context).size.width * 0.09,
                                ),
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              // Doctor Name
              Text(
                doctorName,
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.032,
                  fontWeight: FontWeight.bold,
                  color: HexColor(mainColor),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              // Doctor Specialty
              Text(
                doctorTitle,
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.028,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Connect Button at bottom
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.045,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: HexColor(mainColor),
                width: 1.5,
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Handle connect action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: HexColor(mainColor),
                    size: MediaQuery.of(context).size.width * 0.033,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.013),
                  Text(
                    'Connect',
                    style: GoogleFonts.montserrat(
                      fontSize: MediaQuery.of(context).size.width * 0.031,
                      fontWeight: FontWeight.w600,
                      color: HexColor(mainColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




