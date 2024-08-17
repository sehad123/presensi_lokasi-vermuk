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

  DateTime? selectedDate;
  String? selectedBulan;
  String? selectedTahun;

  List<String> bulanList = List.generate(
      12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));
  List<String> tahunList =
      List.generate(4, (index) => (DateTime.now().year - 3 + index).toString());

  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('presensi')
        .where('dosen_id', isEqualTo: widget.userData['nama']);

    if (selectedDate != null) {
      var startDate = DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day, 0, 0, 0);
      var endDate = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day + 1, 0, 0, 0);
      query = query
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal', isLessThan: Timestamp.fromDate(endDate));
    }

    if (selectedBulan != null && selectedTahun != null) {
      var startDate = DateTime(
          int.parse(selectedTahun!), bulanList.indexOf(selectedBulan!) + 1, 1);
      var endDate = DateTime(
          int.parse(selectedTahun!), bulanList.indexOf(selectedBulan!) + 2, 1);
      query = query
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal', isLessThan: Timestamp.fromDate(endDate));
    }

    if (selectedTahun != null) {
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
      selectedDate = null;
      selectedBulan = null;
      selectedTahun = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
        title: Row(
          children: [
            Expanded(
              child: Text('Presensi Saya'),
            ),
            DropdownButton<String>(
              value: selectedTahun,
              onChanged: (value) {
                setState(() {
                  selectedTahun = value;
                });
              },
              items: tahunList
                  .map((tahun) => DropdownMenuItem<String>(
                        value: tahun,
                        child: Text(tahun),
                      ))
                  .toList(),
              hint: Text('Tahun'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetFilters,
            tooltip: 'Reset Filters',
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
                        text: selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : ''),
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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBulan,
                    onChanged: (value) {
                      setState(() {
                        selectedBulan = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Bulan',
                    ),
                    items: bulanList
                        .map((bulan) => DropdownMenuItem<String>(
                              value: bulan,
                              child: Text(bulan),
                            ))
                        .toList(),
                  ),
                ),
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
                              ? Image.network(
                                  jadwal['face_image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.person, size: 50),
                          title: Text(
                            '${jadwal['dosen_id'] ?? 'Unknown Dosen'}',
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
                                  'Mata Kuliah: ${jadwal['matkul_id'] ?? 'Unknown Matkul'}'),
                              Text(
                                  'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}'),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
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
