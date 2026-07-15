import { useEffect, useState, useMemo } from "react";
import { collection, query, where, orderBy, limit, getDocs, collectionGroup, Timestamp } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { History, TrendingUp, Search, Users, Star } from "lucide-react";
import defaultAvatar from "../assets/images/avatar-default.png";

type SetoranRecord = {
  id: string;
  santriId: string;
  surahEnglishName: string;
  ayahStart: number;
  ayahEnd: number;
  finalScore: number;
  date: string;
  type: string;
  pesantrenId: string;
};

type SantriData = {
  id: string;
  name: string;
  nis: string;
  photoPath: string | null;
  estimatedJuz: number;
  averageScore: number;
};

export default function MonitoringProgres() {
  const { profile } = useAuth();
  const [setorans, setSetorans] = useState<SetoranRecord[]>([]);
  const [santriList, setSantriList] = useState<SantriData[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<"riwayat" | "peringkat" | "presensi">("riwayat");
  const [presensiList, setPresensiList] = useState<any[]>([]);

  useEffect(() => {
    if (profile?.pesantrenId) {
      loadData();
    }
  }, [profile?.pesantrenId]);

  const loadData = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;

      const santriSnap = await getDocs(collection(db, "pesantren", pid, "santri"));
      const sList = santriSnap.docs.map(d => {
        const data = d.data();
        return {
          id: d.id,
          name: String(data.name || ""),
          nis: String(data.nis || ""),
          photoPath: data.photoPath || null,
          estimatedJuz: Number(data.estimatedJuz || 0),
          averageScore: Number(data.averageScore || 0),
        };
      });
      setSantriList(sList);

      const q = query(
        collectionGroup(db, "setoranHistory"),
        where("pesantrenId", "==", pid),
        orderBy("date", "desc"),
        limit(50)
      );
      const setoranSnap = await getDocs(q);
      setSetorans(setoranSnap.docs.map(d => ({ id: d.id, ...d.data() } as SetoranRecord)));

      const presensiSnap = await getDocs(query(collection(db, "pesantren", pid, "presensi"), orderBy("tanggal", "desc"), limit(30)));
      setPresensiList(presensiSnap.docs.map(d => ({ id: d.id, ...d.data() })));

    } catch (err) {
      console.error("Error loading monitoring data:", err);
    } finally {
      setLoading(false);
    }
  };

  const getSantri = (id: string) => santriList.find(s => s.id === id);

  const rankedSantri = useMemo(() => {
    return [...santriList].sort((a, b) => {
      if (b.estimatedJuz !== a.estimatedJuz) return b.estimatedJuz - a.estimatedJuz;
      return b.averageScore - a.averageScore;
    });
  }, [santriList]);

  const filteredSetorans = useMemo(() => {
    if (!search.trim()) return setorans;
    const q = search.toLowerCase();
    return setorans.filter(s => {
      const santri = getSantri(s.santriId);
      return (
        s.surahEnglishName.toLowerCase().includes(q) ||
        (santri?.name.toLowerCase().includes(q) ?? false) ||
        (santri?.nis.toLowerCase().includes(q) ?? false)
      );
    });
  }, [setorans, search, santriList]);

  return (
    <>
      <PageMeta title="Monitoring Progres | TahfidzMU Admin" description="Pantau aktivitas setoran dan peringkat santri secara real-time." />

      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Monitoring Progres</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Pantau aktivitas setoran harian dan capaian hafalan santri.</p>
          </div>
          <div className="flex bg-gray-100 dark:bg-gray-800 p-1 rounded-xl">
            <button
              onClick={() => setActiveTab("riwayat")}
              className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition ${activeTab === "riwayat" ? "bg-white dark:bg-gray-700 text-brand-600 dark:text-brand-400 shadow-sm" : "text-gray-500 hover:text-gray-700"}`}
            >
              <History size={16} /> Riwayat
            </button>
            <button
              onClick={() => setActiveTab("peringkat")}
              className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition ${activeTab === "peringkat" ? "bg-white dark:bg-gray-700 text-brand-600 dark:text-brand-400 shadow-sm" : "text-gray-500 hover:text-gray-700"}`}
            >
              <TrendingUp size={16} /> Peringkat
            </button>
            <button
              onClick={() => setActiveTab("presensi")}
              className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition ${activeTab === "presensi" ? "bg-white dark:bg-gray-700 text-brand-600 dark:text-brand-400 shadow-sm" : "text-gray-500 hover:text-gray-700"}`}
            >
              <Users size={16} /> Presensi
            </button>
          </div>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Cari santri atau surah..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm"
          />
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[400px]">
            <div className="w-10 h-10 border-4 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : (
          <div className="grid gap-6">
            {activeTab === "riwayat" && (
              <div className="bg-white dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 rounded-2xl overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-gray-100 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.02] text-gray-500 dark:text-gray-400">
                        <th className="p-4">Santri</th>
                        <th className="p-4">Hafalan</th>
                        <th className="p-4">Tipe</th>
                        <th className="p-4">Skor</th>
                        <th className="p-4">Waktu</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                      {filteredSetorans.length === 0 ? (
                        <tr><td colSpan={5} className="p-12 text-center text-gray-500">Belum ada aktivitas setoran tercatat.</td></tr>
                      ) : (
                        filteredSetorans.map((s) => {
                          const santri = getSantri(s.santriId);
                          return (
                            <tr key={s.id} className="hover:bg-gray-50/50 dark:hover:bg-white/[0.01] transition-colors">
                              <td className="p-4">
                                <div className="flex items-center gap-3">
                                  <img src={santri?.photoPath || defaultAvatar} className="w-9 h-9 rounded-full object-cover border border-gray-100 dark:border-gray-700" alt="" />
                                  <div>
                                    <p className="font-bold text-gray-900 dark:text-white">{santri?.name || "Santri dihapus"}</p>
                                    <p className="text-xs text-gray-500">{santri?.nis || "-"}</p>
                                  </div>
                                </div>
                              </td>
                              <td className="p-4">
                                <p className="font-semibold text-gray-800 dark:text-gray-200">{s.surahEnglishName}</p>
                                <p className="text-xs text-gray-500">Ayat {s.ayahStart}-{s.ayahEnd}</p>
                              </td>
                              <td className="p-4">
                                <span className={`px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider ${s.type === 'ziyadah' ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10' : 'bg-blue-50 text-blue-600 dark:bg-blue-500/10'}`}>
                                  {s.type}
                                </span>
                              </td>
                              <td className="p-4">
                                <div className="flex items-center gap-1">
                                  <Star size={14} className="text-amber-500 fill-amber-500" />
                                  <span className="font-bold text-gray-900 dark:text-white">{s.finalScore.toFixed(0)}</span>
                                </div>
                              </td>
                              <td className="p-4 text-gray-500 text-xs">
                                {new Date(s.date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {activeTab === "peringkat" && (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                {rankedSantri.map((s, index) => (
                  <div key={s.id} className="bg-white dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 p-4 rounded-2xl flex items-center gap-4 relative overflow-hidden group">
                    <div className={`absolute top-0 left-0 w-8 h-8 flex items-center justify-center text-xs font-bold rounded-br-xl ${index === 0 ? 'bg-amber-500 text-white' : index === 1 ? 'bg-slate-400 text-white' : index === 2 ? 'bg-orange-600 text-white' : 'bg-gray-100 dark:bg-gray-800 text-gray-400'}`}>
                      #{index + 1}
                    </div>
                    <img src={s.photoPath || defaultAvatar} className="w-14 h-14 rounded-2xl object-cover shadow-sm" alt="" />
                    <div className="flex-1 min-w-0">
                      <h4 className="font-bold text-gray-900 dark:text-white truncate">{s.name}</h4>
                      <p className="text-xs text-gray-500 font-mono">{s.nis}</p>
                      <div className="mt-3 flex items-center justify-between">
                        <div className="flex flex-col">
                          <span className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Hafalan</span>
                          <span className="text-sm font-bold text-brand-600 dark:text-brand-400">{s.estimatedJuz.toFixed(1)} Juz</span>
                        </div>
                        <div className="flex flex-col items-end">
                          <span className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Rata-rata</span>
                          <div className="flex items-center gap-1">
                            <Star size={12} className="text-amber-500 fill-amber-500" />
                            <span className="text-sm font-bold">{s.averageScore.toFixed(0)}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                    {index < 3 && (
                      <div className="absolute -right-2 -bottom-2 opacity-5 group-hover:opacity-10 transition-opacity">
                         <TrendingUp size={60} />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {activeTab === "presensi" && (
              <div className="bg-white dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 rounded-2xl overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-gray-100 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.02] text-gray-500 dark:text-gray-400">
                        <th className="p-4">Tanggal</th>
                        <th className="p-4">Halaqah</th>
                        <th className="p-4">Hadir</th>
                        <th className="p-4">Izin/Sakit</th>
                        <th className="p-4">Alfa</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                      {presensiList.length === 0 ? (
                        <tr><td colSpan={5} className="p-12 text-center text-gray-500">Belum ada data presensi.</td></tr>
                      ) : (
                        presensiList.map((p) => {
                          const attendance = (p.attendance || {}) as Record<string, string>;
                          const stats = Object.values(attendance).reduce((acc, status) => {
                             acc[status] = (acc[status] || 0) + 1;
                             return acc;
                          }, {} as Record<string, number>);

                          return (
                            <tr key={p.id} className="hover:bg-gray-50/50 dark:hover:bg-white/[0.01]">
                              <td className="p-4 font-semibold">
                                {p.tanggal instanceof Timestamp ? p.tanggal.toDate().toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : String(p.tanggal)}
                              </td>
                              <td className="p-4">{p.halaqahName || "Semua"}</td>
                              <td className="p-4 text-emerald-600 font-bold">{stats['hadir'] || 0}</td>
                              <td className="p-4 text-amber-600 font-bold">{(stats['izin'] || 0) + (stats['sakit'] || 0)}</td>
                              <td className="p-4 text-red-600 font-bold">{stats['alfa'] || 0}</td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </>
  );
}
