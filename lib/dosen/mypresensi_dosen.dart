import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RekapPresensiDosen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RekapPresensiDosen({Key? key, required this.userData})
      : super(key: key);

  @override
  _RekapPresensiDosenState createState() => _RekapPresensiDosenState();
}

class _RekapPresensiDosenState extends State<RekapPresensiDosen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime selectedDate = DateTime.now(); // Set default to today's date
  String? selectedTahun;
  bool showAllPresensi = false; // Flag to toggle between filtered and all data

  List<String> tahunList =
      List.generate(4, (index) => (DateTime.now().year - 3 + index).toString());

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('presensi')
        .where('dosen_id', isEqualTo: widget.userData['nama']);

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

    if (selectedTahun != null && !showAllPresensi) {
      var startDate = DateTime(int.parse(selectedTahun!), 1, 1);
      var endDate = DateTime(int.parse(selectedTahun!) + 1, 1, 1);
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
      selectedTahun = null;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Container(
                              alignment: Alignment.center,
                              child: jadwal['face_image'] != null
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
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.person, size: 100),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${jadwal['dosen_id'] ?? 'Unknown Dosen'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )),
                                  SizedBox(height: 4),
                                  Text(
                                      'Kelas: ${jadwal['class_id'] ?? 'Unknown Class'}'),
                                  Text(
                                      'Mata Kuliah: ${jadwal['matkul_id'] ?? 'Unknown Matkul'}'),
                                  Text(
                                      'Dosen: ${jadwal['dosen'] ?? 'Unknown Dosen'}'),
                                  Text(
                                      'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}'),
                                  Text(
                                    'Jam Presensi: ${dateTime != null ? DateFormat(' HH:mm').format(dateTime) : 'N/A'}',
                                  ),
                                  Text(
                                      'Lokasi : ${jadwal['location'] ?? 'Lokasi Tidak Terdeteksi'}'),
                                  if (dateTime != null)
                                    Text(
                                        'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                                ],
                              ),
                            ),
                          ],
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
