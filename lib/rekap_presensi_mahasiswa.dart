import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RekapPresensiMahasiswaFiltered extends StatefulWidget {
  const RekapPresensiMahasiswaFiltered({Key? key}) : super(key: key);

  @override
  _RekapPresensiMahasiswaFilteredState createState() =>
      _RekapPresensiMahasiswaFilteredState();
}

class _RekapPresensiMahasiswaFilteredState
    extends State<RekapPresensiMahasiswaFiltered> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? selectedTanggal;
  String? selectedMatkul;
  String? selectedStudent;
  String? selectedClass;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedTanggal)
      setState(() {
        selectedTanggal = picked;
      });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPresensiStream() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('presensi').where('dosen_id', isEqualTo: null);

    if (selectedStudent != null && selectedStudent!.isNotEmpty) {
      query = query.where('student_id', isEqualTo: selectedStudent);
    }
    if (selectedClass != null && selectedClass!.isNotEmpty) {
      query = query.where('class_id', isEqualTo: selectedClass);
    }
    if (selectedTanggal != null) {
      DateTime startOfDay = DateTime(
          selectedTanggal!.year, selectedTanggal!.month, selectedTanggal!.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));
      query = query
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Nama
            TextField(
              decoration: InputDecoration(
                labelText: 'Cari Nama',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  selectedStudent =
                      value.trim(); // Remove leading/trailing spaces
                });
              },
            ),
            SizedBox(height: 16),
            // Filter Kelas dan Tanggal
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Pilih Tingkat',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClass,
                    items: <String>[
                      '1',
                      '2',
                      '3',
                      '4',
                    ] // Ganti dengan kelas yang sesuai
                        .map((kelas) => DropdownMenuItem<String>(
                              value: kelas,
                              child: Text(kelas),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedTanggal != null
                                ? DateFormat('d MMMM yyyy')
                                    .format(selectedTanggal!)
                                : 'Pilih Tanggal',
                          ),
                          Spacer(),
                          Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Daftar Presensi
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getPresensiStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var jadwalList = snapshot.data?.docs
                          .map((doc) => {'id': doc.id, ...doc.data()})
                          .toList() ??
                      [];

                  return ListView.builder(
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      var jadwal = jadwalList[index];

                      DateTime? dateTime;
                      if (jadwal['tanggal'] != null) {
                        dateTime = (jadwal['tanggal'] as Timestamp).toDate();
                      }

                      return Card(
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8.0),
                          title: Row(
                            children: [
                              // Menampilkan gambar wajah
                              jadwal['face_image'] != null
                                  ? Image.network(
                                      jadwal['face_image'],
                                      width: 50, // Lebar gambar
                                      height: 50, // Tinggi gambar
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey,
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                              SizedBox(width: 10),
                              // Menampilkan informasi lainnya
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${jadwal['student_id'] ?? 'Unknown Student'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Kelas: ${jadwal['class_id'] ?? 'Unknown Class'}',
                                    ),
                                    Text(
                                      'Mata Kuliah: ${jadwal['matkul_id'] ?? 'Unknown Matkul'}',
                                    ),
                                    Text(
                                      'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}',
                                    ),
                                    if (dateTime != null)
                                      Text(
                                        'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
