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
    if (selectedMatkul != null && selectedMatkul!.isNotEmpty) {
      query = query.where('matkul_id', isEqualTo: selectedMatkul);
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
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : SizedBox(width: 50, height: 50),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${jadwal['student_id'] ?? 'N/A'}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Tanggal: ${dateTime != null ? DateFormat('d MMMM yyyy').format(dateTime) : 'N/A'}',
                                    ),
                                    Text(
                                      'Jam Presensi: ${dateTime != null ? DateFormat(' HH:mm').format(dateTime) : 'N/A'}',
                                    ),
                                    Text(
                                      'Kelas: ${jadwal['class_id'] ?? 'N/A'}',
                                    ),
                                    Text(
                                      'Mata Kuliah: ${jadwal['matkul_id'] ?? 'N/A'}',
                                    ),
                                    Text(
                                      'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}',
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
