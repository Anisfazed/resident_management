import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/resident_model.dart';
import '../models/household_model.dart';
import '../myconfig.dart'; // Import your config file

class AddResidentPage extends StatefulWidget {
  final Resident? existingResident;

  const AddResidentPage({super.key, this.existingResident});

  @override
  State<AddResidentPage> createState() => _AddResidentPageState();
}

class _AddResidentPageState extends State<AddResidentPage> {
  // ... (controllers and variables stay the same)
  final TextEditingController kirNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();

  bool isLoading = false;
  String selectedMukim = "Temin";
  String selectedKampung = "Kampung Baru Jitra";

  final List<String> mukimList = [
    "Temin", "Tunjang", "Padang Perahu", "Sungai Laka", "Keplu",
  ];

  final Map<String, List<String>> kampungByMukim = {
    "Temin": ["Kampung Baru Jitra", "Kampung Teluk Malau", "Kampung Padang"],
    "Tunjang": ["Kampung Tunjang", "Kampung Padang Lalang", "Kampung Pulau Ketam"],
    "Padang Perahu": ["Kampung Padang Perahu", "Kampung Melele"],
    "Sungai Laka": ["Kampung Gelung Chinchu", "Kampung Changkat Setol", "Bukit Kayu Hitam"],
    "Keplu": ["Kampung Keplu", "Kampung Megat Dewa"],
  };

  Map<String, bool> bantuanList = {
    "Zakat": false,
    "Bantuan Kerajaan": false,
    "NGO": false,
    "Baitulmal": false,
  };

  List<HouseholdMember> householdMembers = [];
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberAgeController = TextEditingController();
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
      incomeController.text = r.incomeRange;
      selectedMukim = r.mukim ?? "Mukim A";
      selectedKampung = r.kampung ?? "Kampung 1";
      if (r.bantuan != null) {
        for (var b in r.bantuan!) {
          if (bantuanList.containsKey(b)) bantuanList[b] = true;
        }
      }
      householdMembers = List.from(r.householdMembers);
    }
  }

  Future<void> _saveResident() async {
    if (kirNameController.text.isEmpty) return;

    setState(() => isLoading = true);

    String bantuanString = bantuanList.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(",");

    String householdJson = jsonEncode(householdMembers.map((m) => m.toJson()).toList());

    try {
      final bool isEdit = widget.existingResident != null;
      
      // Concatenate your MyConfig.myurl with the folder and filename
      final String folderPath = "${MyConfig.myurl}dataresidents/";
      final String url = isEdit 
          ? "${folderPath}update_resident.php" 
          : "${folderPath}register_resident.php";

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

      if (isEdit) body["id"] = widget.existingResident!.id!;

      final response = await http.post(Uri.parse(url), body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Navigator.pop(context, true); 
        } else {
          _showError(data['message']);
        }
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error connecting to server: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ... (Rest of the dialog and build methods stay exactly as they were)
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
          title: Text(member == null ? "Tambah Ahli" : "Edit Ahli"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: memberNameController, decoration: const InputDecoration(labelText: "Nama")),
              TextField(controller: memberAgeController, decoration: const InputDecoration(labelText: "Umur"), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: memberRelation,
                items: relationOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDialogState(() => memberRelation = v!),
                decoration: const InputDecoration(labelText: "Hubungan"),
              ),
              DropdownButtonFormField<String>(
                value: memberStatus,
                items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => memberStatus = v!),
                decoration: const InputDecoration(labelText: "Status"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                if (memberNameController.text.isEmpty) return;
                final newMember = HouseholdMember(
                  name: memberNameController.text,
                  age: memberAgeController.text,
                  relation: memberRelation,
                  status: memberStatus,
                );
                setState(() {
                  if (index != null) {
                    householdMembers[index] = newMember;
                  } else {
                    householdMembers.add(newMember);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(member == null ? "Tambah" : "Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingResident == null ? "Tambah Penduduk" : "Edit Penduduk"),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Maklumat Ketua Isi Rumah (KIR)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(controller: kirNameController, decoration: const InputDecoration(labelText: "Nama KIR")),
                  TextField(controller: ageController, decoration: const InputDecoration(labelText: "Umur KIR"), keyboardType: TextInputType.number),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: "No Telefon")),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: "Alamat"), maxLines: 2),
                  DropdownButtonFormField<String>(
                    value: selectedMukim,
                    items: mukimList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() {
                      selectedMukim = v!;
                      selectedKampung = kampungByMukim[v]!.first;
                    }),
                    decoration: const InputDecoration(labelText: "Mukim"),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedKampung,
                    items: kampungByMukim[selectedMukim]!.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => selectedKampung = v!),
                    decoration: const InputDecoration(labelText: "Kampung"),
                  ),
                  DropdownButtonFormField<String>(
                    value: incomeController.text.isEmpty ? "< RM1,000" : (["< RM1,000", "RM1,001 – RM2,000", "> RM3,000"].contains(incomeController.text) ? incomeController.text : "< RM1,000"),
                    items: ["< RM1,000", "RM1,001 – RM2,000", "> RM3,000"].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                    onChanged: (v) => setState(() => incomeController.text = v!),
                    decoration: const InputDecoration(labelText: "Pendapatan Bulanan"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Jenis Bantuan Pernah Diterima", style: TextStyle(fontWeight: FontWeight.bold)),
          Column(
            children: bantuanList.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: bantuanList[key],
                onChanged: (value) => setState(() => bantuanList[key] = value!),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ahli Isi Rumah", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text("Tambah Ahli"), onPressed: () => showAddMemberDialog()),
            ],
          ),
          const SizedBox(height: 10),
          householdMembers.isEmpty
              ? const Text("Tiada ahli isi rumah")
              : Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: householdMembers.length,
                    itemBuilder: (context, index) {
                      final m = householdMembers[index];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Text("${m.relation} • ${m.age} tahun"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showAddMemberDialog(member: m, index: index)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => householdMembers.removeAt(index))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveResident,
              child: Text(widget.existingResident == null ? "Simpan Maklumat Penduduk" : "Kemaskini Maklumat"),
            ),
          ),
        ]),
      ),
    );
  }
}