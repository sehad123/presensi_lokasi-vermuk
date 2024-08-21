import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presensi_app/dashboard.dart';
import 'package:presensi_app/dosen/cek_presensi_mahasiswa.dart';
import 'package:presensi_app/dosen/jadwal_dosen.dart';
import 'package:presensi_app/dosen/list_jadwal_dosen.dart';
import 'package:presensi_app/dosen/mypresensi_dosen.dart';
import 'package:presensi_app/list_jadwal.dart';
import 'package:presensi_app/mahasiswa/jadwal_mahasiswa.dart';
import 'package:presensi_app/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:presensi_app/menu_page.dart';
import 'package:presensi_app/profile/profile_page.dart';
import 'package:presensi_app/rekap_presensi_mahasiswa.dart';

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
      print("Fetching data for user ID: ${widget.userId}");
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
        print("User data: $_userData");
      } else {
        print("User data not found for ID: ${widget.userId}");
      }
    } catch (e, stacktrace) {
      print("Error fetching user data: $e");
      print("Stacktrace: $stacktrace");
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
              return JadwalDosenSTIS(userData: _userData!);
            case 1:
              return RekapPresensiDosen(userData: _userData!);
            case 2:
              return CekPresensiMahasiswa(userData: _userData!);
            case 3:
              return ListJadwalDosen(userData: _userData!);
            case 4:
              return ProfilePage(userData: _userData!);
            default:
              return Center(child: Text('Page not found'));
          }
        default:
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
      }
    }

    List<BottomNavigationBarItem> _getBottomNavigationBarItems() {
      if (_userData == null) {
        return [];
      }

      switch (_userData!['user_type']) {
        case 1:
          return [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];
        case 2:
          return [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Jadwal Kuliah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Presensi Saya',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Presensi Mahasiswa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Jadwal Saya',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];
        default:
          return [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Jadwal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];
      }
    }

    return Scaffold(
        appBar: AppBar(title: Text('Presensi')),
        body: _getSelectedPage(),
        bottomNavigationBar: BottomNavigationBar(
          items: _getBottomNavigationBarItems(),
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          onTap: _onItemTapped,
        ));
  }
}
