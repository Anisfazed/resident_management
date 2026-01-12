import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Tempoh 3 saat untuk nampak lebih profesional
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih nampak lebih bersih
      body: Stack(
        children: [
          // Corak hiasan di bahagian atas (opsional - untuk elemen korporat)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.blueGrey.withOpacity(0.05),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO - Gunakan Jata Negara atau Logo Jabatan jika ada
                // Image.asset('assets/images/logo_kerajaan.png', width: 120),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1), // Royal Blue
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded, // Ikon bangunan/institusi
                    size: 70,
                    color: Color(0xFFFFD700), // Warna Emas
                  ),
                ),
                const SizedBox(height: 30),
                
                // Tajuk Utama
                const Text(
                  "SISTEM MAKLUMAT PENDUDUK",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1A237E), // Navy Blue
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                
                // Garisan Pemisah Kecil (Elemen Design Kerajaan)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 2,
                  width: 40,
                  color: const Color(0xFFFFD700), // Garis Emas
                ),
                
                const Text(
                  "PENGURUSAN PROFIL DIGITAL",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Loading yang lebih korporat
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                  ),
                ),
              ],
            ),
          ),
          
          // Bahagian Bawah (Footer)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Versi 1.0.0",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Text(
                  "HAK CIPTA TERPELIHARA © 2024",
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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