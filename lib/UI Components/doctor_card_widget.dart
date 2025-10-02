import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Utils/main_variables.dart';

class DoctorCardWidget extends StatelessWidget {
  final String img;
  final String doctorName;
  final String doctorTitle;
  final VoidCallback? onTap;

  const DoctorCardWidget({
    Key? key,
    required this.img,
    required this.doctorName,
    required this.doctorTitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {
          // Default navigation to doctor details
          Navigator.pushNamed(context, '/doctor-detail', arguments: {
            'name': doctorName,
            'title': doctorTitle,
            'image': img,
          });
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: HexColor(mainColor).withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: img.startsWith('http') 
                    ? Image.network(
                        img,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image(
                            width: 80,
                            height: 80,
                            image: AssetImage('assets/person.png'),
                            fit: BoxFit.cover,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: HexColor(mainColor).withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: HexColor(mainColor),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Image(
                        width: 80,
                        height: 80,
                        image: AssetImage(img),
                        fit: BoxFit.cover,
                      ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: GoogleFonts.montserrat(
                        color: HexColor(mainColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      doctorTitle,
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.0 - 50 Reviews',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: HexColor(mainColor),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
