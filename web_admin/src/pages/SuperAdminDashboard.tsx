import { useEffect, useState } from "react";
import { collection, doc, getDocs, getDoc, setDoc, updateDoc, Timestamp } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Landmark, Users, Building2, TrendingUp, Save, ShieldAlert, Award, Clock, ArrowRight } from "lucide-react";
import { useNavigate } from "react-router";

type PesantrenRow = {
  id: string;
  nama: string;
  subscriptionTier: string;
  activeUntil: any;
  status: string;
  pricePerSantri: number;
  pricePerMusyrif: number;
  discountAmount: number;
  santriCount: number;
  musyrifCount: number;
  monthlyRevenue: number;
};

export default function SuperAdminDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [list, setList] = useState<PesantrenRow[]>([]);
  const [loading, setLoading] = useState(true);

  // Global pricing configuration
  const [priceSantriStandar, setPriceSantriStandar] = useState(5000);
  const [priceMusyrifStandar, setPriceMusyrifStandar] = useState(0);
  const [priceSantriProfesional, setPriceSantriProfesional] = useState(10000);
  const [priceMusyrifProfesional, setPriceMusyrifProfesional] = useState(0);
  const [pricingSaving, setPricingSaving] = useState(false);
  const [pricingSuccess, setPricingSuccess] = useState(false);
  const [applyToExisting, setApplyToExisting] = useState(false);

  useEffect(() => {
    if (profile?.role === "superAdmin") {
      loadDashboardData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // 1. Get global pricing settings
      const globalSnap = await getDoc(doc(db, "settings", "global_pricing"));
      if (globalSnap.exists()) {
        const gData = globalSnap.data();
        setPriceSantriStandar(typeof gData.pricePerSantriStandar === "number" ? gData.pricePerSantriStandar : (typeof gData.pricePerSantri === "number" ? gData.pricePerSantri : 5000));
        setPriceMusyrifStandar(typeof gData.priceMusyrifStandar === "number" ? gData.priceMusyrifStandar : (typeof gData.pricePerMusyrif === "number" ? gData.pricePerMusyrif : 0));
        setPriceSantriProfesional(typeof gData.pricePerSantriProfesional === "number" ? gData.pricePerSantriProfesional : 10000);
        setPriceMusyrifProfesional(typeof gData.pricePerMusyrifProfesional === "number" ? gData.pricePerMusyrifProfesional : 0);
      }

      // 2. Load all Pesantren documents
      const pesSnap = await getDocs(collection(db, "pesantren"));
      
      // Load user stats asynchronously for each pesantren
      const rows: PesantrenRow[] = await Promise.all(
        pesSnap.docs.map(async (d) => {
          const data = d.data();
          
          // Get santri and musyrif counts
          const [santriSnap, musyrifSnap] = await Promise.all([
            getDocs(collection(db, "pesantren", d.id, "santri")),
            getDocs(collection(db, "pesantren", d.id, "musyrif")),
          ]);

          const sCount = santriSnap.docs.length;
          const mCount = musyrifSnap.docs.length;

          const pPerSantri = typeof data.pricePerSantri === "number" ? data.pricePerSantri : 5000;
          const pPerMusyrif = typeof data.pricePerMusyrif === "number" ? data.pricePerMusyrif : 0;
          const disc = typeof data.discountAmount === "number" ? data.discountAmount : 0;

          // Calculate monthly revenue
          const monthlyRevenue = Math.max(0, (sCount * pPerSantri) + (mCount * pPerMusyrif) - disc);

          return {
            id: d.id,
            nama: data.nama || "Pesantren",
            subscriptionTier: data.subscriptionTier || "Standar",
            activeUntil: data.activeUntil,
            status: data.status || "active",
            pricePerSantri: pPerSantri,
            pricePerMusyrif: pPerMusyrif,
            discountAmount: disc,
            santriCount: sCount,
            musyrifCount: mCount,
            monthlyRevenue,
          };
        })
      );

      setList(rows);
    } catch (err) {
      console.error("Gagal memuat dashboard:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveGlobalPricing = async (e: React.FormEvent) => {
    e.preventDefault();
    setPricingSaving(true);
    setPricingSuccess(false);

    try {
      await setDoc(doc(db, "settings", "global_pricing"), {
        pricePerSantriStandar: priceSantriStandar,
        priceMusyrifStandar: priceMusyrifStandar,
        pricePerSantriProfesional: priceSantriProfesional,
        pricePerMusyrifProfesional: priceMusyrifProfesional,
        // Backward-compatibility
        pricePerSantri: priceSantriStandar,
        pricePerMusyrif: priceMusyrifStandar,
        updatedAt: Timestamp.now(),
      });

      if (applyToExisting) {
        const updatePromises = list.map(async (pesantren) => {
          const isProf = pesantren.subscriptionTier === "Profesional";
          const newPriceSantri = isProf ? priceSantriProfesional : priceSantriStandar;
          const newPriceMusyrif = isProf ? priceMusyrifProfesional : priceMusyrifStandar;
          
          await updateDoc(doc(db, "pesantren", pesantren.id), {
            pricePerSantri: newPriceSantri,
            pricePerMusyrif: newPriceMusyrif,
          });
        });
        await Promise.all(updatePromises);
        await loadDashboardData();
      }

      setPricingSuccess(true);
      setTimeout(() => setPricingSuccess(false), 3000);
    } catch (err: any) {
      console.error(err);
      alert("Gagal menyimpan harga global: " + err.message);
    } finally {
      setPricingSaving(false);
    }
  };

  // Calculations for stats
  const totalPesantren = list.length;
  const totalSantri = list.reduce((sum, p) => sum + p.santriCount, 0);
  const totalMusyrif = list.reduce((sum, p) => sum + p.musyrifCount, 0);
  const estimatedMRR = list.reduce((sum, p) => sum + p.monthlyRevenue, 0);

  const getDaysLeft = (activeUntil: any) => {
    if (!activeUntil) return 0;
    const date = activeUntil.toDate ? activeUntil.toDate() : new Date(activeUntil);
    const diff = date.getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
  };

  const formatDate = (ts: any) => {
    if (!ts) return "-";
    const date = ts.toDate ? ts.toDate() : new Date(ts);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  };

  const isSuperAdmin = profile?.role === "superAdmin";

  if (!isSuperAdmin) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Dashboard Super Admin hanya dapat diakses oleh administrator utama.</p>
      </div>
    );
  }

  return (
    <>
      <PageMeta title="Super Admin Dashboard | TahfidzMU" description="Ringkasan eksekutif dan monitoring pendapatan SaaS." />
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Super Admin Dashboard</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Pantau pertumbuhan pesantren, estimasi omset platform (MRR), dan sesuaikan harga default sistem secara real-time.
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-brand-600 dark:text-brand-400 uppercase tracking-wider flex items-center gap-1">
              <TrendingUp size={12} /> POTENSI PENDAPATAN (MRR)
            </div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">Rp {estimatedMRR.toLocaleString("id-ID")}</div>
            <div className="text-xs text-gray-450">Akumulasi biaya bulanan saat ini</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wider flex items-center gap-1">
              <Building2 size={12} /> PESANTREN AKTIF
            </div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">{totalPesantren} Mitra</div>
            <div className="text-xs text-gray-450">Pesantren menggunakan platform</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wider flex items-center gap-1">
              <Users size={12} /> TOTAL SANTRI
            </div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">{totalSantri} Santri</div>
            <div className="text-xs text-gray-450">Terdaftar di seluruh pesantren</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wider flex items-center gap-1">
              <Award size={12} /> TOTAL MUSYRIF
            </div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">{totalMusyrif} Guru</div>
            <div className="text-xs text-gray-450">Musyrif pembimbing halaqah</div>
          </div>
        </div>

        {/* Global Pricing Config Section */}
        <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-6 shadow-sm">
          <div className="mb-4">
            <h3 className="text-md font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <Landmark size={18} className="text-brand-500" />
              Pengaturan Harga Dasar Global Platform
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-450 mt-1">
              Atur tarif sewa dasar standar sistem. Tarif baru ini otomatis terisi saat mendaftarkan pesantren baru, namun Anda tetap bisa melakukan override/merubahnya khusus per-pesantren di panel Kelola Pesantren.
            </p>
          </div>

          {pricingSuccess && (
            <div className="p-3 mb-4 text-xs font-medium text-emerald-800 bg-emerald-50 border border-emerald-100 rounded-xl dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20">
              ✓ Harga dasar global berhasil diperbarui di server cloud.
            </div>
          )}

          <form onSubmit={handleSaveGlobalPricing} className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              {/* Standar Section */}
              <div className="space-y-3 bg-gray-50/50 dark:bg-white/[0.02] p-4 rounded-2xl border border-gray-150 dark:border-gray-800">
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider">📦 Tarif Paket Standar</h4>
                <div className="grid gap-3 sm:grid-cols-2">
                  <div>
                    <label className="block mb-1.5 text-[10px] font-bold text-gray-500 uppercase tracking-wider">Biaya Per Santri (Rp/Bln)</label>
                    <input
                      type="number"
                      required
                      value={priceSantriStandar}
                      onChange={(e) => setPriceSantriStandar(Number(e.target.value))}
                      className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block mb-1.5 text-[10px] font-bold text-gray-500 uppercase tracking-wider">Biaya Per Musyrif (Rp/Bln)</label>
                    <input
                      type="number"
                      required
                      value={priceMusyrifStandar}
                      onChange={(e) => setPriceMusyrifStandar(Number(e.target.value))}
                      className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                </div>
              </div>

              {/* Profesional Section */}
              <div className="space-y-3 bg-brand-50/20 dark:bg-brand-500/5 p-4 rounded-2xl border border-brand-100 dark:border-brand-500/20">
                <h4 className="text-xs font-bold text-brand-700 dark:text-brand-400 uppercase tracking-wider">💎 Tarif Paket Profesional</h4>
                <div className="grid gap-3 sm:grid-cols-2">
                  <div>
                    <label className="block mb-1.5 text-[10px] font-bold text-gray-500 uppercase tracking-wider">Biaya Per Santri (Rp/Bln)</label>
                    <input
                      type="number"
                      required
                      value={priceSantriProfesional}
                      onChange={(e) => setPriceSantriProfesional(Number(e.target.value))}
                      className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block mb-1.5 text-[10px] font-bold text-gray-500 uppercase tracking-wider">Biaya Per Musyrif (Rp/Bln)</label>
                    <input
                      type="number"
                      required
                      value={priceMusyrifProfesional}
                      onChange={(e) => setPriceMusyrifProfesional(Number(e.target.value))}
                      className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
              <label className="flex items-center gap-2 text-xs text-gray-650 dark:text-gray-400 font-medium cursor-pointer">
                <input
                  type="checkbox"
                  checked={applyToExisting}
                  onChange={(e) => setApplyToExisting(e.target.checked)}
                  className="rounded text-brand-500 focus:ring-brand-500/20 dark:bg-gray-800 dark:border-gray-700 w-4 h-4"
                />
                <span>Terapkan juga tarif baru ini ke seluruh pesantren mitra yang sudah terdaftar saat ini</span>
              </label>

              <button
                type="submit"
                disabled={pricingSaving}
                className="flex items-center justify-center gap-2 px-5 py-2.5 text-xs font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition disabled:opacity-50 shadow-sm shadow-brand-500/20"
              >
                <Save size={14} /> {pricingSaving ? "Menyimpan..." : "Simpan Penyesuaian Tarif Global"}
              </button>
            </div>
          </form>
        </div>

        {/* Pricing List Table */}
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <h3 className="text-md font-bold text-gray-900 dark:text-white">Daftar Biaya Langganan Pesantren Mitra</h3>
            <button
              onClick={() => navigate("/pesantren")}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-650 hover:text-brand-700 dark:text-brand-400"
            >
              Kelola Pesantren <ArrowRight size={14} />
            </button>
          </div>

          {loading ? (
            <div className="flex items-center justify-center min-h-[150px]">
              <div className="w-6 h-6 border-2 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : list.length === 0 ? (
            <div className="p-10 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500">
              <ShieldAlert size={28} className="mx-auto mb-2 text-gray-300 dark:text-gray-700" />
              <p className="text-xs">Belum ada pesantren terdaftar.</p>
            </div>
          ) : (
            <div className="overflow-hidden bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 shadow-sm">
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Nama Pesantren</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Paket Sewa</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Santri / Musyrif</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Tarif Pengguna</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Potongan Diskon</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Biaya Bulanan (Est)</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Masa Sewa</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 dark:divide-gray-800 text-sm">
                    {list.map((p) => {
                      const daysLeft = getDaysLeft(p.activeUntil);
                      return (
                        <tr key={p.id} className="hover:bg-gray-50/30 dark:hover:bg-gray-800/10 transition-colors">
                          <td className="px-6 py-4 font-bold text-gray-950 dark:text-white">
                            {p.nama}
                            <div className="text-[10px] text-gray-400 font-normal">NPSN / ID: {p.id}</div>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold ${
                              p.subscriptionTier === "Profesional"
                                ? "bg-purple-100 text-purple-800 dark:bg-purple-950/40 dark:text-purple-400"
                                : "bg-blue-100 text-blue-800 dark:bg-blue-950/40 dark:text-blue-400"
                            }`}>
                              {p.subscriptionTier}
                            </span>
                          </td>
                          <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white">
                            {p.santriCount} S / {p.musyrifCount} M
                          </td>
                          <td className="px-6 py-4 text-xs text-gray-600 dark:text-gray-400">
                            <div>Santri: Rp {p.pricePerSantri.toLocaleString("id-ID")}</div>
                            <div>Musyrif: Rp {p.pricePerMusyrif.toLocaleString("id-ID")}</div>
                          </td>
                          <td className="px-6 py-4 font-medium text-red-650 dark:text-red-400">
                            Rp {p.discountAmount.toLocaleString("id-ID")}
                          </td>
                          <td className="px-6 py-4 font-bold text-brand-650 dark:text-brand-400 text-md">
                            Rp {p.monthlyRevenue.toLocaleString("id-ID")}
                          </td>
                          <td className="px-6 py-4">
                            <div className="text-gray-800 dark:text-gray-300 font-medium">{formatDate(p.activeUntil)}</div>
                            <div className="flex items-center gap-1 text-[10px] text-gray-400">
                              <Clock size={10} />
                              {daysLeft > 0 ? `${daysLeft} hari lagi` : "Kedaluwarsa"}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-right">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                              p.status === "active"
                                ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-450"
                                : "bg-gray-100 text-gray-850 dark:bg-gray-800 dark:text-gray-450"
                            }`}>
                              {p.status === "active" ? "Aktif" : "Suspend"}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
