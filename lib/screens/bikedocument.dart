import 'package:bikeservice/screens/certificates/BikeInsurence.dart';
import 'package:bikeservice/screens/certificates/Rccertificate.dart';
import 'package:bikeservice/screens/certificates/serviceBill.dart';
import 'package:flutter/material.dart';

class Bikedocument extends StatefulWidget {
  const Bikedocument({super.key});

  @override
  State<Bikedocument> createState() => _BikedocumentState();
}

class _BikedocumentState extends State<Bikedocument> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text('Document Wallet', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF070B14),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            documentCard(
              icon: Icons.app_registration,
              title: 'Registration Certificate',
              subtitle: 'Upload Rc Book',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationCertificatePage(),
                  ),
                );
              },
            ),
            SizedBox(height: 15),
            documentCard(
              icon: Icons.shield_outlined,
              title: 'Bike Insurance',
              subtitle: 'upload Insurance',
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BikeInsurancePage(),
                  ),
                );
              },
            ),
            SizedBox(height: 15),
            documentCard(
              icon: Icons.receipt_outlined,
              title: 'Service bills',
              subtitle: 'upload Service bills',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceBillsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget documentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      color: const Color(0xFF111827),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
      ),




      
    );
  }
}
