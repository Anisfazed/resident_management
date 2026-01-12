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

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  // 1. MEMUAT DATA
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

  // 2. FUNGSI PADAM
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

  void _goToAddResident() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddResidentPage()),
    );
    if (result == true) {
      _loadResidents();
    }
  }

  // 4. EKSPORT KE PDF
  Future<void> _exportToPdf() async {
    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tiada data untuk dieksport"))
      );
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
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text("LAPORAN PROFIL PENDUDUK KESELURUHAN", 
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['Mukim', 'Kampung', 'Nama KIR', 'Telefon', 'Pendapatan', 'Bantuan'],
              data: sortedList.map((r) => [
                r.mukim ?? "-",
                r.kampung ?? "-",
                r.name,
                r.phone,
                r.incomeRange ?? "-",
                r.bantuan?.join(", ") ?? "-"
              ]).toList(),
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Penduduk_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint("Ralat PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Penduduk"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf), 
            tooltip: "Eksport PDF",
            onPressed: _exportToPdf
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _loadResidents
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterResidents,
              decoration: InputDecoration(
                hintText: "Cari nama, telefon, atau mukim...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadResidents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final resident = filteredList[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                // ListTile tidak boleh ditekan secara keseluruhan
                                onTap: null, 
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey,
                                  child: Text(
                                    resident.name.isNotEmpty ? resident.name[0].toUpperCase() : "?", 
                                    style: const TextStyle(color: Colors.white)
                                  ),
                                ),
                                title: Text(resident.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("KIR • ${resident.mukim ?? 'N/A'} • ${resident.phone}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Butang Padam
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteResident(resident.id.toString()),
                                    ),
                                    // Butang Chevron untuk ke Details (Sahaja yang boleh klik)
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, color: Colors.grey),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ResidentDetailsPage(residentData: resident)
                                          ),
                                        );
                                        _loadResidents();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddResident,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? "Tiada data penduduk" : "Tiada hasil untuk '$searchQuery'", 
            style: const TextStyle(color: Colors.grey)
          ),
          if (searchQuery.isEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                onPressed: _goToAddResident, 
                child: const Text("Tambah Sekarang")
              ),
            ),
        ],
      ),
    );
  }
}