import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/resident_model.dart';
import 'add_resident_page.dart';

class ResidentDetailsPage extends StatefulWidget {
  final Resident residentData;

  const ResidentDetailsPage({super.key, required this.residentData});

  @override
  State<ResidentDetailsPage> createState() => _ResidentDetailsPageState();
}

class _ResidentDetailsPageState extends State<ResidentDetailsPage> {
  late Resident currentResident;

  // Warna Tema Konsisten
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color navyBlue = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    currentResident = widget.residentData;
  }

  /// Generates a PDF of the specific resident details
  Future<void> _exportResidentToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text("PROFIL RASMI PENDUDUK",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Nama: ${currentResident.name.toUpperCase()}"),
          pw.Text("ID Penduduk: #RES-${currentResident.id}"),
          pw.Divider(),
          pw.SizedBox(height: 15),
          pw.Text("MAKLUMAT KETUA ISI RUMAH", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Bullet(text: "Umur: ${currentResident.age}"),
          pw.Bullet(text: "No. Telefon: ${currentResident.phone}"),
          pw.Bullet(text: "Alamat: ${currentResident.address}"),
          pw.Bullet(text: "Mukim/Kampung: ${currentResident.mukim} / ${currentResident.kampung}"),
          pw.Bullet(text: "Pendapatan: ${currentResident.incomeRange}"),
          pw.Bullet(text: "Bantuan: ${currentResident.bantuan?.join(', ') ?? '-'}"),
          pw.SizedBox(height: 25),
          pw.Text("SENARAI AHLI ISI RUMAH", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          if (currentResident.householdMembers.isEmpty)
            pw.Text("Tiada ahli isi rumah didaftarkan.")
          else
            pw.TableHelper.fromTextArray(
              headers: ['Nama', 'Hubungan', 'Umur', 'Status'],
              data: currentResident.householdMembers
                  .map((m) => [m.name.toUpperCase(), m.relation, m.age, m.status])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 40),
              child: pw.Text("Tarikh Cetakan: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Profil_${currentResident.name.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("PROFIL PENDUDUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddResidentPage(existingResident: currentResident),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card
            _buildProfileHeader(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Maklumat Peribadi"),
                  _buildDetailsCard(),
                  
                  const SizedBox(height: 24),
                  
                  _sectionTitle("Senarai Ahli Isi Rumah"),
                  _buildHouseholdTable(),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("CETAK PROFIL (PDF)", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _exportResidentToPdf,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: navyBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              currentResident.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            currentResident.name.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            "ID: #RES-${currentResident.id}",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: navyBlue, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.cake, "Umur", "${currentResident.age} Tahun"),
            _infoRow(Icons.phone_android, "No. Telefon", currentResident.phone),
            _infoRow(Icons.location_on_outlined, "Alamat", currentResident.address),
            _infoRow(Icons.map_outlined, "Mukim / Kampung", "${currentResident.mukim} / ${currentResident.kampung}"),
            _infoRow(Icons.payments_outlined, "Pendapatan", currentResident.incomeRange),
            _infoRow(Icons.handshake_outlined, "Bantuan", currentResident.bantuan?.join(", ") ?? "-"),
            const Divider(),
            _infoRow(Icons.update, "Kemaskini Terakhir", currentResident.lastUpdate, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdTable() {
    if (currentResident.householdMembers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text("Tiada ahli isi rumah berdaftar.", 
          textAlign: TextAlign.center, 
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(label: Text("NAMA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("HUBUNGAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("UMUR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: currentResident.householdMembers.map((m) {
              return DataRow(cells: [
                DataCell(Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 11))),
                DataCell(Text(m.relation, style: const TextStyle(fontSize: 11))),
                DataCell(Text(m.age, style: const TextStyle(fontSize: 11))),
                DataCell(Text(m.status, style: const TextStyle(fontSize: 11))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value ?? "-", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}