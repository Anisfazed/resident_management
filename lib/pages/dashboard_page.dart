import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; 
import '../models/resident_model.dart';
import '../myconfig.dart';
import 'add_resident_page.dart';
import 'resident_details_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Resident> residentList = [];
  List<Resident> filteredList = [];
  bool isLoading = true;
  String searchQuery = "";

  // Warna Tema Rasmi (Navy & Gold)
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color navyBlue = const Color(0xFF1A237E);
  final Color goldAccent = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  // 1. MEMUAT DATA DARI SERVER
  Future<void> _loadResidents() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final String url = "${MyConfig.myurl}/dataresidents/load_residents.php";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          var list = data['data'] as List;
          setState(() {
            residentList = list.map((json) => Resident.fromJson(json)).toList();
            filteredList = residentList;
          });
        } else {
          setState(() {
            residentList = [];
            filteredList = [];
          });
        }
      }
    } catch (e) {
      debugPrint("Ralat memuat data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2. FUNGSI PADAM REKOD
  Future<void> _deleteResident(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sahkan Padam"),
        content: const Text("Adakah anda pasti mahu memadam data ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Padam", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse("${MyConfig.myurl}/dataresidents/delete_resident.php"),
          body: {"resident_id": id},
        );
        
        if (response.statusCode == 200) {
          setState(() {
            residentList.removeWhere((resident) => resident.id.toString() == id);
            filteredList.removeWhere((resident) => resident.id.toString() == id);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data berjaya dipadam"))
            );
          }
        }
      } catch (e) {
        debugPrint("Ralat padam: $e");
      }
    }
  }

  // 3. FUNGSI CARIAN
  void _filterResidents(String query) {
    setState(() {
      searchQuery = query;
      filteredList = residentList.where((resident) {
        final nameMatch = resident.name.toLowerCase().contains(query.toLowerCase());
        final phoneMatch = resident.phone.contains(query);
        final mukimMatch = (resident.mukim ?? "").toLowerCase().contains(query.toLowerCase());
        return nameMatch || phoneMatch || mukimMatch;
      }).toList();
    });
  }

  // 4. EKSPORT KE PDF (LANDSCAPE)
  Future<void> _exportToPdf() async {
    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tiada data untuk dieksport")));
      return;
    }

    final pdf = pw.Document();
    List<Resident> sortedList = List.from(filteredList);
    sortedList.sort((a, b) => (a.mukim ?? "").compareTo(b.mukim ?? ""));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Center(
              child: pw.Text("LAPORAN PROFIL PENDUDUK DIGITAL", 
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Mukim', 'Kampung', 'Nama KIR', 'Telefon', 'Pendapatan', 'Bantuan'],
            data: sortedList.map((r) => [
              r.mukim ?? "-",
              r.kampung ?? "-",
              r.name.toUpperCase(),
              r.phone,
              r.incomeRange ?? "-",
              r.bantuan?.join(", ") ?? "-"
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("SISTEM PENDUDUK", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportToPdf),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResidents),
        ],
      ),
      body: Column(
        children: [
          // Header Statistik
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: navyBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderStat("REKOD", filteredList.length.toString()),
                _buildHeaderStat("MUKIM", _getUniqueMukimCount().toString()),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterResidents,
              decoration: InputDecoration(
                hintText: "Cari nama, telefon, atau mukim...",
                prefixIcon: Icon(Icons.search, color: primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List Data
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue))
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadResidents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final resident = filteredList[index];
                            return _buildResidentCard(resident);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddResidentPage()));
          if (result == true) _loadResidents();
        },
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("TAMBAH KIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget Kad Penduduk yang telah direka semula
  Widget _buildResidentCard(Resident resident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: null, // Menutup fungsi klik pada keseluruhan kad
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withOpacity(0.1),
          child: Text(resident.name[0].toUpperCase(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        ),
        title: Text(resident.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
        subtitle: Text("${resident.mukim ?? 'N/A'} • ${resident.phone}", style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteResident(resident.id.toString()),
            ),
            const SizedBox(width: 4),
            // HANYA butang ini yang boleh ke details
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 18),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResidentDetailsPage(residentData: resident)),
                );
                _loadResidents();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: goldAccent, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
      ],
    );
  }

  int _getUniqueMukimCount() {
    return residentList.map((r) => r.mukim).toSet().length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(searchQuery.isEmpty ? "Tiada rekod penduduk." : "Tiada hasil ditemukan.", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}