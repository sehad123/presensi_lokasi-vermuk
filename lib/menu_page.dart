import 'package:flutter/material.dart';
import 'package:presensi_app/dosen/list_dosen.dart';
import 'package:presensi_app/list_jadwal.dart';
import 'package:presensi_app/mahasiswa/list_mahasiswa.dart';
import 'package:presensi_app/matkul_class/list_matkul_class.dart';
import 'package:presensi_app/matkul_dosen/list_matkul_dosen.dart';
import 'package:presensi_app/rekap_presensi_dosen.dart';
import 'package:presensi_app/rekap_presensi_mahasiswa.dart';
import 'package:presensi_app/semester_class/list_semester_class.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //     // title: Text('Daftar Menu Halaman'),
      //     ),
      body: ListView(
        children: [
          // Mahasiswa Menu Item
          ListTile(
            title: Text('Mahasiswa'),
            onTap: () {
              // Aksi ketika Mahasiswa diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MahasiswaPage()),
              );
            },
          ),
          Divider(),

          // Dosen Menu Item
          ListTile(
            title: Text('Dosen'),
            onTap: () {
              // Aksi ketika Dosen diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DosenPage()),
              );
            },
          ),
          Divider(),

          // Sub Menu Akademik (Dipindahkan dari ExpansionTile)
          ListTile(
            title: Text('Semester & Class'),
            onTap: () {
              // Aksi ketika Semester & Class diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SemesterClassPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Matkul & Class'),
            onTap: () {
              // Aksi ketika Matkul & Class diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MatkulClassPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Matkul & Dosen'),
            onTap: () {
              // Aksi ketika Matkul & Dosen diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MatkulDosenPage()),
              );
            },
          ),
          Divider(),

          // Jadwal Class Menu Item
          ListTile(
            title: Text('Jadwal Class'),
            onTap: () {
              // Aksi ketika Jadwal Class diklik
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JadwalClassPage()),
              );
            },
          ),
          Divider(),

          // Presensi Menu with Dropdown
          ExpansionTile(
            title: Text('Presensi'),
            children: [
              ListTile(
                title: Text('Mahasiswa'),
                onTap: () {
                  // Aksi ketika Presensi Mahasiswa diklik
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PresensiMahasiswaPage()),
                  );
                },
              ),
              ListTile(
                title: Text('Dosen'),
                onTap: () {
                  // Aksi ketika Presensi Dosen diklik
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PresensiDosenPage()),
                  );
                },
              ),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }
}

// Placeholder pages for navigation
class MahasiswaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mahasiswa')),
      body: ListMahasiswa(),
    );
  }
}

class DosenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Dosen')), body: ListDosen());
  }
}

class SemesterClassPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Semester & Class')),
      body: ListSemesterClassPage(),
    );
  }
}

class MatkulClassPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matkul & Class')),
      body: MatkulClassListPage(),
    );
  }
}

class MatkulDosenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matkul & Dosen')),
      body: MatkulDosenListPage(),
    );
  }
}

class JadwalClassPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal Class')),
      body: ListJadwal(),
    );
  }
}

class PresensiMahasiswaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Presensi Mahasiswa')),
      body: RekapPresensiMahasiswaFiltered(),
    );
  }
}

class PresensiDosenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Presensi Dosen')),
      body: RekapPresensiDosenFiltered(),
    );
  }
}
