import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_app/Dosen/detail_presensi_Dosen.dart';
import 'package:presensi_app/profile/profile_page.dart';

class RekapPresensiDosenFiltered extends StatefulWidget {
  const RekapPresensiDosenFiltered({Key? key}) : super(key: key);

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
  List<Map<String, dynamic>> presensiList = [];

  @override
  void initState() {
    super.initState();
    fetchSemesterList();
    fetchPresensiList();
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

  Future<void> fetchPresensiList() async {
    var snapshot = await _firestore.collection('presensi').get();
    setState(() {
      presensiList = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((data) =>
              data['dosen_id'] != null &&
              data['dosen_id'] !=
                  'Unknown Dosen') // Hanya tampilkan jika dosen_id valid
          .toList();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Mata Kuliah
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
            // Daftar Presensi

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

            Expanded(
              child: ListView.builder(
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
                      dateTime = (presensi['tanggal'] as Timestamp).toDate();
                    }

                    if (dateTime == null ||
                        dateTime.isBefore(DateTime(selectedTanggal!.year,
                            selectedTanggal!.month, selectedTanggal!.day)) ||
                        dateTime.isAfter(DateTime(
                            selectedTanggal!.year,
                            selectedTanggal!.month,
                            selectedTanggal!.day + 1))) {
                      return SizedBox.shrink(); // Skip item
                    }
                  }

                  DateTime? dateTime;
                  if (presensi['created_at'] != null) {
                    dateTime = (presensi['created_at'] as Timestamp).toDate();
                  }

                  // Update the ListTile inside the ListView.builder

                  return Card(
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8.0),
                      title: Row(
                        children: [
                          presensi['face_image'] != null &&
                                  presensi['face_image'] != "Null"
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullScreenImage(
                                          imageUrl: presensi['face_image'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    presensi['face_image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nama: ${presensi['dosen_id'] ?? 'Unknown Dosen'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Kelas: ${presensi['class_id'] ?? 'Unknown Class'}',
                                ),
                                Text(
                                  'Mata Kuliah: ${presensi['matkul_id'] ?? 'Unknown Matkul'}',
                                ),
                                // Text(
                                //   'Jam Presensi: ${dateTime != null ? DateFormat('HH:mm').format(dateTime) : 'N/A'}',
                                // ),
                                Text(
                                  'Status: ${presensi['presensi_type'] ?? 'Unknown Type'}',
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPresensiDosen(
                              attendanceData: presensi,
                            ),
                          ),
                        );
                      },
                    ),
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
