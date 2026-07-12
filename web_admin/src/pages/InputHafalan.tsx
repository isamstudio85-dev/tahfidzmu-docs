import { useEffect, useState, useMemo } from "react";
import { collection, doc, getDocs, setDoc, updateDoc, increment, query, orderBy, limit } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Search, Save, User, BookOpen, Star, CheckCircle2, AlertCircle } from "lucide-react";
import defaultAvatar from "../../../assets/images/avatar-default.png";

const surahs: SurahInfo[] = [
  {"number": 1, "name": "الفاتحة", "englishName": "Al-Fatihah", "numberOfAyahs": 7},
  {"number": 2, "name": "البقرة", "englishName": "Al-Baqarah", "numberOfAyahs": 286},
  {"number": 3, "name": "آل عمران", "englishName": "Al-Imran", "numberOfAyahs": 200},
  {"number": 4, "name": "النساء", "englishName": "An-Nisa", "numberOfAyahs": 176},
  {"number": 5, "name": "المائدة", "englishName": "Al-Ma'idah", "numberOfAyahs": 120},
  {"number": 6, "name": "الأنعام", "englishName": "Al-An'am", "numberOfAyahs": 165},
  {"number": 7, "name": "الأعراف", "englishName": "Al-A'raf", "numberOfAyahs": 206},
  {"number": 8, "name": "الأنفال", "englishName": "Al-Anfal", "numberOfAyahs": 75},
  {"number": 9, "name": "التوبة", "englishName": "At-Tawbah", "numberOfAyahs": 129},
  {"number": 10, "name": "يونس", "englishName": "Yunus", "numberOfAyahs": 109},
  {"number": 11, "name": "هود", "englishName": "Hud", "numberOfAyahs": 123},
  {"number": 12, "name": "يوسف", "englishName": "Yusuf", "numberOfAyahs": 111},
  {"number": 13, "name": "الرعد", "englishName": "Ar-Ra'd", "numberOfAyahs": 43},
  {"number": 14, "name": "إبراهيم", "englishName": "Ibrahim", "numberOfAyahs": 52},
  {"number": 15, "name": "الحجر", "englishName": "Al-Hijr", "numberOfAyahs": 99},
  {"number": 16, "name": "النحل", "englishName": "An-Nahl", "numberOfAyahs": 128},
  {"number": 17, "name": "الإسراء", "englishName": "Al-Isra", "numberOfAyahs": 111},
  {"number": 18, "name": "الكهf", "englishName": "Al-Kahf", "numberOfAyahs": 110},
  {"number": 19, "name": "مريم", "englishName": "Maryam", "numberOfAyahs": 98},
  {"number": 20, "name": "طه", "englishName": "Ta-Ha", "numberOfAyahs": 135},
  {"number": 21, "name": "الأنبياء", "englishName": "Al-Anbiya", "numberOfAyahs": 112},
  {"number": 22, "name": "الحج", "englishName": "Al-Hajj", "numberOfAyahs": 78},
  {"number": 23, "name": "المؤمنون", "englishName": "Al-Mu'minun", "numberOfAyahs": 118},
  {"number": 24, "name": "النور", "englishName": "An-Nur", "numberOfAyahs": 64},
  {"number": 25, "name": "الفرقان", "englishName": "Al-Furqan", "numberOfAyahs": 77},
  {"number": 26, "name": "الشعراء", "englishName": "Ash-Shu'ara", "numberOfAyahs": 227},
  {"number": 27, "name": "النمل", "englishName": "An-Naml", "numberOfAyahs": 93},
  {"number": 28, "name": "القصص", "englishName": "Al-Qasas", "numberOfAyahs": 88},
  {"number": 29, "name": "العنكبوت", "englishName": "Al-Ankabut", "numberOfAyahs": 69},
  {"number": 30, "name": "الروم", "englishName": "Ar-Rum", "numberOfAyahs": 60},
  {"number": 31, "name": "لقمان", "englishName": "Luqman", "numberOfAyahs": 34},
  {"number": 32, "name": "السجدة", "englishName": "As-Sajdah", "numberOfAyahs": 30},
  {"number": 33, "name": "الأحزاب", "englishName": "Al-Ahzab", "numberOfAyahs": 73},
  {"number": 34, "name": "سبأ", "englishName": "Saba", "numberOfAyahs": 54},
  {"number": 35, "name": "فاطر", "englishName": "Fatir", "numberOfAyahs": 45},
  {"number": 36, "name": "يس", "englishName": "Ya-Sin", "numberOfAyahs": 83},
  {"number": 37, "name": "الصافات", "englishName": "As-Saffat", "numberOfAyahs": 182},
  {"number": 38, "name": "ص", "englishName": "Sad", "numberOfAyahs": 88},
  {"number": 39, "name": "الزمر", "englishName": "Az-Zumar", "numberOfAyahs": 75},
  {"number": 40, "name": "غافر", "englishName": "Ghafir", "numberOfAyahs": 85},
  {"number": 41, "name": "فصلت", "englishName": "Fussilat", "numberOfAyahs": 54},
  {"number": 42, "name": "الشورى", "englishName": "Ash-Shura", "numberOfAyahs": 53},
  {"number": 43, "name": "الزخرف", "englishName": "Az-Zukhruf", "numberOfAyahs": 89},
  {"number": 44, "name": "الدخان", "englishName": "Ad-Dukhan", "numberOfAyahs": 59},
  {"number": 45, "name": "الجاثية", "englishName": "Al-Jathiyah", "numberOfAyahs": 37},
  {"number": 46, "name": "الأحقاف", "englishName": "Al-Ahqaf", "numberOfAyahs": 35},
  {"number": 47, "name": "محمد", "englishName": "Muhammad", "numberOfAyahs": 38},
  {"number": 48, "name": "الفتح", "englishName": "Al-Fath", "numberOfAyahs": 29},
  {"number": 49, "name": "الحجرات", "englishName": "Al-Hujurat", "numberOfAyahs": 18},
  {"number": 50, "name": "ق", "englishName": "Qaf", "numberOfAyahs": 45},
  {"number": 51, "name": "الذاريات", "englishName": "Adh-Dhariyat", "numberOfAyahs": 60},
  {"number": 52, "name": "الطور", "englishName": "At-Tur", "numberOfAyahs": 49},
  {"number": 53, "name": "النجم", "englishName": "An-Najm", "numberOfAyahs": 62},
  {"number": 54, "name": "القمر", "englishName": "Al-Qamar", "numberOfAyahs": 55},
  {"number": 55, "name": "الرحمن", "englishName": "Ar-Rahman", "numberOfAyahs": 78},
  {"number": 56, "name": "الواقعة", "englishName": "Al-Waqi'ah", "numberOfAyahs": 96},
  {"number": 57, "name": "الحديد", "englishName": "Al-Hadid", "numberOfAyahs": 29},
  {"number": 58, "name": "المجادلة", "englishName": "Al-Mujadilah", "numberOfAyahs": 22},
  {"number": 59, "name": "الحشر", "englishName": "Al-Hashr", "numberOfAyahs": 24},
  {"number": 60, "name": "الممتحنة", "englishName": "Al-Mumtahanah", "numberOfAyahs": 13},
  {"number": 61, "name": "الصف", "englishName": "As-Saff", "numberOfAyahs": 14},
  {"number": 62, "name": "الجمعة", "englishName": "Al-Jumu'ah", "numberOfAyahs": 11},
  {"number": 63, "name": "المنافقون", "englishName": "Al-Munafiqun", "numberOfAyahs": 11},
  {"number": 64, "name": "التغابن", "englishName": "At-Taghabun", "numberOfAyahs": 18},
  {"number": 65, "name": "الطلاق", "englishName": "At-Talaq", "numberOfAyahs": 12},
  {"number": 66, "name": "التحريم", "englishName": "At-Tahrim", "numberOfAyahs": 12},
  {"number": 67, "name": "الملك", "englishName": "Al-Mulk", "numberOfAyahs": 30},
  {"number": 68, "name": "القلم", "englishName": "Al-Qalam", "numberOfAyahs": 52},
  {"number": 69, "name": "الحاقة", "englishName": "Al-Haqqah", "numberOfAyahs": 52},
  {"number": 70, "name": "المعارج", "englishName": "Al-Ma'arij", "numberOfAyahs": 44},
  {"number": 71, "name": "نوح", "englishName": "Nuh", "numberOfAyahs": 28},
  {"number": 72, "name": "الجن", "englishName": "Al-Jinn", "numberOfAyahs": 28},
  {"number": 73, "name": "المزمل", "englishName": "Al-Muzzammil", "numberOfAyahs": 20},
  {"number": 74, "name": "المدثر", "englishName": "Al-Muddaththir", "numberOfAyahs": 56},
  {"number": 75, "name": "القيامة", "englishName": "Al-Qiyamah", "numberOfAyahs": 40},
  {"number": 76, "name": "الإنسان", "englishName": "Al-Insan", "numberOfAyahs": 31},
  {"number": 77, "name": "المرسلات", "englishName": "Al-Mursalat", "numberOfAyahs": 50},
  {"number": 78, "name": "النبأ", "englishName": "An-Naba", "numberOfAyahs": 40},
  {"number": 79, "name": "النازعات", "englishName": "An-Nazi'at", "numberOfAyahs": 46},
  {"number": 80, "name": "عبس", "englishName": "'Abasa", "numberOfAyahs": 42},
  {"number": 81, "name": "التكوير", "englishName": "At-Takwir", "numberOfAyahs": 29},
  {"number": 82, "name": "الانفطار", "englishName": "Al-Infitar", "numberOfAyahs": 19},
  {"number": 83, "name": "المطففين", "englishName": "Al-Mutaffifin", "numberOfAyahs": 36},
  {"number": 84, "name": "الانشقاق", "englishName": "Al-Inshiqaq", "numberOfAyahs": 25},
  {"number": 85, "name": "البروج", "englishName": "Al-Buruj", "numberOfAyahs": 22},
  {"number": 86, "name": "الطارق", "englishName": "At-Tariq", "numberOfAyahs": 17},
  {"number": 87, "name": "الأعلى", "englishName": "Al-A'la", "numberOfAyahs": 19},
  {"number": 88, "name": "الغاشية", "englishName": "Al-Ghashiyah", "numberOfAyahs": 26},
  {"number": 89, "name": "الفجر", "englishName": "Al-Fajr", "numberOfAyahs": 30},
  {"number": 90, "name": "البلد", "englishName": "Al-Balad", "numberOfAyahs": 20},
  {"number": 91, "name": "الشمس", "englishName": "Ash-Shams", "numberOfAyahs": 15},
  {"number": 92, "name": "الليل", "englishName": "Al-Layl", "numberOfAyahs": 21},
  {"number": 93, "name": "الضحى", "englishName": "Ad-Duha", "numberOfAyahs": 11},
  {"number": 94, "name": "الشرح", "englishName": "Ash-Sharh", "numberOfAyahs": 8},
  {"number": 95, "name": "التين", "englishName": "At-Tin", "numberOfAyahs": 8},
  {"number": 96, "name": "العلق", "englishName": "Al-'Alaq", "numberOfAyahs": 19},
  {"number": 97, "name": "القدر", "englishName": "Al-Qadr", "numberOfAyahs": 5},
  {"number": 98, "name": "البينة", "englishName": "Al-Bayyinah", "numberOfAyahs": 8},
  {"number": 99, "name": "الزلزلة", "englishName": "Az-Zalzalah", "numberOfAyahs": 8},
  {"number": 100, "name": "العاديات", "englishName": "Al-'Adiyat", "numberOfAyahs": 11},
  {"number": 101, "name": "القارعة", "englishName": "Al-Qari'ah", "numberOfAyahs": 11},
  {"number": 102, "name": "التكاثر", "englishName": "At-Takathur", "numberOfAyahs": 8},
  {"number": 103, "name": "العصر", "englishName": "Al-'Asr", "numberOfAyahs": 3},
  {"number": 104, "name": "الهمزة", "englishName": "Al-Humazah", "numberOfAyahs": 9},
  {"number": 105, "name": "الفيل", "englishName": "Al-Fil", "numberOfAyahs": 5},
  {"number": 106, "name": "قريش", "englishName": "Quraish", "numberOfAyahs": 4},
  {"number": 107, "name": "الماعون", "englishName": "Al-Ma'un", "numberOfAyahs": 7},
  {"number": 108, "name": "الكوثر", "englishName": "Al-Kawthar", "numberOfAyahs": 3},
  {"number": 109, "name": "الكافرون", "englishName": "Al-Kafirun", "numberOfAyahs": 6},
  {"number": 110, "name": "النصر", "englishName": "An-Nasr", "numberOfAyahs": 3},
  {"number": 111, "name": "المسد", "englishName": "Al-Masad", "numberOfAyahs": 5},
  {"number": 112, "name": "الإخلاص", "englishName": "Al-Ikhlas", "numberOfAyahs": 4},
  {"number": 113, "name": "الفلق", "englishName": "Al-Falaq", "numberOfAyahs": 5},
  {"number": 114, "name": "الناس", "englishName": "An-Nas", "numberOfAyahs": 6}
];

type SurahInfo = {
  number: number;
  name: string;
  englishName: string;
  numberOfAyahs: number;
};

type SantriLite = {
  id: string;
  name: string;
  nis: string;
  photoPath: string | null;
  halaqahId: string | null;
  averageScore: number;
  totalSetoranCount: number;
  totalZiyadahAyahs: number;
  totalMurojaahAyahs: number;
  totalErrors: number;
  juzCoveredByZiyadah: number[];
};

export default function InputHafalan() {
  const { profile } = useAuth();
  const [santriList, setSantriList] = useState<SantriLite[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedSantri, setSelectedSantri] = useState<SantriLite | null>(null);
  const [searchSantri, setSearchSantri] = useState("");

  const [type, setType] = useState<"ziyadah" | "murojaah">("ziyadah");
  const [surahNum, setSurahNum] = useState(1);
  const [ayahStart, setAyahStart] = useState(1);
  const [ayahEnd, setAyahEnd] = useState(10);
  const [tajwidErrors, setTajwidErrors] = useState(0);
  const [makhrojErrors, setMakhrojErrors] = useState(0);
  const [fluency, setFluency] = useState(5);

  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    if (selectedSantri) {
       fetchNextSuggestion(selectedSantri.id);
    }
  }, [selectedSantri]);

  const fetchNextSuggestion = async (santriId: string) => {
    const pid = profile?.pesantrenId;
    if (!pid) return;

    try {
      const q = query(
        collection(db, "pesantren", pid, "santri", santriId, "setoranHistory"),
        orderBy("date", "desc"),
        limit(1)
      );
      const snap = await getDocs(q);
      if (!snap.empty) {
        const last = snap.docs[0].data();
        const lastSurahNum = last.surahNumber as number;
        const lastAyahEnd = last.ayahEnd as number;
        const lastType = last.type as "ziyadah" | "murojaah";

        const surah = surahs.find(s => s.number === lastSurahNum);
        if (surah) {
           if (lastAyahEnd < surah.numberOfAyahs) {
              setSurahNum(lastSurahNum);
              setAyahStart(lastAyahEnd + 1);
              setAyahEnd(Math.min(lastAyahEnd + 10, surah.numberOfAyahs));
           } else if (lastSurahNum < 114) {
              const nextSurah = surahs.find(s => s.number === lastSurahNum + 1);
              setSurahNum(lastSurahNum + 1);
              setAyahStart(1);
              setAyahEnd(Math.min(10, nextSurah?.numberOfAyahs || 1));
           }
        }
        setType(lastType);
      }
    } catch (e) {
      console.warn("Failed to fetch suggestion:", e);
    }
  };

  useEffect(() => {
    if (profile?.pesantrenId) {
      loadData();
    }
  }, [profile?.pesantrenId]);

  const loadData = async () => {
    setLoading(true);
    try {
      const pid = profile?.pesantrenId;
      if (!pid) return;

      const sSnap = await getDocs(collection(db, "pesantren", pid, "santri"));
      const sList = sSnap.docs.map(d => ({ id: d.id, ...d.data() } as SantriLite));
      setSantriList(sList);
      if (sList.length > 0) setSelectedSantri(sList[0]);

    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const currentSurah = useMemo(() => surahs.find(s => s.number === surahNum), [surahNum]);

  const filteredSantri = useMemo(() => {
    const q = searchSantri.toLowerCase();
    return santriList.filter(s => s.name.toLowerCase().includes(q) || s.nis.includes(q));
  }, [santriList, searchSantri]);

  const calculateScore = () => {
    const errorScore = Math.max(0, 100 - (tajwidErrors * 3 + makhrojErrors * 2));
    const fluencyScore = fluency * 20;
    const finalScore = (errorScore * 0.6) + (fluencyScore * 0.4);
    return Math.max(0, Math.min(100, finalScore));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSantri || !currentSurah || !profile?.pesantrenId) return;

    setSaving(true);
    setMessage(null);
    try {
      const pid = profile.pesantrenId;
      const finalScore = calculateScore();
      const setoranId = `setoran_${Date.now()}`;

      const record = {
        id: setoranId,
        santriId: selectedSantri.id,
        type,
        surahNumber: surahNum,
        surahName: currentSurah.name,
        surahEnglishName: currentSurah.englishName,
        ayahStart,
        ayahEnd,
        passedAyahs: Array.from({ length: ayahEnd - ayahStart + 1 }, (_, i) => ayahStart + i),
        failedAyahs: [],
        errorMarks: [],
        fluencyRating: fluency,
        date: new Date().toISOString(),
        finalScore,
        pesantrenId: pid,
        halaqahId: selectedSantri.halaqahId,
      };

      await setDoc(doc(db, "pesantren", pid, "santri", selectedSantri.id, "setoranHistory", setoranId), record);

      const newCount = (selectedSantri.totalSetoranCount || 0) + 1;
      const newAvg = (((selectedSantri.averageScore || 0) * (selectedSantri.totalSetoranCount || 0)) + finalScore) / newCount;

      const addedAyahs = ayahEnd - ayahStart + 1;
      const updateData: any = {
        averageScore: newAvg,
        totalSetoranCount: newCount,
        totalErrors: increment(tajwidErrors + makhrojErrors),
        lastSetoranAt: record.date,
      };

      if (type === "ziyadah") {
        updateData.totalZiyadahAyahs = (selectedSantri.totalZiyadahAyahs || 0) + addedAyahs;
        updateData.estimatedJuz = (selectedSantri.totalZiyadahAyahs + addedAyahs) / 604;
      } else {
        updateData.totalMurojaahAyahs = (selectedSantri.totalMurojaahAyahs || 0) + addedAyahs;
      }

      await updateDoc(doc(db, "pesantren", pid, "santri", selectedSantri.id), updateData);

      setMessage({ type: "success", text: `Setoran ${selectedSantri.name} berhasil disimpan.` });
      setTajwidErrors(0);
      setMakhrojErrors(0);
      setFluency(5);

    } catch (err: any) {
      console.error(err);
      setMessage({ type: "error", text: "Gagal menyimpan: " + err.message });
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <PageMeta title="Input Hafalan | TahfidzMU Admin" description="Rekapitulasi setoran hafalan santri dengan cepat." />

      <div className="h-[calc(100vh-120px)] flex flex-col lg:flex-row gap-6">
        {/* Left Column: Santri Selection */}
        <div className="w-full lg:w-80 flex flex-col bg-white dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 rounded-2xl overflow-hidden shadow-sm">
          <div className="p-4 border-b border-gray-100 dark:border-gray-800">
            <h3 className="font-bold text-gray-800 dark:text-white mb-3 text-start">Pilih Santri</h3>
            <div className="relative">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Cari nama/NIS..."
                value={searchSantri}
                onChange={(e) => setSearchSantri(e.target.value)}
                className="w-full pl-9 pr-3 py-2 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl text-sm outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white"
              />
            </div>
          </div>

          <div className="flex-1 overflow-y-auto custom-scrollbar">
            {filteredSantri.map(s => (
              <button
                key={s.id}
                onClick={() => setSelectedSantri(s)}
                className={`w-full flex items-center gap-3 p-3 text-left transition ${selectedSantri?.id === s.id ? "bg-brand-50 dark:bg-brand-500/10 border-r-4 border-brand-500" : "hover:bg-gray-50 dark:hover:bg-white/5"}`}
              >
                <img src={s.photoPath || defaultAvatar} className="w-9 h-9 rounded-full object-cover" alt="" />
                <div className="min-w-0">
                  <p className={`text-sm font-bold truncate ${selectedSantri?.id === s.id ? "text-brand-700 dark:text-brand-400" : "text-gray-800 dark:text-gray-200"}`}>{s.name}</p>
                  <p className="text-[10px] text-gray-500 font-mono">{s.nis}</p>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Right Column: Input Form */}
        <div className="flex-1 bg-white dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 rounded-2xl shadow-sm flex flex-col overflow-hidden">
          {selectedSantri ? (
            <form onSubmit={handleSave} className="flex-1 overflow-y-auto p-6 lg:p-8 custom-scrollbar">
              <div className="flex items-center gap-4 mb-8 text-start">
                <div className="p-3 bg-brand-50 dark:bg-brand-500/10 rounded-2xl">
                  <User size={32} className="text-brand-600 dark:text-brand-400" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-gray-900 dark:text-white">{selectedSantri.name}</h3>
                  <p className="text-sm text-gray-500">Rekapitulasi setoran hafalan - Mode Cepat</p>
                </div>
              </div>

              {message && (
                <div className={`mb-6 p-4 rounded-2xl flex items-center gap-3 text-sm font-medium ${message.type === 'success' ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-red-50 text-red-700 border border-red-100'}`}>
                  {message.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                  {message.text}
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-start">
                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Tipe Setoran</label>
                  <div className="flex bg-gray-50 dark:bg-gray-800 p-1 rounded-xl border border-gray-200 dark:border-gray-700">
                    <button type="button" onClick={() => setType("ziyadah")} className={`flex-1 py-2 text-sm font-bold rounded-lg transition ${type === 'ziyadah' ? "bg-white dark:bg-gray-700 text-brand-600 shadow-sm" : "text-gray-500"}`}>Ziyadah</button>
                    <button type="button" onClick={() => setType("murojaah")} className={`flex-1 py-2 text-sm font-bold rounded-lg transition ${type === 'murojaah' ? "bg-white dark:bg-gray-700 text-brand-600 shadow-sm" : "text-gray-500"}`}>Muroja'ah</button>
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Pilih Surah</label>
                  <select
                    value={surahNum}
                    onChange={(e) => {
                      const n = Number(e.target.value);
                      setSurahNum(n);
                      const s = surahs.find(x => x.number === n);
                      if (s) {
                        setAyahStart(1);
                        setAyahEnd(Math.min(10, s.numberOfAyahs));
                      }
                    }}
                    className="w-full px-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl text-sm outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white"
                  >
                    {surahs.map(s => (
                      <option key={s.number} value={s.number}>{s.number}. {s.englishName}</option>
                    ))}
                  </select>
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Ayat Mulai</label>
                  <input
                    type="number"
                    min={1}
                    max={currentSurah?.numberOfAyahs || 1}
                    value={ayahStart}
                    onChange={(e) => setAyahStart(Number(e.target.value))}
                    className="w-full px-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl text-sm outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Ayat Selesai</label>
                  <input
                    type="number"
                    min={ayahStart}
                    max={currentSurah?.numberOfAyahs || 1}
                    value={ayahEnd}
                    onChange={(e) => setAyahEnd(Number(e.target.value))}
                    className="w-full px-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl text-sm outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Total Salah Tajwid</label>
                  <div className="flex items-center gap-4">
                    <button type="button" onClick={() => setTajwidErrors(Math.max(0, tajwidErrors - 1))} className="w-10 h-10 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-50 dark:hover:bg-white/5 text-gray-600 dark:text-gray-300">-</button>
                    <span className="text-xl font-bold w-12 text-center text-orange-600">{tajwidErrors}</span>
                    <button type="button" onClick={() => setTajwidErrors(tajwidErrors + 1)} className="w-10 h-10 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-50 dark:hover:bg-white/5 text-gray-600 dark:text-gray-300">+</button>
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Total Salah Makhroj</label>
                  <div className="flex items-center gap-4">
                    <button type="button" onClick={() => setMakhrojErrors(Math.max(0, makhrojErrors - 1))} className="w-10 h-10 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-50 dark:hover:bg-white/5 text-gray-600 dark:text-gray-300">-</button>
                    <span className="text-xl font-bold w-12 text-center text-blue-600">{makhrojErrors}</span>
                    <button type="button" onClick={() => setMakhrojErrors(makhrojErrors + 1)} className="w-10 h-10 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-50 dark:hover:bg-white/5 text-gray-600 dark:text-gray-300">+</button>
                  </div>
                </div>
              </div>

              <div className="mt-8 p-6 bg-amber-50/50 dark:bg-amber-500/5 rounded-2xl border border-amber-100 dark:border-amber-500/10">
                <label className="block text-center text-xs font-bold text-amber-800 dark:text-amber-400 uppercase tracking-wider mb-4">Tingkat Kelancaran</label>
                <div className="flex justify-center gap-4">
                  {[1, 2, 3, 4, 5].map(v => (
                    <button
                      key={v}
                      type="button"
                      onClick={() => setFluency(v)}
                      className={`w-12 h-12 rounded-xl flex items-center justify-center transition-all ${fluency >= v ? 'bg-amber-500 text-white shadow-md scale-110' : 'bg-gray-200 dark:bg-gray-800 text-gray-400'}`}
                    >
                      <Star size={20} fill={fluency >= v ? "currentColor" : "none"} />
                    </button>
                  ))}
                </div>
                <p className="text-center mt-4 font-bold text-amber-700 dark:text-amber-300">
                  {fluency === 5 ? 'Sangat Lancar' : fluency === 4 ? 'Lancar' : fluency === 3 ? 'Cukup Lancar' : fluency === 2 ? 'Kurang Lancar' : 'Tidak Lancar'}
                </p>
              </div>

              <div className="mt-8 flex flex-col items-center">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Prediksi Skor</p>
                <p className="text-5xl font-black text-brand-600 dark:text-brand-400">{calculateScore().toFixed(0)}</p>
              </div>

              <div className="mt-10 pt-6 border-t border-gray-100 dark:border-gray-800 flex justify-end">
                <button
                  type="submit"
                  disabled={saving}
                  className="px-10 py-4 bg-brand-500 hover:bg-brand-600 text-white font-bold rounded-2xl shadow-lg shadow-brand-500/20 transition-all active:scale-[0.98] disabled:opacity-50 flex items-center gap-3"
                >
                  <Save size={20} />
                  {saving ? "Menyimpan..." : "Simpan Hasil Setoran"}
                </button>
              </div>
            </form>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center p-12 text-center">
              <div className="p-6 bg-gray-50 dark:bg-white/5 rounded-full mb-4">
                <BookOpen size={48} className="text-gray-300" />
              </div>
              <h3 className="text-lg font-bold text-gray-800 dark:text-white">Pilih Santri</h3>
              <p className="text-sm text-gray-500 max-w-xs mt-1">Silakan pilih santri di daftar sebelah kiri untuk mulai menginput data hafalan Al-Quran.</p>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
