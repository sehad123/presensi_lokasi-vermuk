import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presensi_api/dashboard.dart';
import 'package:presensi_api/dosen/jadwal_dosen.dart';
import 'package:presensi_api/dosen/mypresensi_dosen.dart';
import 'package:presensi_api/mahasiswa/jadwal_mahasiswa.dart';
import 'package:presensi_api/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:presensi_api/menu_page.dart';
import 'package:presensi_api/profile/profile_page.dart';
import 'package:presensi_api/rekap_presensi_mahasiswa.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      } else {
        print("User data not found.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    Widget _getSelectedPage() {
      if (_userData == null) {
        return Center(child: CircularProgressIndicator());
      }

      switch (_userData!['user_type']) {
        case 1:
          switch (_selectedIndex) {
            case 0:
              return DashboardPage();
            case 1:
              return MenuPage();
            case 2:
              return ProfilePage(userData: _userData!);
            default:
              return Center(child: Text('Page not found'));
          }
        case 2:
          switch (_selectedIndex) {
            case 0:
              return JadwalMahasiswastis(userData: _userData!);
            case 1:
              return RekapPresensiMahasiswa(userData: _userData!);
            case 2:
              return ProfilePage(userData: _userData!);
            default:
              return Center(child: Text('Page not found'));
          }
        case 3:
          switch (_selectedIndex) {
            case 0:
              return JadwalDosenSTIS(userData: _userData!);
            case 1:
              return RekapPresensiDosen(userData: _userData!);
            case 2:
              return RekapPresensiMahasiswaFiltered();
            case 3:
              return ProfilePage(userData: _userData!);
            default:
              return Center(child: Text('Page not found'));
          }
        default:
          return Center(child: Text('Page not found'));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Presensi')),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: _userData == null
            ? []
            : _userData!['user_type'] == 3
                ? <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Jadwal',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list_sharp),
                      label: 'Presensi Saya',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list),
                      label: 'Presensi Mahasiswa',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ]
                : <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label:
                          _userData!['user_type'] == 1 ? 'Dashboard' : 'Jadwal',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu),
                      label:
                          _userData!['user_type'] == 1 ? 'Menu' : 'Kehadiran',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholder pages for additional menus

