import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_app/mahasiswa/detail_presensi_mahasiswa.dart';
import 'package:presensi_app/profile/profile_page.dart';

class CekPresensiMahasiswa extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CekPresensiMahasiswa({Key? key, required this.userData})
      : super(key: key);
  @override
  _CekPresensiMahasiswaState createState() => _CekPresensiMahasiswaState();
}

class _CekPresensiMahasiswaState extends State<CekPresensiMahasiswa> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime selectedDate = DateTime.now(); // Set default to today's date
  String? selectedMatkul;
  String? selectedStudent;
  String? selectedClass;
  String? selectedSemester;

  List<String> semesterList = [];
  List<String> kelasList = [];
  List<String> matkulList = [];
  List<Map<String, dynamic>> presensiList = [];
  int totalMahasiswa = 0;
  int totalDisplayedMahasiswa = 0;

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
    DateTime startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));
    var snapshot = await _firestore
        .collection('presensi')
        .where('dosen', isEqualTo: widget.userData['nama'])
        .where('matkul_id', isEqualTo: selectedMatkul)
        .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
        .where('tanggal', isLessThan: endOfDay)
        // .where('tanggal', isEqualTo: selectedDate)
        .get();

    setState(() {
      presensiList = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((data) =>
              data['student_id'] != null &&
              data['student_id'] != 'Unknown Mahasiswa')
          .toList();

      // Hitung jumlah mahasiswa yang tampil berdasarkan filter
      totalDisplayedMahasiswa = presensiList.length;
    });

    if (selectedClass != null && selectedSemester != null) {
      fetchTotalMahasiswa();
    }
  }

  Future<void> fetchTotalMahasiswa() async {
    var snapshot = await _firestore
        .collection('users')
        .where('user_type', isEqualTo: 3)
        .where('class_id', isEqualTo: selectedClass)
        .where('semester_id', isEqualTo: selectedSemester)
        .get();

    setState(() {
      totalMahasiswa = snapshot.docs.length;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menambahkan angka di pojok kanan atas
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$totalDisplayedMahasiswa / $totalMahasiswa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Filter Mata Kuliah
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
                        fetchTotalMahasiswa();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(selectedDate)),
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
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
                      !presensi['student_id']
                          .toString()
                          .toLowerCase()
                          .contains(selectedStudent!.toLowerCase())) {
                    return SizedBox.shrink();
                  }

                  if (selectedClass != null &&
                      selectedClass!.isNotEmpty &&
                      presensi['class_id'] != selectedClass) {
                    return SizedBox.shrink();
                  }

                  if (selectedMatkul != null &&
                      selectedMatkul!.isNotEmpty &&
                      presensi['matkul_id'] != selectedMatkul) {
                    return SizedBox.shrink();
                  }

                  if (selectedDate != null) {
                    DateTime? dateTime;
                    if (presensi['tanggal'] != null) {
                      dateTime = (presensi['tanggal'] as Timestamp).toDate();
                    }

                    if (dateTime == null ||
                        dateTime.isBefore(DateTime(selectedDate.year,
                            selectedDate.month, selectedDate.day)) ||
                        dateTime.isAfter(DateTime(selectedDate.year,
                            selectedDate.month, selectedDate.day + 1))) {
                      return SizedBox.shrink();
                    }
                  }

                  DateTime? dateTime;
                  if (presensi['created_at'] != null) {
                    dateTime = (presensi['created_at'] as Timestamp).toDate();
                  }

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
                                  'Nama: ${presensi['student_id'] ?? 'Unknown Mahasiswa'}',
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
                                Text(
                                  'Jam Presensi: ${dateTime != null ? DateFormat('HH:mm').format(dateTime) : 'N/A'}',
                                ),
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
                            builder: (context) => DetailPresensiMahasiswa(
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
