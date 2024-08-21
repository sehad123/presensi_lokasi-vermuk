import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_app/edit_jadwal.dart';
import 'package:presensi_app/edit_presensi.dart';
import 'package:presensi_app/Dosen/detail_presensi_Dosen.dart';
import 'package:presensi_app/profile/profile_page.dart';

class RekapPresensiDosenFiltered extends StatefulWidget {
  @override
  _RekapPresensiDosenFilteredState createState() =>
      _RekapPresensiDosenFilteredState();
}

class _RekapPresensiDosenFilteredState
    extends State<RekapPresensiDosenFiltered> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? selectedTanggal;
  String? selectedMatkul;
  String? selectedStudent;
  String? selectedClass;
  String? selectedSemester;

  List<String> semesterList = [];
  List<String> kelasList = [];
  List<String> matkulList = [];

  @override
  void initState() {
    super.initState();
    fetchSemesterList();
  }

  Future<void> fetchSemesterList() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('semester').get();
    setState(() {
      semesterList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> fetchKelasList(String semesterId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('class_semester')
        .where('semester_id', isEqualTo: semesterId)
        .get();

    var classIds =
        snapshot.docs.map((doc) => doc['class_id'] as String).toList();

    var classSnapshot = await FirebaseFirestore.instance
        .collection('kelas')
        .where(FieldPath.documentId, whereIn: classIds)
        .get();

    setState(() {
      kelasList = classSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> fetchMatkulList(String classId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('matkul_class')
        .where('class_id', isEqualTo: classId)
        .get();

    var matkulIds = snapshot.docs
        .map((doc) => doc['matkul_id'] as List)
        .expand((x) => x)
        .toList();

    var matkulSnapshot = await FirebaseFirestore.instance
        .collection('matkul')
        .where(FieldPath.documentId, whereIn: matkulIds)
        .get();

    setState(() {
      matkulList =
          matkulSnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  void editPresensi(String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPresensi(docId: docId)),
    ).then((_) => setState(() {})); // Refresh the state after editing
  }

  void deletePresensi(String docId) async {
    await _firestore.collection('presensi').doc(docId).delete();
    // No need to call fetchJadwalList() here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari Nama',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedStudent = value.trim();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSemester,
                    items: semesterList
                        .map((semester) => DropdownMenuItem<String>(
                              value: semester,
                              child: Text(semester),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSemester = value;
                        fetchKelasList(value!);
                        selectedClass = null;
                        matkulList = [];
                        selectedMatkul = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Row for filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Kelas',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClass,
                    items: kelasList
                        .map((kelas) => DropdownMenuItem<String>(
                              value: kelas,
                              child: Text(kelas),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                        fetchMatkulList(value!);
                        selectedMatkul = null;
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
            // Mata Kuliah Filter
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(),
              ),
              value: selectedMatkul,
              items: matkulList
                  .map((matkul) => DropdownMenuItem<String>(
                        value: matkul,
                        child: Text(matkul),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMatkul = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Daftar Presensi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('presensi').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var presensiList = snapshot.data!.docs
                      .map((doc) =>
                          {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                      .where((data) =>
                          data['dosen_id'] != null &&
                          data['dosen_id'] != 'Unknown Dosen')
                      .toList();

                  return ListView.builder(
                    itemCount: presensiList.length,
                    itemBuilder: (context, index) {
                      var presensi = presensiList[index];

                      if (selectedStudent != null &&
                          selectedStudent!.isNotEmpty &&
                          !presensi['dosen_id']
                              .toString()
                              .toLowerCase()
                              .contains(selectedStudent!.toLowerCase())) {
                        return SizedBox.shrink(); // Skip item
                      }

                      if (selectedClass != null &&
                          selectedClass!.isNotEmpty &&
                          presensi['class_id'] != selectedClass) {
                        return SizedBox.shrink(); // Skip item
                      }

                      if (selectedMatkul != null &&
                          selectedMatkul!.isNotEmpty &&
                          presensi['matkul_id'] != selectedMatkul) {
                        return SizedBox.shrink(); // Skip item
                      }

                      if (selectedTanggal != null) {
                        DateTime? dateTime;
                        if (presensi['tanggal'] != null) {
                          dateTime =
                              (presensi['tanggal'] as Timestamp).toDate();
                        }

                        if (dateTime == null ||
                            dateTime.isBefore(DateTime(
                                selectedTanggal!.year,
                                selectedTanggal!.month,
                                selectedTanggal!.day)) ||
                            dateTime.isAfter(DateTime(
                                selectedTanggal!.year,
                                selectedTanggal!.month,
                                selectedTanggal!.day + 1))) {
                          return SizedBox.shrink(); // Skip item
                        }
                      }

                      DateTime? dateTime;
                      if (presensi['created_at'] != null) {
                        dateTime =
                            (presensi['created_at'] as Timestamp).toDate();
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tambahkan padding atau Align untuk menggeser gambar ke bawah
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 50.0), // Menggeser gambar ke bawah
                                child: presensi['face_image'] != null &&
                                        presensi['face_image'] != "Null"
                                    ? GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FullScreenImage(
                                                imageUrl:
                                                    presensi['face_image'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Image.network(
                                          presensi['face_image'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey,
                                        child: Icon(Icons.person, size: 50),
                                      ),
                              ),
                              SizedBox(width: 16),
                              // Informasi tambahan di sebelah kanan gambar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${presensi['dosen_id']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    if (presensi['matkul_id'] != null)
                                      Text(
                                          'Mata Kuliah: ${presensi['matkul_id']}'),
                                    SizedBox(height: 8),
                                    if (dateTime != null)
                                      Text(
                                          'Waktu Presensi: ${DateFormat('d MMMM yyyy, HH:mm').format(dateTime)}'),
                                    SizedBox(height: 8),
                                    Text(
                                        'Status: ${presensi['presensi_type'] ?? 'Tidak Diketahui'}'),
                                    SizedBox(height: 8),
                                    Text(
                                        'Bobot Kehadiran: ${presensi['bobot'] ?? 'Tidak Diketahui'}'),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              editPresensi(presensi['id']),
                                          child: Text('Edit'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              deletePresensi(presensi['id']),
                                          child: Text('Hapus'),
                                        ),
                                      ],
                                    )
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedTanggal)
      setState(() {
        selectedTanggal = picked;
      });
  }
}
