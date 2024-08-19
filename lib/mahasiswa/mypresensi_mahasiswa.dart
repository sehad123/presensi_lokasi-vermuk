import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detail_presensi_mahasiswa.dart'; // Import halaman baru

class RekapPresensiMahasiswa extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RekapPresensiMahasiswa({Key? key, required this.userData})
      : super(key: key);

  @override
  _RekapPresensiMahasiswaState createState() => _RekapPresensiMahasiswaState();
}

class _RekapPresensiMahasiswaState extends State<RekapPresensiMahasiswa> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime selectedDate = DateTime.now(); // Set default to today's date
  bool showAllPresensi = false; // Flag to toggle between filtered and all data

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('presensi')
        .where('student_id', isEqualTo: widget.userData['nama']);

    if (!showAllPresensi) {
      var startDate = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
      var endDate = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day + 1, 0, 0, 0);
      query = query
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal', isLessThan: Timestamp.fromDate(endDate));
    }

    return query.snapshots();
  }

  void resetFilters() {
    setState(() {
      selectedDate = DateTime.now();
      showAllPresensi = false;
    });
  }

  void toggleShowAllPresensi() {
    setState(() {
      showAllPresensi = !showAllPresensi;
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
      appBar: AppBar(
        title: Text('Rekap Presensi'),
        actions: [
          ElevatedButton(
            onPressed: toggleShowAllPresensi,
            child: Text(showAllPresensi ? ' Hari Ini' : 'Semua'),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                SizedBox(width: 16),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getJadwalStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No data found'));
                  }

                  var jadwalList = snapshot.data!.docs
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
                          leading: jadwal['face_image'] != null
                              ? GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: Container(
                                            color: Colors.black,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Image.network(
                                                jadwal['face_image'],
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Image.network(
                                    jadwal['face_image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.person, size: 50),
                          title: Text(
                            '${jadwal['matkul_id'] ?? 'Unknown Student'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Kelas: ${jadwal['class_id'] ?? 'Unknown Class'}'),
                              Text(
                                  'Dosen: ${jadwal['dosen'] ?? 'Unknown Dosen'}'),
                              Text(
                                  'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}'),
                              Text(
                                'Jam Presensi: ${dateTime != null ? DateFormat(' HH:mm').format(dateTime) : 'N/A'}',
                              ),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPresensiMahasiswa(
                                  attendanceData: jadwal,
                                ),
                              ),
                            );
                          },
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
