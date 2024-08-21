import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPresensiDosen extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const DetailPresensiDosen({Key? key, required this.attendanceData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = (attendanceData['created_at'] as Timestamp).toDate();

    // Determine the face_image URL
    String? faceImageUrl = attendanceData['face_image'];
    bool isFaceImageNull =
        faceImageUrl == null || faceImageUrl.toLowerCase() == "null";

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Presensi Dosen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar face_image ditampilkan di atas
            Center(
              child: isFaceImageNull
                  ? Icon(Icons.person, size: 200)
                  : Image.network(
                      faceImageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(height: 20),

            // Informasi lainnya ditampilkan di bawah gambar
            Text(
              'Mata Kuliah: ${attendanceData['matkul_id'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Kelas: ${attendanceData['class_id'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Jam Presensi: ${DateFormat('HH:mm').format(dateTime)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Lokasi: ${attendanceData['location'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Status: ${attendanceData['presensi_type'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
