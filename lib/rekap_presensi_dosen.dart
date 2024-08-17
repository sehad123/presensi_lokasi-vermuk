import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String? selectedDosen;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedTanggal) {
      setState(() {
        selectedTanggal = picked;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPresensiStream() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('presensi').where('student_id', isEqualTo: null);

    if (selectedDosen != null && selectedDosen!.isNotEmpty) {
      query = query.where('created_by', isEqualTo: selectedDosen);
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

  Future<List<DropdownMenuItem<String>>> _getDosenList() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .where('user_type', isEqualTo: 2)
        .get();

    List<DropdownMenuItem<String>> dosenItems = snapshot.docs.map((doc) {
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(doc['nama'] ?? 'Unknown Dosen'),
      );
    }).toList();

    return dosenItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Dosen
            FutureBuilder<List<DropdownMenuItem<String>>>(
              future: _getDosenList(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Dosen',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDosen,
                  items: snapshot.data!,
                  onChanged: (value) {
                    setState(() {
                      selectedDosen = value;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),
            // Filter Tanggal
            InkWell(
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
                          ? DateFormat('d MMMM yyyy').format(selectedTanggal!)
                          : 'Pilih Tanggal',
                    ),
                    Spacer(),
                    Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
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
                              // Menampilkan gambar wajah dengan tap untuk melihat full screen
                              jadwal['face_image'] != null
                                  ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenImage(
                                              imageUrl: jadwal['face_image'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        jadwal['face_image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
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
                                      'Nama Dosen: ${jadwal['dosen_name'] ?? 'Unknown Dosen'}',
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
                                      'Jam Presensi: ${dateTime != null ? DateFormat(' HH:mm').format(dateTime) : 'N/A'}',
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Screen Image'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
