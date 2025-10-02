import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../Utils/main_variables.dart';

class SimpleEmptyState extends StatelessWidget {
  const SimpleEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Empty State Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: HexColor(mainColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 60,
                color: HexColor(mainColor).withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'No Heart Medications Added',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HexColor(mainColor),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Start by adding your heart medications to track your cardiovascular health journey and never miss a dose.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            _buildFeatureItem(
              Icons.notifications,
              'Smart Reminders',
              'Get notified when it\'s time to take your medicine',
            ),
            
            _buildFeatureItem(
              Icons.track_changes,
              'Track Progress',
              'Monitor your medication schedule and adherence',
            ),
            
            _buildFeatureItem(
              Icons.health_and_safety,
              'Health Insights',
              'Get personalized health recommendations',
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HexColor(mainColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: HexColor(mainColor),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HexColor(mainColor),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}