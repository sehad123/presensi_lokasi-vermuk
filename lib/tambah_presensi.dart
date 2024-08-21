import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Library untuk format tanggal

class AddPresensiMahasiswa extends StatefulWidget {
  @override
  _AddPresensiMahasiswaState createState() => _AddPresensiMahasiswaState();
}

class _AddPresensiMahasiswaState extends State<AddPresensiMahasiswa> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tanggalController = TextEditingController();

  String? selectedSemester;
  String? selectedKelas;
  String? selectedMatkul;
  String? selectedHari;
  String? selectedDosen;
  String? selectedMahasiswa;
  String? presensi_type;
  String? link;
  String? face_image;
  DateTime? selectedDate;
  String? bobot;
  String? location;
  List<String> semesterList = [];
  List<String> dosenList = [];
  List<String> mahasiswaList = [];
  List<String> kelasList = [];
  List<String> matkulList = [];
  List<String> hariList = [];
  Map<String, dynamic>? presensiDetails;
  bool searchPerformed = false;

  @override
  void initState() {
    super.initState();
    fetchSemesterList();
    fetchHariList();
    fetchDosenList(); // Fetch dosen when initializing
    fetchMahasiswaList(); // Fetch dosen when initializing
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

  Future<void> fetchDosenList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user_type', isEqualTo: 2)
        .get();

    setState(() {
      dosenList = snapshot.docs.map((doc) => doc['nama'] as String).toList();
    });
  }

  Future<void> fetchMahasiswaList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user_type', isEqualTo: 3)
        .where('class_id', isEqualTo: selectedKelas)
        .where('semester_id', isEqualTo: selectedSemester)
        .get();

    setState(() {
      mahasiswaList =
          snapshot.docs.map((doc) => doc['nama'] as String).toList();
    });
  }

  Future<void> fetchJadwalList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('presensi')
        .where('semester_id', isEqualTo: selectedSemester)
        .where('class_id', isEqualTo: selectedKelas)
        .where('matkul_id', isEqualTo: selectedMatkul)
        .where('hari_id', isEqualTo: selectedHari)
        .where('dosen_id', isEqualTo: selectedDosen)
        .where('student_id', isEqualTo: selectedMahasiswa)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        presensiDetails = snapshot.docs.first.data();
        presensi_type = presensiDetails?['presensi_type'];
        selectedDate = (presensiDetails?['tanggal'] as Timestamp?)?.toDate();
        _tanggalController.text = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : '';
        bobot = presensiDetails?['bobot'];
      });
    } else {
      setState(() {
        presensiDetails = null;
        presensi_type = null;
        face_image = null;
        location = null;
        selectedDate = null;
        _tanggalController.text = '';
        bobot = null;
      });
    }
  }

  Future<void> fetchHariList() async {
    var snapshot = await FirebaseFirestore.instance.collection('hari').get();
    setState(() {
      hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      int? parsedBobot = int.tryParse(bobot ?? '');

      Map<String, dynamic> presensiDataa = {
        'semester_id': selectedSemester,
        'class_id': selectedKelas,
        'matkul_id': selectedMatkul,
        'dosen': selectedDosen,
        'student_id': selectedMahasiswa,
        'hari_id': selectedHari,
        'presensi_type': presensi_type,
        'tanggal': selectedDate,
        'bobot': parsedBobot,
        'face_image': null,
        'location': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('presensi')
          .add(presensiDataa);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Presensi berhasil disimpan!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Presensi Mahasiswa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Row for Hari and Semester
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Hari"),
                            value: selectedHari,
                            onChanged: (value) {
                              setState(() {
                                selectedHari = value;
                              });
                            },
                            items: hariList.map((hari) {
                              return DropdownMenuItem<String>(
                                value: hari,
                                child: Text(hari),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Semester"),
                            value: selectedSemester,
                            onChanged: (value) {
                              setState(() {
                                selectedSemester = value;
                                selectedKelas = null;
                                selectedMatkul = null;
                                kelasList.clear();
                                matkulList.clear();
                                searchPerformed = false;
                                if (value != null) {
                                  fetchKelasList(value);
                                }
                              });
                            },
                            items: semesterList.map((semester) {
                              return DropdownMenuItem<String>(
                                value: semester,
                                child: Text(semester),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),

                    // Row for Kelas and Matkul
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Kelas"),
                            value: selectedKelas,
                            onChanged: (value) {
                              setState(() {
                                selectedKelas = value;
                                selectedMatkul = null;
                                matkulList.clear();
                                searchPerformed = false;
                                if (value != null) {
                                  fetchMatkulList(value);
                                }
                              });
                            },
                            items: kelasList.map((kelas) {
                              return DropdownMenuItem<String>(
                                value: kelas,
                                child: Text(kelas),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Matkul"),
                            value: selectedMatkul,
                            onChanged: (value) {
                              setState(() {
                                selectedMatkul = value;
                                searchPerformed = false;
                              });
                            },
                            items: matkulList.map((matkul) {
                              return DropdownMenuItem<String>(
                                value: matkul,
                                child: Text(matkul),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),

                    // Search Button
                    ElevatedButton(
                      onPressed: () {
                        fetchJadwalList();
                        setState(() {
                          searchPerformed = true;
                        });
                      },
                      child: Text("Search"),
                    ),

                    // Status Dropdown
                    if (searchPerformed)
                      Column(
                        children: [
                          SizedBox(height: 16.0),

                          // Room Number or Link Input

                          DropdownButton<String>(
                            hint: Text("Select Dosen"),
                            value: selectedDosen,
                            onChanged: (value) {
                              setState(() {
                                selectedDosen = value;
                                searchPerformed = true;
                              });
                            },
                            items: dosenList.map((dosen) {
                              return DropdownMenuItem<String>(
                                value: dosen,
                                child: Text(dosen),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 16.0),

                          DropdownButton<String>(
                            hint: Text("Select Mahasiswa"),
                            value: selectedMahasiswa,
                            onChanged: (value) {
                              setState(() {
                                selectedMahasiswa = value;
                                searchPerformed = true;
                              });
                            },
                            items: mahasiswaList.map((mahasiswa) {
                              return DropdownMenuItem<String>(
                                value: mahasiswa,
                                child: Text(mahasiswa),
                              );
                            }).toList(),
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          DropdownButton<String>(
                            hint: Text("Select Presensi Type"),
                            value: presensi_type,
                            onChanged: (value) {
                              setState(() {
                                presensi_type = value;
                              });
                            },
                            items: [
                              'Tepat Waktu',
                              'Terlambat A',
                              'Terlambat B',
                              'Sakit',
                              'Izin',
                              'Tidak Hadir'
                            ].map((presensiOption) {
                              return DropdownMenuItem<String>(
                                value: presensiOption,
                                child: Text(presensiOption),
                              );
                            }).toList(),
                          ),

                          // Date Picker
                          TextFormField(
                            controller: _tanggalController,
                            decoration: InputDecoration(labelText: "Tanggal"),
                            readOnly: true,
                            onTap: () async {
                              selectedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (selectedDate != null) {
                                _tanggalController.text =
                                    DateFormat('yyyy-MM-dd')
                                        .format(selectedDate!);
                              }
                            },
                          ),

                          SizedBox(height: 16.0),
                          TextFormField(
                            initialValue: bobot,
                            decoration: InputDecoration(labelText: "Bobot"),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              bobot = value;
                            },
                          ),

                          // Submit Button
                          ElevatedButton(
                            onPressed: handleSubmit,
                            child: Text("Submit"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
