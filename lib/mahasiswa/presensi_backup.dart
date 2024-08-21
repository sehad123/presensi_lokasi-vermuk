import 'dart:convert';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
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
import 'package:presensi_app/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:presensi_app/notification_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PresensiMahasiswa extends StatefulWidget {
  final Map<String, dynamic> jadwalData;
  final Map<String, dynamic> userData;

  const PresensiMahasiswa(
      {Key? key, required this.jadwalData, required this.userData})
      : super(key: key);

  @override
  _PresensiMahasiswaState createState() => _PresensiMahasiswaState();
}

class _PresensiMahasiswaState extends State<PresensiMahasiswa> {
  Timer? _countdownTimer;
  Duration _countdownDuration = Duration();
  final NotificationHelper _notificationHelper =
      NotificationHelper(); // Instance notifikasi

  Position? _currentPosition;
  final MapController _mapController = MapController();
  bool _loadingLocation = true;
  bool _hasCheckedIn = false;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Tambahkan variabel untuk loading
  final LatLng _referenceLocation =
      // LatLng(-7.5395562137055165, 110.7758042610071);
      LatLng(-7.538542036047427, 110.62505381023126);
  final double _radius = 100;

  String? _targetAddress;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _checkIfCheckedIn(); // Add this to check presensi status when the page loads
    _loadTargetAddress();
    _requestNotificationPermission(); // Meminta izin notifikasi
    _initializeCountdown();
    _scheduleAttendanceNotification(DateTime.now().add(Duration(minutes: 10)));
  }

  void _loadTargetAddress() async {
    _targetAddress = await _getTargetAddressFromLatLng();
    setState(() {});
  }

  void _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
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
      // Mengubah tanggal sekarang ke format yang sesuai
      // String formattedDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
      final DateTime now = DateTime.now();
      final DateTime onlyDate = DateTime(now.year, now.month, now.day);

      QuerySnapshot presensiSnapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('class_id', isEqualTo: widget.jadwalData['class_id'])
          .where('hari_id', isEqualTo: widget.jadwalData['hari_id'])
          .where('matkul_id', isEqualTo: widget.jadwalData['matkul_id'])
          .where('student_id', isEqualTo: widget.userData['nama'])
          .where('tanggal', isEqualTo: onlyDate) // Only compare the date part
          .get();

      if (presensiSnapshot.docs.isNotEmpty) {
        _hasCheckedIn = true;
        Fluttertoast.showToast(
            msg: 'Anda sudah melakukan presensi untuk jadwal ini.');
        setState(() {});
      } else {
        _hasCheckedIn = false;
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
    if (image != null && image.path != "Null") {
      final faceImageUrl = await _uploadFaceImage(File(image.path));
      _handleAttendance('Tepat Waktu', faceImageUrl, 100);
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
      String presensiType, String faceImageUrl, int bobot) async {
    if (_hasCheckedIn) {
      Fluttertoast.showToast(
          msg: 'Anda sudah melakukan presensi untuk jadwal ini.');
      return;
    }

    // Pengecekan apakah status presensi bukan "Online" dan posisi saat ini null
    if (widget.jadwalData['status'] != 'Online' && _currentPosition == null) {
      // Fluttertoast.showToast(
      //     msg: 'Tidak dapat mendeteksi lokasi. Aktifkan GPS.');
      await _getLocation(); // Meminta pengguna untuk mengaktifkan GPS
      return;
    }

    if (widget.jadwalData['status'] != 'Online') {
      // Pengecekan jarak dari lokasi referensi
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
      final DateTime now = DateTime.now();

      final DateTime onlyDate = DateTime(now.year, now.month, now.day);

      // Ambil alam
      //at dari latitude dan longitude
      String address = _currentPosition != null
          ? await _getAddressFromLatLng(
              _currentPosition!.latitude, _currentPosition!.longitude)
          : 'Tidak diketahui';

      QuerySnapshot presensiSnapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('class_id', isEqualTo: widget.jadwalData['class_id'])
          .where('hari_id', isEqualTo: widget.jadwalData['hari_id'])
          .where('matkul_id', isEqualTo: widget.jadwalData['matkul_id'])
          .where('student_id', isEqualTo: widget.userData['nama'])
          .where('tanggal',
              isEqualTo: onlyDate) // cek berdasarkan tanggal yang sama

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

      int jamMulai =
          int.tryParse(widget.jadwalData['jam_mulai'].toString()) ?? 0;
      int menitMulai =
          int.tryParse(widget.jadwalData['menit_mulai'].toString()) ?? 0;
      DateTime startTime =
          DateTime(now.year, now.month, now.day, jamMulai, menitMulai);

      Duration difference = now.difference(startTime);
      if (difference.inMinutes > 30) {
        presensiType = 'Tidak Hadir';
        bobot = 0;
      } else if (difference.inMinutes > 20) {
        presensiType = 'Terlambat B';
        bobot = 50;
      } else if (difference.inMinutes > 10) {
        presensiType = 'Terlambat A';
        bobot = 75;
      }

      final attendanceData = {
        // 'id': DateTime.now().millisecondsSinceEpoch,
        'class_id': widget.jadwalData['class_id'],
        'dosen': widget.jadwalData['dosen_id'],
        'tanggal': onlyDate,
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
        'location': address, // Tambahkan alamat hasil geocoding
        'face_image': faceImageUrl,
        'bobot': bobot
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
          builder: (context) =>
              RekapPresensiMahasiswa(userData: widget.userData),
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

  void _initializeCountdown() {
    DateTime now = DateTime.now();
    int jamMulai = int.tryParse(widget.jadwalData['jam_mulai'].toString()) ?? 0;
    int menitMulai =
        int.tryParse(widget.jadwalData['menit_mulai'].toString()) ?? 0;
    DateTime startTime =
        DateTime(now.year, now.month, now.day, jamMulai, menitMulai);

    Duration timeUntilPresensi = startTime.difference(now);

    if (timeUntilPresensi.isNegative) {
      timeUntilPresensi = Duration.zero;
    }

    // Hitung waktu hingga countdown berakhir
    _countdownDuration = timeUntilPresensi;

    // Hanya menjalankan timer jika ada durasi tersisa
    if (_countdownDuration > Duration.zero) {
      _startCountdownTimer();
    }

    // Jadwalkan notifikasi
    _scheduleAttendanceNotification(startTime);
  }

  void _scheduleAttendanceNotification(DateTime startTime) async {
    // Jadwalkan notifikasi 10 menit sebelum pelajaran dimulai
    DateTime notificationTime = startTime.subtract(Duration(minutes: 10));

    // Pastikan waktu notifikasi lebih besar dari waktu saat ini
    if (notificationTime.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10,
          channelKey: 'presensi_channel',
          title: 'Pengingat Presensi',
          body: 'Pelajaran segera dimulai, lakukan presensi sekarang.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: notificationTime),
      );
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdownDuration.inSeconds > 0) {
        setState(() {
          _countdownDuration = _countdownDuration - Duration(seconds: 1);
        });

        if (_countdownDuration.inSeconds == 0) {
          _notificationHelper.showNotification(
            'presensi_channel',
            'Saatnya untuk melakukan presensi untuk jadwal kuliah Anda.',
          );
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return "Pelajaran akan dimulai dalam $hours jam $minutes menit $seconds detik lagi";
  }

  @override
  Widget build(BuildContext context) {
    var jadwal = widget.jadwalData;
    var user = widget.userData;

    DateTime? dateTime;
    if (jadwal['tanggal'] != null && jadwal['tanggal'] is Timestamp) {
      dateTime = (jadwal['tanggal'] as Timestamp).toDate();
    }

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

    if (dateTime != null) {
      print('dateTime is not null');
      if (isSameDay(now, dateTime)) {
        print('Date is the same day');
        if (now.isAfter(endTime)) {
          print('Current time is after endTime');
          if (!_hasCheckedIn) {
            print('User has not checked in');
            // _handleAttendance("Lupa Presensi", "Null", 0);
            Fluttertoast.showToast(
                msg: 'Anda Lupa melakukan presensi, Silahkan Lapor Ke BAAK.');
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Presensi Mahasiswa"),
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
                    else if (_currentPosition != null)
                      Container(
                        height: 200,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
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
                                  radius: _radius,
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
                        ),
                      ),
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
                          if (jadwal['status'] == 'Offline' &&
                              jadwal['room_number'] != null)
                            Text('Ruangan: ${jadwal['room_number']}'),
                          if (widget.jadwalData['status'] == 'Online')
                            GestureDetector(
                              onTap: () async {
                                final url =
                                    Uri.parse(widget.jadwalData['link'] ?? '');
                                if (url != null && url.toString().isNotEmpty) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode
                                        .externalApplication, // Membuka link di browser eksternal
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg: 'URL tidak tersedia.',
                                  );
                                }
                              },
                              child: Text(
                                'Link: ${widget.jadwalData['link']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          if (dateTime != null)
                            Text(
                                'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                          SizedBox(height: 10),
                          if (dateTime != null &&
                              isSameDay(now, dateTime) &&
                              now.isBefore(startTime))
                            Text(
                              _formatDuration(_countdownDuration),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          // Logika yang telah diperbaiki
                          if (!_hasCheckedIn && isInTimeRange)
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      _takePicture();
                                    },
                                    child: const Text('Presensi'),
                                  )
                          else if (!_hasCheckedIn &&
                              !isInTimeRange &&
                              now.isBefore(startTime))
                            const Text(
                              'Presensi hanya bisa dilakukan ketika memasuki jam pelajaran',
                              style: TextStyle(color: Colors.red),
                            )
                          else if (_hasCheckedIn)
                            const Text(
                              'Anda sudah melakukan presensi',
                              style: TextStyle(color: Colors.red),
                            )
                          else
                            const Text(
                              'Presensi hanya bisa dilakukan ketika memasuki jam pelajaran',
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
                                      'Lokasi Anda Saat ini: ${snapshot.data}');
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
