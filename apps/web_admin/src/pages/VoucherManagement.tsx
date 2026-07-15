import { useEffect, useState } from "react";
import { collection, doc, getDocs, updateDoc, Timestamp } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Search, ShieldAlert, CheckCircle, Clock, Award, CreditCard, Calendar } from "lucide-react";

type VoucherTicket = {
  id: string;
  santriId: string;
  santriName: string;
  rewardId: string;
  rewardName: string;
  cost: number;
  purchaseDate: any;
  redeemedDate?: any;
  status: "pending" | "redeemed" | "expired";
};

export default function VoucherManagement() {
  const { profile } = useAuth();
  const [list, setList] = useState<VoucherTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<"pending" | "redeemed">("pending");
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.pesantrenId) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;
      const snap = await getDocs(collection(db, "pesantren", pid, "vouchers"));
      const items = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          santriId: data.santriId || "",
          santriName: data.santriName || "",
          rewardId: data.rewardId || "",
          rewardName: data.rewardName || "",
          cost: Number(data.cost || 0),
          purchaseDate: data.purchaseDate,
          redeemedDate: data.redeemedDate,
          status: data.status || "pending",
        } as VoucherTicket;
      });
      // Sort by purchaseDate descending
      items.sort((a, b) => {
        const timeA = a.purchaseDate?.seconds || 0;
        const timeB = b.purchaseDate?.seconds || 0;
        return timeB - timeA;
      });
      setList(items);
    } catch (err) {
      console.error("Gagal memuat voucher:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleRedeem = async (voucherId: string) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm("Konfirmasi pencairan voucher ini? Pastikan barang/hadiah fisik telah diserahkan kepada santri.")) return;

    setProcessingId(voucherId);
    try {
      const pid = profile.pesantrenId;
      await updateDoc(doc(db, "pesantren", pid, "vouchers", voucherId), {
        status: "redeemed",
        redeemedDate: Timestamp.now(),
      });
      // reload
      await load();
    } catch (err: any) {
      console.error(err);
      alert("Gagal mencairkan voucher: " + err.message);
    } finally {
      setProcessingId(null);
    }
  };

  const canManage = profile?.role === "admin" || profile?.role === "superAdmin" || profile?.isKoordinator;

  if (!canManage) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Halaman ini hanya untuk Administrator atau Koordinator.</p>
      </div>
    );
  }

  const filtered = list.filter((v) => {
    const matchesSearch =
      v.santriName.toLowerCase().includes(search.toLowerCase()) ||
      v.rewardName.toLowerCase().includes(search.toLowerCase());
    const matchesTab = v.status === activeTab;
    return matchesSearch && matchesTab;
  });

  const countPending = list.filter((v) => v.status === "pending").length;
  const countRedeemed = list.filter((v) => v.status === "redeemed").length;

  const formatDate = (ts: any) => {
    if (!ts) return "-";
    const date = ts.toDate ? ts.toDate() : new Date(ts);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <>
      <PageMeta title="Pusat Voucher | TahfidzMU Admin" description="Manajemen penukaran voucher koin santri." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Pusat Penukaran Voucher</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Verifikasi dan cairkan tiket hadiah fisik santri dari Toko Reward.
            </p>
          </div>
        </div>

        {/* Tab Filters */}
        <div className="flex border-b border-gray-200 dark:border-gray-850">
          <button
            onClick={() => setActiveTab("pending")}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-semibold border-b-2 transition-all ${
              activeTab === "pending"
                ? "border-brand-500 text-brand-500 dark:text-brand-400"
                : "border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            }`}
          >
            <Clock size={16} />
            Menunggu Pencairan
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-orange-100 text-orange-600 dark:bg-orange-950 dark:text-orange-400">
              {countPending}
            </span>
          </button>
          <button
            onClick={() => setActiveTab("redeemed")}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-semibold border-b-2 transition-all ${
              activeTab === "redeemed"
                ? "border-brand-500 text-brand-500 dark:text-brand-400"
                : "border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            }`}
          >
            <CheckCircle size={16} />
            Sudah Dicairkan
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400">
              {countRedeemed}
            </span>
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama santri atau nama hadiah..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm"
          />
        </div>

        {/* Table & List View */}
        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]">
            <div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500">
            <CreditCard size={36} className="mx-auto mb-3 text-gray-300 dark:text-gray-700" />
            <p className="text-sm font-medium">Tidak ada voucher dalam kategori ini.</p>
            {search && <p className="text-xs text-gray-400 mt-1">Coba kata kunci pencarian yang lain.</p>}
          </div>
        ) : (
          <div className="overflow-hidden bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Santri</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Hadiah / Voucher</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Biaya Koin</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Tanggal Pembelian</th>
                    {activeTab === "redeemed" && (
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Tanggal Dicairkan</th>
                    )}
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                  {filtered.map((v) => (
                    <tr key={v.id} className="hover:bg-gray-50/30 dark:hover:bg-gray-800/20 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-gray-950 dark:text-white">{v.santriName}</div>
                        <div className="text-xs text-gray-400">ID: {v.santriId}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <Award size={16} className="text-brand-500" />
                          <span className="font-medium text-gray-800 dark:text-gray-300">{v.rewardName}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-900 dark:bg-amber-950/40 dark:text-amber-400">
                          🪙 {v.cost} Koin
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar size={14} className="text-gray-400" />
                          {formatDate(v.purchaseDate)}
                        </div>
                      </td>
                      {activeTab === "redeemed" && (
                        <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                          <div className="flex items-center gap-1.5">
                            <CheckCircle size={14} className="text-emerald-500" />
                            {formatDate(v.redeemedDate)}
                          </div>
                        </td>
                      )}
                      <td className="px-6 py-4 text-right">
                        {v.status === "pending" ? (
                          <button
                            onClick={() => handleRedeem(v.id)}
                            disabled={processingId === v.id}
                            className="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 disabled:bg-emerald-800/50 rounded-xl transition shadow-sm"
                          >
                            {processingId === v.id ? "Memproses..." : "Cairkan Hadiah"}
                          </button>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 dark:text-emerald-450 bg-emerald-100/50 dark:bg-emerald-950/30 px-3 py-1 rounded-full">
                            <CheckCircle size={12} /> Dicairkan
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
