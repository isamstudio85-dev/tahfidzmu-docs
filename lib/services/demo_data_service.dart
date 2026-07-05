import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/musyrif_data.dart';
import '../models/halaqah_data.dart';
import '../models/graduation_event.dart';
import '../models/graduation_registration.dart';
import '../models/tasmi_record.dart';

class DemoDataService {
  static Future<DemoBundle> loadDemoData() async {
    // 1. Musyrif
    final List<MusyrifData> musyrifList = [
      const MusyrifData(id: 'm1', nip: '199001', nama: 'Ustadz Ahmad Fauzi', jabatan: 'Kepala Tahfidz', status: 'aktif'),
      const MusyrifData(id: 'm2', nip: '199502', nama: 'Ustadz Hilman Hakim', jabatan: 'Pembimbing Ikhwan', status: 'aktif'),
      const MusyrifData(id: 'm3', nip: '199803', nama: 'Ustadzah Siti Aminah', jabatan: 'Pembimbing Akhwat', status: 'aktif', jenisKelamin: 'P'),
    ];

    // 2. Halaqah
    final List<HalaqahData> halaqahList = [
      const HalaqahData(id: 'h1', nama: 'Halaqah Abu Bakar', musyrifId: 'm1'),
      const HalaqahData(id: 'h2', nama: 'Halaqah Umar Bin Khattab', musyrifId: 'm2'),
      const HalaqahData(id: 'h3', nama: 'Halaqah Khadijah', musyrifId: 'm3'),
    ];

    final currentYear = DateTime.now().year.toString();

    // 3. Graduation Events
    final List<GraduationEvent> graduationEvents = [
      GraduationEvent(
        id: 'e1',
        title: 'Haflah Takhorruj Angkatan 2026',
        year: '2026',
        examStartDate: DateTime.now().subtract(const Duration(days: 30)),
        examEndDate: DateTime.now().subtract(const Duration(days: 5)),
        graduationDate: DateTime.now().add(const Duration(days: 10)),
        method: "Tasmi' Sekali Duduk",
        requirements: "Minimal lulus Tasmi' 1 Juz Mutqin",
        description: "Assalamu'alaikum Wr. Wb. Diberitahukan kepada seluruh santri bahwa wisuda akan dilaksanakan di Gedung Aula Utama. Harap menyiapkan pakaian seragam putih.",
        isPublished: true,
        isCertificatesReleased: true,
        bannerPath: 'assets/images/wisuda tahfidz 2026.png',
      ),
    ];

    // 4. Graduation Registrations
    final List<GraduationRegistration> graduationRegistrations = [
      GraduationRegistration(
        id: 'reg1', eventId: 'e1', santriId: 's1', registrationDate: DateTime.now().subtract(const Duration(days: 20)),
        status: RegistrationStatus.diterima, registrationPaymentStatus: PaymentStatus.lunas, graduationPaymentStatus: PaymentStatus.lunas, registeredBy: 'parent'
      ),
      GraduationRegistration(
        id: 'reg2', eventId: 'e1', santriId: 's2', registrationDate: DateTime.now().subtract(const Duration(days: 15)),
        status: RegistrationStatus.diterima, registrationPaymentStatus: PaymentStatus.lunas, graduationPaymentStatus: PaymentStatus.belumBayar, registeredBy: 'parent'
      ),
      GraduationRegistration(
        id: 'reg3', eventId: 'e1', santriId: 's3', registrationDate: DateTime.now().subtract(const Duration(days: 5)),
        status: RegistrationStatus.menunggu, registrationPaymentStatus: PaymentStatus.belumBayar, graduationPaymentStatus: PaymentStatus.belumBayar, registeredBy: 'parent'
      ),
    ];

    // 5. Santri with diverse backgrounds (New and Advanced)
    final List<Santri> santriList = [
      // Advanced: Has 5 Juz already + passed 1 Juz Tasmi
      Santri(
        id: 's1', name: 'Muhammad Al-Fatih', nis: '2024001', kelas: '9A', halaqahId: 'h1',
        initialMemorizedJuz: [30, 29, 28, 1, 2], // 5 Juz
        setoranHistory: [
          SetoranRecord(
            id: 'r1', santriId: 's1', type: SetoranType.ziyadah, surahNumber: 3, 
            surahName: 'آل عمران', surahEnglishName: 'Al-Imran', ayahStart: 1, ayahEnd: 20, 
            errorMarks: const [], fluencyRating: 5, date: DateTime.now().subtract(const Duration(days: 1)), finalScore: 95
          ),
        ],
        tasmiHistory: [
          TasmiRecord(
            id: 't1', santriId: 's1', juzNumbers: [30], finalScore: 92, fluencyRating: 5, 
            errorMarks: const [], date: DateTime.now().subtract(const Duration(days: 10)), 
            status: 'lulus', year: currentYear, note: "Sangat lancar, makhroj mantap."
          ),
        ],
      ),
      // Mid: Has 2 Juz
      Santri(
        id: 's2', name: 'Abdurrahman Wahid', nis: '2024002', kelas: '8B', halaqahId: 'h1',
        initialMemorizedJuz: [30, 1], // 2 Juz
        setoranHistory: [
          SetoranRecord(
            id: 'r2', santriId: 's2', type: SetoranType.ziyadah, surahNumber: 2, 
            surahName: 'البقرة', surahEnglishName: 'Al-Baqarah', ayahStart: 142, ayahEnd: 152, 
            errorMarks: const [], fluencyRating: 4, date: DateTime.now().subtract(const Duration(hours: 5)), finalScore: 88
          ),
        ],
        tasmiHistory: [
          TasmiRecord(
            id: 't2', santriId: 's2', juzNumbers: [30], finalScore: 85, fluencyRating: 4, 
            errorMarks: const [], date: DateTime.now().subtract(const Duration(days: 12)), 
            status: 'lulus', year: currentYear
          ),
        ],
      ),
      // Beginner: 0 Juz
      Santri(
        id: 's3', name: 'Zaidan Nasir', nis: '2024003', kelas: '7C', halaqahId: 'h2',
        initialMemorizedJuz: const [], 
        setoranHistory: [
          SetoranRecord(
            id: 'r3', santriId: 's3', type: SetoranType.ziyadah, surahNumber: 78, 
            surahName: 'النبأ', surahEnglishName: 'An-Naba', ayahStart: 1, ayahEnd: 10, 
            errorMarks: const [], fluencyRating: 3, date: DateTime.now().subtract(const Duration(days: 2)), finalScore: 75
          ),
        ],
      ),
      // Advanced Akhwat: 3 Juz
      Santri(
        id: 's4', name: 'Aisyah Humaira', nis: '2024004', kelas: '9 Akhwat', halaqahId: 'h3',
        jenisKelamin: 'P', initialMemorizedJuz: [30, 29, 1],
        setoranHistory: const [],
        tasmiHistory: [
          TasmiRecord(
            id: 't3', santriId: 's4', juzNumbers: [30, 29], finalScore: 98, fluencyRating: 5, 
            errorMarks: const [], date: DateTime.now().subtract(const Duration(days: 8)), 
            status: 'lulus', year: currentYear
          ),
        ],
      ),
      // Mid Akhwat: 1 Juz
      Santri(
        id: 's5', name: 'Fathimah Azzahra', nis: '2024005', kelas: '7 Akhwat', halaqahId: 'h3',
        jenisKelamin: 'P', initialMemorizedJuz: [30],
        setoranHistory: [
          SetoranRecord(
            id: 'r4', santriId: 's5', type: SetoranType.ziyadah, surahNumber: 1, 
            surahName: 'الفاتحة', surahEnglishName: 'Al-Fatihah', ayahStart: 1, ayahEnd: 7,
            errorMarks: const [], fluencyRating: 5, date: DateTime.now(), finalScore: 100
          ),
        ],
      ),
    ];

    return DemoBundle(
      musyrifList: musyrifList, 
      halaqahList: halaqahList, 
      santriList: santriList,
      graduationEvents: graduationEvents,
      graduationRegistrations: graduationRegistrations,
    );
  }
}

class DemoBundle {
  final List<MusyrifData> musyrifList;
  final List<HalaqahData> halaqahList;
  final List<Santri> santriList;
  final List<GraduationEvent> graduationEvents;
  final List<GraduationRegistration> graduationRegistrations;
  DemoBundle({
    required this.musyrifList, 
    required this.halaqahList, 
    required this.santriList,
    required this.graduationEvents,
    required this.graduationRegistrations,
  });
}
