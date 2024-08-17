import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_app/dosen/presensi_dosen.dart';
import 'package:presensi_app/mahasiswa/presensi_mahasiswa.dart';

class JadwalDosenSTIS extends StatefulWidget {
  final Map<String, dynamic> userData;

  const JadwalDosenSTIS({Key? key, required this.userData}) : super(key: key);

  @override
  _JadwalDosenSTISState createState() => _JadwalDosenSTISState();
}

class _JadwalDosenSTISState extends State<JadwalDosenSTIS> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedHari;

  List<String> hariList = [];
  Map<String, String> matkulMap = {};

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.userData[
        'nama']; // Pastikan 'id' di sini adalah key yang tepat untuk user_id
    _fetchHari();
  }

  Future<void> _fetchHari() async {
    var snapshot = await _firestore.collection('hari').get();
    setState(() {
      hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('jadwal');

    if (selectedHari != null) {
      query = query.where('hari_id', isEqualTo: selectedHari);
    }

    query = query.where('dosen_id', isEqualTo: currentUserId);

    print('Filtering jadwal with dosen_id: $currentUserId'); // Debugging log

    return query.snapshots();
  }

  void resetFilters() {
    setState(() {
      selectedHari = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Anda'),
        actions: [
          ElevatedButton(
            onPressed: resetFilters,
            child: Text('Tampilkan Semua'),
          ),
          SizedBox(width: 16), // Memberi jarak antara tombol dan tepi kanan
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DropdownButtonFormField<String>(
                value: selectedHari,
                onChanged: (value) {
                  setState(() {
                    selectedHari = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Hari',
                ),
                items: hariList
                    .map((hari) => DropdownMenuItem<String>(
                          value: hari,
                          child: Text(hari),
                        ))
                    .toList(),
              ),
            ),
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
                          title: Text(
                            jadwal['matkul_id'] ?? 'Unknown Matkul',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Hari: ${jadwal['hari_id'] ?? 'Unknown Hari'}'),
                              Text(
                                  'Kelas: ${jadwal['class_id'] ?? 'Unknown Kelas'}'),
                              Text(
                                  'Dosen: ${jadwal['dosen_id'] ?? 'Unknown Dosen'}'),
                              Text(
                                  'Jam: ${jadwal['jam_mulai']}:${jadwal['menit_mulai']} - ${jadwal['jam_akhir']}:${jadwal['menit_akhir']}'),
                              Text(
                                  'Status: ${jadwal['status'] ?? 'Unknown Status'}'),
                              if (jadwal['status'] == 'Offline' &&
                                  jadwal['room_number'] != null)
                                Text('Ruangan: ${jadwal['room_number']}'),
                              if (jadwal['status'] == 'Online' &&
                                  jadwal['link'] != null)
                                Text('Link Zoom: ${jadwal['link']}'),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PresensiDosen(
                                  jadwalData:
                                      jadwal, // Kirim data jadwal yang dipilih
                                  userData: widget
                                      .userData, // Kirim data pengguna yang login
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
