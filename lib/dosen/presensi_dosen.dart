import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:presensi_app/dosen/mypresensi_dosen.dart';
import 'package:presensi_app/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PresensiDosen extends StatefulWidget {
  final Map<String, dynamic> jadwalData;
  final Map<String, dynamic> userData;

  const PresensiDosen(
      {Key? key, required this.jadwalData, required this.userData})
      : super(key: key);

  @override
  _PresensiDosenState createState() => _PresensiDosenState();
}

class _PresensiDosenState extends State<PresensiDosen> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  bool _loadingLocation = true;
  bool _hasCheckedIn = false;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Tambahkan variabel untuk loading
  final LatLng _referenceLocation =
      LatLng(-7.5395562137055165, 110.7758042610071);
  // LatLng(-7.538542036047427, 110.62505381023126);
  final double _radius = 100;

  String? _targetAddress;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _checkIfCheckedIn(); // Add this to check presensi status when the page loads
    _loadTargetAddress();
  }

  void _loadTargetAddress() async {
    _targetAddress = await _getTargetAddressFromLatLng();
    setState(() {});
  }

  void _initializeLocation() async {
    await _getLocation();
    if (_currentPosition == null) {
      Fluttertoast.showToast(msg: 'Gagal mendapatkan posisi GPS.');
      return;
    }

    if (_currentPosition != null && mounted) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
      setState(() {});
    }
  }

  void _reloadPage() {
    setState(() {
      _initializeLocation(); // Menginisialisasi ulang lokasi ketika di-refresh
    });
  }

  Future<void> _checkIfCheckedIn() async {
    try {
      QuerySnapshot presensiSnapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('class_id', isEqualTo: widget.jadwalData['class_id'])
          .where('hari_id', isEqualTo: widget.jadwalData['hari_id'])
          .where('matkul_id', isEqualTo: widget.jadwalData['matkul_id'])
          .where('dosen_id', isEqualTo: widget.userData['user_id'])
          .get();

      if (presensiSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasCheckedIn = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e');
    }
  }

  Future<String> _getAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      return " ${place.street ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
    } catch (e) {
      print(e);
      return "Tidak diketahui";
    }
  }

  Future<String> _getTargetAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _referenceLocation.latitude, _referenceLocation.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.name ?? ''}, ${place.street ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
      } else {
        return "Tidak diketahui";
      }
    } catch (e) {
      print(e);
      return "Tidak diketahui";
    }
  }

  Future<void> _checkLocation(String status) async {
    if (status == "Offline") {
      await _getLocation();
    } else {
      // Jika statusnya "Online", tidak perlu menghidupkan GPS
      Fluttertoast.showToast(msg: 'Presensi online tidak memerlukan GPS.');
      // Lanjutkan proses selanjutnya tanpa pengecekan lokasi
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Mengecek apakah GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika GPS tidak aktif, tampilkan peringatan dan kembali ke halaman sebelumnya
      Fluttertoast.showToast(
          msg: 'GPS tidak aktif. Aktifkan GPS untuk melanjutkan.');

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingLocation = false;
        });
        Fluttertoast.showToast(
            msg:
                'Izin lokasi ditolak. Aktifkan izin lokasi untuk melanjutkan.');

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingLocation = false;
      });
      Fluttertoast.showToast(
          msg:
              'Izin lokasi ditolak secara permanen. Aktifkan izin lokasi di pengaturan.');

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String address =
        await _getAddressFromLatLng(position.latitude, position.longitude);

    setState(() {
      _currentPosition = position;
      _loadingLocation = false;
    });

    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      15.0,
    );

    Fluttertoast.showToast(msg: 'Lokasi saat ini: $address');
  }

  Future<void> _refreshData() async {
    _initializeLocation(); // Re-initialize location data when the user refreshes the page
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final faceImageUrl = await _uploadFaceImage(File(image.path));
      _handleAttendance('Tepat Waktu', faceImageUrl);
    } else {
      Fluttertoast.showToast(msg: 'Gambar tidak diambil.');
    }
  }

  Future<String> _uploadFaceImage(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('face_images')
        .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');

    try {
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengupload gambar wajah: $e');
    }
  }

  Future<void> _handleAttendance(
      String presensiType, String faceImageUrl) async {
    if (widget.jadwalData['status'] != 'Online' && _currentPosition == null) {
      Fluttertoast.showToast(msg: 'Tidak dapat mendeteksi lokasi.');
      return;
    }

    if (widget.jadwalData['status'] != 'Online') {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _referenceLocation.latitude,
        _referenceLocation.longitude,
      );
      String formattedDistance = distance.toStringAsFixed(0);

      print('Distance: $formattedDistance meters'); // Debugging line
      Fluttertoast.showToast(
          msg: 'Jarak ke lokasi referensi: $formattedDistance meter');

      if (distance > _radius) {
        Fluttertoast.showToast(
            msg: 'Lokasi Anda berada di luar radius tempat.');
        return;
      }
    }
    setState(() {
      _isLoading = true; // Set loading true sebelum memulai proses
    });
    try {
      String address = _currentPosition != null
          ? await _getAddressFromLatLng(
              _currentPosition!.latitude, _currentPosition!.longitude)
          : 'Tidak diketahui';

      QuerySnapshot presensiSnapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('class_id', isEqualTo: widget.jadwalData['class_id'])
          .where('hari_id', isEqualTo: widget.jadwalData['hari_id'])
          .where('matkul_id', isEqualTo: widget.jadwalData['matkul_id'])
          .where('dosen_id', isEqualTo: widget.userData['user_id'])
          .get();
      if (presensiSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasCheckedIn = true; // Update state after checking in
          _isLoading = false; // Set loading false setelah proses selesai
        });

        Fluttertoast.showToast(
            msg: 'Anda sudah melakukan presensi untuk jadwal ini.');
        return;
      }

      DateTime now = DateTime.now();
      int jamMulai =
          int.tryParse(widget.jadwalData['jam_mulai'].toString()) ?? 0;
      int menitMulai =
          int.tryParse(widget.jadwalData['menit_mulai'].toString()) ?? 0;
      DateTime startTime =
          DateTime(now.year, now.month, now.day, jamMulai, menitMulai);

      Duration difference = now.difference(startTime);
      if (difference.inMinutes > 30) {
        presensiType = 'tidak hadir';
      } else if (difference.inMinutes > 20) {
        presensiType = 'terlambat B';
      } else if (difference.inMinutes > 10) {
        presensiType = 'terlambat A';
      }

      final attendanceData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'class_id': widget.jadwalData['class_id'],
        'dosen': widget.jadwalData['dosen_id'],
        'tanggal': DateTime.now(),
        'student_id':
            widget.userData['user_type'] == 3 ? widget.userData['nama'] : null,
        'dosen_id':
            widget.userData['user_type'] == 2 ? widget.userData['nama'] : null,
        'presensi_type': presensiType,
        'created_by': widget.userData['nama'],
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'matkul_id': widget.jadwalData['matkul_id'],
        'hari_id': widget.jadwalData['hari_id'],
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'location': address,
        'face_image': faceImageUrl,
      };

      await FirebaseFirestore.instance
          .collection('presensi')
          .add(attendanceData);
      setState(() {
        _hasCheckedIn = true;
      });

      Fluttertoast.showToast(msg: 'Absensi berhasil dilakukan.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RekapPresensiDosen(userData: widget.userData),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading false jika terjadi error
      });
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    var jadwal = widget.jadwalData;
    var user = widget.userData;

    DateTime? dateTime;
    if (jadwal['tanggal'] != null && jadwal['tanggal'] is Timestamp) {
      dateTime = (jadwal['tanggal'] as Timestamp).toDate();
    }
// bool _isTargetAddressVisible = false;

    bool isOnline = jadwal['status'] == 'Online';
    DateTime now = DateTime.now();

    int jamMulai = int.tryParse(jadwal['jam_mulai'].toString()) ?? 0;
    int menitMulai = int.tryParse(jadwal['menit_mulai'].toString()) ?? 0;
    int jamAkhir = int.tryParse(jadwal['jam_akhir'].toString()) ?? 23;
    int menitAkhir = int.tryParse(jadwal['menit_akhir'].toString()) ?? 59;

    DateTime startTime =
        DateTime(now.year, now.month, now.day, jamMulai, menitMulai);
    DateTime endTime =
        DateTime(now.year, now.month, now.day, jamAkhir, menitAkhir);

    bool isInTimeRange = dateTime != null &&
        isSameDay(now, dateTime) &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);

    // bool canCheckIn = now.isAfter(startTime) && now.isBefore(endTime);

    if (dateTime != null &&
        isSameDay(now, dateTime) &&
        now.isAfter(endTime) &&
        !_hasCheckedIn) {
      Fluttertoast.showToast(
          msg: 'Anda Lupa melakukan presensi, Silahkan Lapor Ke BAAK.');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Presensi Dosen"),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _loadingLocation
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    if (_loadingLocation)
                      Center(child: CircularProgressIndicator())
                    else if (!isOnline && _currentPosition != null)
                      Container(
                          height: 200,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition != null
                                  ? LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude)
                                  : _referenceLocation,
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: LatLng(_referenceLocation.latitude,
                                        _referenceLocation.longitude),
                                    color: Colors.blue.withOpacity(0.3),
                                    radius:
                                        _radius, // Display the radius on the map
                                  ),
                                  CircleMarker(
                                    point: LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    color: Colors.blue.withOpacity(0.7),
                                    radius: 12,
                                  ),
                                ],
                              ),
                            ],
                          )),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${jadwal['matkul_id'] ?? 'Unknown Matkul'}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Nama: ${user['nama'] ?? 'Unknown User'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('Hari: ${jadwal['hari_id'] ?? 'Unknown Hari'}'),
                          Text(
                              'Kelas: ${jadwal['class_id'] ?? 'Unknown Kelas'}'),
                          Text(
                              'Dosen: ${jadwal['dosen_id'] ?? 'Unknown Dosen'}'),

                          Text(
                              'Jam: ${jamMulai.toString().padLeft(2, '0')}:${menitMulai.toString().padLeft(2, '0')} - ${jamAkhir.toString().padLeft(2, '0')}:${menitAkhir.toString().padLeft(2, '0')}'),
                          Text(
                              'Status: ${jadwal['status'] ?? 'Unknown Status'}'),
                          // if (_targetAddress != null) ...[
                          //   SizedBox(height: 8),
                          //   Text(
                          //     'Alamat Lokasi Target: $_targetAddress',
                          //     style: TextStyle(color: Colors.blue),
                          //   ),
                          // ],
                          if (jadwal['status'] == 'Offline' &&
                              jadwal['room_number'] != null)
                            Text('Ruangan: ${jadwal['room_number']}'),
                          if (widget.jadwalData['status'] == 'Online')
                            GestureDetector(
                              onTap: () async {
                                final url = widget.jadwalData['link'];
                                if (url != null && url.isNotEmpty) {
                                  if (await canLaunchUrl(url)) {
                                    await canLaunchUrl(url);
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Tidak dapat membuka link. Pastikan URL valid.');
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'URL tidak tersedia.');
                                }
                              },
                              child: Text(
                                'Link: ${widget.jadwalData['link']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .blue, // Memberi warna biru pada link
                                  decoration: TextDecoration
                                      .underline, // Menambahkan underline
                                ),
                              ),
                            ),
                          Text('Link Zoom: ${jadwal['link']}'),
                          if (dateTime != null)
                            Text(
                                'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                          SizedBox(height: 10),

                          if (!_hasCheckedIn && isInTimeRange)
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading =
                                            true; // Set loading true saat tombol diklik
                                      });
                                      _takePicture(); // Memanggil fungsi untuk mengambil gambar
                                    },
                                    child: const Text('Presensi'),
                                  )
                          else if (!isInTimeRange)
                            const Text(
                              'Presensi hanya bisa dilakukan jika sudah memasuki waktu kelas',
                              style: TextStyle(color: Colors.red),
                            )
                          else
                            const Text(
                              'Anda sudah melakukan presensi',
                              style: TextStyle(color: Colors.red),
                            ),

                          SizedBox(height: 20),
                          if (_currentPosition != null)
                            FutureBuilder(
                              future: _getAddressFromLatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return Text(
                                    'Lokasi saat ini: ${snapshot.data}',
                                    style: TextStyle(fontSize: 16),
                                  );
                                }
                              },
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
