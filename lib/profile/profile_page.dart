import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  ProfilePage({required this.userData});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Fungsi untuk refresh data
  Future<void> _refreshData() async {
    // Simulasikan pengambilan data baru
    await Future.delayed(Duration(seconds: 1));

    // Jika kamu mengambil data dari server, lakukan di sini
    setState(() {
      // Contoh: update userData jika perlu
      // widget.userData = fetchNewUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Akun Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(), // Memungkinkan refresh meskipun tidak ada konten yang bisa discroll
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar profil di tengah-tengah
              if (widget.userData['profile_img'] != null &&
                  widget.userData['profile_img'].isNotEmpty)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                            imageUrl: widget.userData['profile_img'],
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 50, // Ukuran lingkaran
                      backgroundImage:
                          NetworkImage(widget.userData['profile_img']),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                )
              else
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                ),
              SizedBox(height: 16),
              // Identitas pengguna
              if (widget.userData['nama'] != null)
                buildInfoRow('Nama', widget.userData['nama']),
              if (widget.userData['gender'] != null)
                buildInfoRow('Jenis Kelamin', widget.userData['gender']),
              if (widget.userData['email'] != null)
                buildInfoRow('Email', widget.userData['email']),
              if (widget.userData['class_id'] != null)
                buildInfoRow('Kelas', widget.userData['class_id']),
              if (widget.userData['semester_id'] != null)
                buildInfoRow('Semester', widget.userData['semester_id']),
              SizedBox(height: 1),
              // Tombol Logout
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacementNamed(
                        '/login'); // Adjust route as needed
                  } catch (e) {
                    print("Error logging out: $e");
                  }
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(value ?? ''),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Gambar Profil'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
