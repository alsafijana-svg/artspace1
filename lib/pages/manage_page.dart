import 'package:artspace1/pages/artist_reservation_page.dart';
import 'package:artspace1/pages/my_workshop_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ManagePage extends StatelessWidget {
  const ManagePage({Key? key}) : super(key: key);

// Card builder for reuseable cards
  Widget _buildCard({
    //Card properties
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Return styled container as card
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10, // soften the shadow
            offset: const Offset(0, 4), // move 4 down
          ),
        ],
      ),
      
      child: ListTile(// ListTile for easy layout
        contentPadding: 
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: Color(0xFF582C0A), size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Color(0xFF895735), size: 22),
        onTap: onTap,
      ),
    );
  }
// Build method for ManagePage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              const SizedBox(height: 10),

              _buildCard( // My Workshops card
                icon: Icons.edit_note,
                title: "My Workshops".tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyWorkshopPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildCard(
                icon: Icons.people_alt,
                title: "" 
                    "Artist Reservation".tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtistReservationPage (),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
