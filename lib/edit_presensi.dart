import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPresensi extends StatefulWidget {
  final String docId;

  EditPresensi({required this.docId});

  @override
  _EditPresensiState createState() => _EditPresensiState();
}

class _EditPresensiState extends State<EditPresensi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _presensiData = {};
  String? _presensiType;
  TextEditingController _bobotController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPresensiData();
  }

  Future<void> _fetchPresensiData() async {
    try {
      var doc = await _firestore.collection('presensi').doc(widget.docId).get();
      if (doc.exists) {
        setState(() {
          _presensiData = doc.data()!;
          _presensiType = _presensiData['presensi_type'];
          _bobotController.text = _presensiData['bobot']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        // Handle document not found
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Document not found'),
        ));
      }
    } catch (e) {
      // Handle errors
      print('Error fetching presensi data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching presensi data: $e'),
      ));
    }
  }

  Future<void> updatePresensi() async {
    try {
      await _firestore.collection('presensi').doc(widget.docId).update({
        'presensi_type': _presensiType,
        'bobot': int.tryParse(_bobotController.text) ?? 0,
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Presensi updated successfully'),
      ));

      Navigator.pop(context, true); // Return 'true' to indicate update
    } catch (e) {
      print("Error updating Presensi: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating Presensi: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Presensi'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Presensi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller:
                  TextEditingController(text: _presensiData['student_id']),
              decoration: InputDecoration(labelText: 'Mahasiswa'),
              readOnly: true, // Make this field read-only
            ),
            SizedBox(height: 16),
            Text('Status'),
            Wrap(
              spacing: 8.0, // Adjust spacing between options
              runSpacing: 8.0,
              children: [
                _buildRadioOption('Tepat Waktu'),
                _buildRadioOption('Terlambat A'),
                _buildRadioOption('Terlambat B'),
                _buildRadioOption('Sakit'),
                _buildRadioOption('Izin'),
                _buildRadioOption('Tidak hadir'),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bobotController,
              decoration: InputDecoration(labelText: 'Bobot Kehadiran'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updatePresensi,
                child: Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    return ListTile(
      title: Text(value),
      leading: Radio<String>(
        value: value,
        groupValue: _presensiType,
        onChanged: (String? newValue) {
          setState(() {
            _presensiType = newValue;
          });
        },
      ),
    );
  }
}
