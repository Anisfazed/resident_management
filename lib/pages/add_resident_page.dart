import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/resident_model.dart';
import '../models/household_model.dart';
import '../myconfig.dart';

class AddResidentPage extends StatefulWidget {
  final Resident? existingResident;

  const AddResidentPage({super.key, this.existingResident});

  @override
  State<AddResidentPage> createState() => _AddResidentPageState();
}

class _AddResidentPageState extends State<AddResidentPage> {
  // Warna Tema (Selari dengan Dashboard)
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color navyBlue = const Color(0xFF1A237E);

  final TextEditingController kirNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberAgeController = TextEditingController();

  bool isLoading = false;
  String selectedMukim = "Temin";
  String selectedKampung = "Kampung Baru Jitra";

  final List<String> mukimList = ["Temin", "Tunjang", "Padang Perahu", "Sungai Laka", "Keplu"];
  final Map<String, List<String>> kampungByMukim = {
    "Temin": ["Kampung Baru Jitra", "Kampung Teluk Malau", "Kampung Padang"],
    "Tunjang": ["Kampung Tunjang", "Kampung Padang Lalang", "Kampung Pulau Ketam"],
    "Padang Perahu": ["Kampung Padang Perahu", "Kampung Melele"],
    "Sungai Laka": ["Kampung Gelung Chinchu", "Kampung Changkat Setol", "Bukit Kayu Hitam"],
    "Keplu": ["Kampung Keplu", "Kampung Megat Dewa"],
  };

  Map<String, bool> bantuanList = {
    "Zakat": false, "Bantuan Kerajaan": false, "NGO": false, "Baitulmal": false,
  };

  List<HouseholdMember> householdMembers = [];
  String memberRelation = "Anak";
  String memberStatus = "Masih Belajar";

  final List<String> relationOptions = ["Isteri", "Anak", "Ibu Kandung", "Bapa Kandung", "Lain-lain"];
  final List<String> statusOptions = ["Bekerja","Tidak Bekerja", "Masih Belajar", "Suri Rumah", "Buruh", "Pesara"];

  @override
  void initState() {
    super.initState();
    if (widget.existingResident != null) {
      final r = widget.existingResident!;
      kirNameController.text = r.name;
      ageController.text = r.age.toString();
      phoneController.text = r.phone;
      addressController.text = r.address;
      incomeController.text = r.incomeRange ?? "< RM1,000";
      selectedMukim = r.mukim ?? "Temin";
      selectedKampung = r.kampung ?? "Kampung Baru Jitra";
      
      if (r.bantuan != null) {
        for (var b in r.bantuan!) {
          if (bantuanList.containsKey(b)) bantuanList[b] = true;
        }
      }
      householdMembers = List.from(r.householdMembers);
    } else {
      incomeController.text = "< RM1,000";
    }
  }

  // --- LOGIK SIMPAN (Kekal Sama) ---
  Future<void> _saveResident() async {
    if (kirNameController.text.isEmpty) {
      _showError("Sila masukkan nama KIR");
      return;
    }
    setState(() => isLoading = true);
    String bantuanString = bantuanList.entries.where((e) => e.value).map((e) => e.key).join(",");
    String householdJson = jsonEncode(householdMembers.map((m) => m.toJson()).toList());

    try {
      final bool isEdit = widget.existingResident != null;
      final String baseUrl = MyConfig.myurl.endsWith('/') ? MyConfig.myurl : "${MyConfig.myurl}/";
      final String endpoint = isEdit ? "update_resident.php" : "register_resident.php";
      final String url = "${baseUrl}dataresidents/$endpoint";

      final Map<String, String> body = {
        "name": kirNameController.text,
        "age": ageController.text,
        "phone": phoneController.text,
        "address": addressController.text,
        "incomeRange": incomeController.text,
        "mukim": selectedMukim,
        "kampung": selectedKampung,
        "bantuan": bantuanString,
        "household": householdJson,
      };
      if (isEdit) body["resident_id"] = widget.existingResident!.id!;

      final response = await http.post(Uri.parse(url), body: body).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) Navigator.pop(context, true); 
        else _showError(data['message'] ?? "Gagal menyimpan data");
      }
    } catch (e) {
      _showError("Ralat Sambungan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI DIALOG (Kekal Sama tetapi ditambah gaya) ---
  void showAddMemberDialog({HouseholdMember? member, int? index}) {
    if (member != null) {
      memberNameController.text = member.name;
      memberAgeController.text = member.age;
      memberRelation = member.relation;
      memberStatus = member.status;
    } else {
      memberNameController.clear();
      memberAgeController.clear();
      memberRelation = relationOptions.first;
      memberStatus = statusOptions.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(member == null ? "Tambah Ahli Keluarga" : "Edit Ahli Keluarga", 
              style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(memberNameController, "Nama Penuh", Icons.person),
                _buildTextField(memberAgeController, "Umur", Icons.cake, isNumber: true),
                _buildDropdown(memberRelation, relationOptions, "Hubungan", (v) => setDialogState(() => memberRelation = v!)),
                _buildDropdown(memberStatus, statusOptions, "Status Pekerjaan", (v) => setDialogState(() => memberStatus = v!)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () {
                if (memberNameController.text.isEmpty) return;
                final newMember = HouseholdMember(
                  name: memberNameController.text,
                  age: memberAgeController.text,
                  relation: memberRelation,
                  status: memberStatus,
                );
                setState(() {
                  if (index != null) householdMembers[index] = newMember;
                  else householdMembers.add(newMember);
                });
                Navigator.pop(context);
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existingResident == null ? "PENDAFTARAN BARU" : "KEMASKINI DATA"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryBlue))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionTitle("Maklumat Ketua Isi Rumah (KIR)"),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildTextField(kirNameController, "Nama Penuh KIR", Icons.badge),
                    Row(children: [
                      Expanded(child: _buildTextField(ageController, "Umur", Icons.calendar_today, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField(phoneController, "No. Telefon", Icons.phone, isNumber: true)),
                    ]),
                    _buildTextField(addressController, "Alamat Kediaman", Icons.home, maxLines: 2),
                    _buildDropdown(selectedMukim, mukimList, "Pilih Mukim", (v) {
                      setState(() {
                        selectedMukim = v!;
                        selectedKampung = kampungByMukim[v]!.first;
                      });
                    }),
                    _buildDropdown(selectedKampung, kampungByMukim[selectedMukim]!, "Pilih Kampung", (v) => setState(() => selectedKampung = v!)),
                    _buildDropdown(incomeController.text, ["< RM1,000", "RM1,001 – RM2,000", "> RM3,000"], "Kategori Pendapatan", (v) => setState(() => incomeController.text = v!)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("Bantuan Yang Pernah Diterima"),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: bantuanList.keys.map((key) {
                    return CheckboxListTile(
                      activeColor: primaryBlue,
                      title: Text(key, style: const TextStyle(fontSize: 14)),
                      value: bantuanList[key],
                      onChanged: (value) => setState(() => bantuanList[key] = value!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Ahli Isi Rumah"),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Tambah Ahli"),
                    onPressed: () => showAddMemberDialog(),
                  ),
                ],
              ),
              _buildHouseholdList(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  onPressed: _saveResident,
                  child: Text(
                    widget.existingResident == null ? "SIMPAN REKOD PENDUDUK" : "KEMASKINI REKOD",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(title.toUpperCase(), 
          style: TextStyle(color: navyBlue, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.list, size: 20, color: primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHouseholdList() {
    if (householdMembers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Tiada ahli isi rumah didaftarkan", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
      );
    }
    return Column(
      children: householdMembers.asMap().entries.map((entry) {
        int idx = entry.key;
        HouseholdMember m = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blueGrey.shade50, child: const Icon(Icons.person_outline, color: Colors.blueGrey)),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${m.relation} • ${m.age} thn • ${m.status}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => showAddMemberDialog(member: m, index: idx)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => householdMembers.removeAt(idx))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}