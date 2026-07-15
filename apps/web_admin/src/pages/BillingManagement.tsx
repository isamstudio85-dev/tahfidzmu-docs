import { useEffect, useState } from "react";
import { collection, doc, getDocs, updateDoc, getDoc, setDoc, Timestamp } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Search, ShieldAlert, CreditCard, Clock, CheckCircle, Landmark, Upload, X, Calendar, AlertCircle } from "lucide-react";

type InvoiceItem = {
  id: string;
  amount: number;
  subscriptionTier: string;
  status: "unpaid" | "paid" | "expired";
  dueDate: any;
  paidDate?: any;
  createdDate: any;
  paymentMethod?: string;
  paymentProofUrl?: string;
};

type PesantrenInfo = {
  nama: string;
  subscriptionTier: string;
  activeUntil: any;
  status: string;
  pricePerSantri: number;
  pricePerMusyrif: number;
  discountAmount: number;
  santriCount: number;
  musyrifCount: number;
};

export default function BillingManagement() {
  const { profile } = useAuth();
  const [invoices, setInvoices] = useState<InvoiceItem[]>([]);
  const [pesantren, setPesantren] = useState<PesantrenInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<"unpaid" | "paid">("unpaid");

  // Upload proof states
  const [selectedInv, setSelectedInv] = useState<InvoiceItem | null>(null);
  const [proofFile, setProofFile] = useState<File | null>(null);
  const [proofPreview, setProofPreview] = useState<string | null>(null);
  const [bankName, setBankName] = useState("Transfer Bank Mandiri");
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  // Subscription upgrade states
  const [isUpgradeOpen, setIsUpgradeOpen] = useState(false);
  const [newTierSelection, setNewTierSelection] = useState("Profesional (Bulanan)");
  const [upgradeSaving, setUpgradeSaving] = useState(false);

  const handleRequestUpgrade = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.pesantrenId) return;

    setUpgradeSaving(true);
    try {
      const pid = profile.pesantrenId;
      const invId = `INV-UPG-${Date.now().toString().substring(5)}`;

      const sCount = pesantren?.santriCount ?? 0;
      const mCount = pesantren?.musyrifCount ?? 0;
      const pPerSantri = pesantren?.pricePerSantri ?? 5000;
      const pPerMusyrif = pesantren?.pricePerMusyrif ?? 0;
      const disc = pesantren?.discountAmount ?? 0;

      const monthlyBase = (sCount * pPerSantri) + (mCount * pPerMusyrif) - disc;
      let newAmount = Math.max(0, monthlyBase);

      if (newTierSelection.includes("Tahunan")) {
        newAmount = Math.max(0, monthlyBase * 10); // Bayar 10 bulan untuk 12 bulan sewa (Hemat 2 bulan)
      }

      const invRef = doc(db, "pesantren", pid, "invoices", invId);
      await setDoc(invRef, {
        id: invId,
        pesantrenId: pid,
        amount: newAmount,
        subscriptionTier: newTierSelection,
        status: "unpaid",
        dueDate: Timestamp.fromDate(new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)), // 3 days
        createdDate: Timestamp.now(),
      });

      setIsUpgradeOpen(false);
      alert(`Pengajuan pindah paket ke "${newTierSelection}" berhasil dikirim.\n\nTagihan invoice baru (${invId}) senilai Rp ${newAmount.toLocaleString("id-ID")} telah diterbitkan.\nSilakan lakukan pembayaran ke rekening resmi dan unggah bukti transfer agar paket diaktifkan.`);
      await loadData();
    } catch (err: any) {
      console.error(err);
      alert("Gagal mengajukan upgrade: " + err.message);
    } finally {
      setUpgradeSaving(false);
    }
  };

  useEffect(() => {
    if (profile?.pesantrenId) {
      loadData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const loadData = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;

      // 1. Get Pesantren Root Info for Subscription Details
      const [pesSnap, santriSnap, musyrifSnap] = await Promise.all([
        getDoc(doc(db, "pesantren", pid)),
        getDocs(collection(db, "pesantren", pid, "santri")),
        getDocs(collection(db, "pesantren", pid, "musyrif")),
      ]);

      if (pesSnap.exists()) {
        const data = pesSnap.data();
        setPesantren({
          nama: data.nama || "Pesantren",
          subscriptionTier: data.subscriptionTier || "Standar",
          activeUntil: data.activeUntil,
          status: data.status || "active",
          pricePerSantri: typeof data.pricePerSantri === "number" ? data.pricePerSantri : 5000,
          pricePerMusyrif: typeof data.pricePerMusyrif === "number" ? data.pricePerMusyrif : 0,
          discountAmount: typeof data.discountAmount === "number" ? data.discountAmount : 0,
          santriCount: santriSnap.docs.length,
          musyrifCount: musyrifSnap.docs.length,
        });
      }

      // 2. Get Invoices for this Pesantren
      const invSnap = await getDocs(collection(db, "pesantren", pid, "invoices"));
      const items = invSnap.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          amount: Number(data.amount || 0),
          subscriptionTier: data.subscriptionTier || "Standar",
          status: data.status || "unpaid",
          dueDate: data.dueDate,
          paidDate: data.paidDate,
          createdDate: data.createdDate || Timestamp.now(),
          paymentMethod: data.paymentMethod,
          paymentProofUrl: data.paymentProofUrl,
        } as InvoiceItem;
      });

      // Sort by createdDate descending
      items.sort((a, b) => {
        const tA = a.createdDate?.seconds || 0;
        const tB = b.createdDate?.seconds || 0;
        return tB - tA;
      });

      setInvoices(items);
    } catch (err) {
      console.error("Gagal memuat billing:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        setUploadError("Ukuran file maksimal 2MB");
        return;
      }
      setProofFile(file);
      setProofPreview(URL.createObjectURL(file));
      setUploadError(null);
    }
  };

  const handleUploadProof = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedInv || !proofFile || !profile?.pesantrenId) return;

    setUploading(true);
    setUploadError(null);
    try {
      const pid = profile.pesantrenId;
      const proofRef = ref(storage, `invoice_proofs/${selectedInv.id}.jpg`);

      // 1. Upload proof file to Firebase Storage
      const snapshot = await uploadBytes(proofRef, proofFile);
      const proofUrl = await getDownloadURL(snapshot.ref);

      // 2. Update invoice document field in Firestore
      await updateDoc(doc(db, "pesantren", pid, "invoices", selectedInv.id), {
        paymentProofUrl: proofUrl,
        paymentMethod: bankName,
      });

      setSelectedInv(null);
      setProofFile(null);
      setProofPreview(null);
      alert("Bukti pembayaran berhasil diunggah. Menunggu konfirmasi Super Admin.");
      await loadData();
    } catch (err: any) {
      console.error(err);
      setUploadError("Gagal mengunggah bukti: " + err.message);
    } finally {
      setUploading(false);
    }
  };

  const canView = profile?.role === "admin" || profile?.role === "superAdmin" || profile?.isKoordinator;

  if (!canView) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Halaman ini hanya untuk Administrator Pesantren.</p>
      </div>
    );
  }

  const filtered = invoices.filter((inv) => {
    const matchesSearch = inv.id.toLowerCase().includes(search.toLowerCase());
    const matchesTab = inv.status === activeTab;
    return matchesSearch && matchesTab;
  });

  const countUnpaid = invoices.filter((inv) => inv.status === "unpaid").length;
  const countPaid = invoices.filter((inv) => inv.status === "paid").length;

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

  const daysLeft = getDaysLeft(pesantren?.activeUntil);

  return (
    <>
      <PageMeta title="Tagihan Saya | TahfidzMU Admin" description="Detail langganan dan tagihan sewa platform." />
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Tagihan & Langganan Sewa</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Lihat detail paket lisensi sewa pesantren Anda dan konfirmasikan pembayaran.
          </p>
        </div>

        {/* Subscription Info Card */}
        {pesantren && (
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-6 shadow-sm grid gap-6 md:grid-cols-3 items-center">
            <div className="space-y-2">
              <div className="text-[11px] uppercase tracking-wider text-gray-400 font-bold">Paket Sewa Aktif</div>
              <h3 className="text-2xl font-black text-brand-500 dark:text-brand-450">{pesantren.subscriptionTier}</h3>
              <button
                onClick={() => {
                  setNewTierSelection(pesantren.subscriptionTier === "Profesional" ? "Standar (Bulanan)" : "Profesional (Bulanan)");
                  setIsUpgradeOpen(true);
                }}
                className="mt-1 inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-brand-600 bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/10 dark:text-brand-400 rounded-lg border border-brand-200 dark:border-brand-500/30 transition"
              >
                Ubah / Pindah Paket
              </button>
            </div>
            <div className="space-y-1">
              <div className="text-[11px] uppercase tracking-wider text-gray-400 font-bold">Masa Berlaku Sewa</div>
              <h3 className="text-lg font-bold text-gray-950 dark:text-white flex items-center gap-1.5">
                <Calendar size={18} className="text-gray-400" />
                {formatDate(pesantren.activeUntil)}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">Pemberitahuan tagihan dikirim 7 hari sebelum berakhir</p>
            </div>
            <div className="space-y-2">
              <div className="text-[11px] uppercase tracking-wider text-gray-400 font-bold">Sisa Waktu Sewa</div>
              {daysLeft > 0 ? (
                <div className="inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-400">
                  ⚡ {daysLeft} Hari Lagi
                </div>
              ) : (
                <div className="inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-red-100 text-red-800 dark:bg-red-950/40 dark:text-red-400 animate-pulse">
                  🚨 Sewa Kedaluwarsa
                </div>
              )}
            </div>
          </div>
        )}
        {/* Rincian Tarif Sewa Aktif */}
        {pesantren && (
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-3 animate-fade-in-up">
            <h4 className="text-xs font-bold text-gray-800 dark:text-gray-200 uppercase tracking-wider">📋 Rincian & Tarif Sewa Pesantren Anda</h4>
            <div className="grid gap-4 sm:grid-cols-4 text-xs">
              <div className="bg-gray-50 dark:bg-white/[0.02] p-3.5 rounded-xl border border-gray-150 dark:border-gray-850 space-y-1">
                <div className="text-gray-400 font-bold uppercase tracking-wider text-[9px]">Jumlah Santri Aktif</div>
                <div className="text-lg font-black text-gray-900 dark:text-white">{pesantren.santriCount} anak</div>
                <div className="text-[10px] text-gray-500">Tarif: Rp {pesantren.pricePerSantri.toLocaleString("id-ID")}/santri</div>
              </div>
              <div className="bg-gray-50 dark:bg-white/[0.02] p-3.5 rounded-xl border border-gray-150 dark:border-gray-850 space-y-1">
                <div className="text-gray-400 font-bold uppercase tracking-wider text-[9px]">Jumlah Guru / Musyrif</div>
                <div className="text-lg font-black text-gray-900 dark:text-white">{pesantren.musyrifCount} orang</div>
                <div className="text-[10px] text-gray-500">Tarif: {pesantren.pricePerMusyrif > 0 ? `Rp ${pesantren.pricePerMusyrif.toLocaleString("id-ID")}/guru` : "Gratis"}</div>
              </div>
              <div className="bg-gray-50 dark:bg-white/[0.02] p-3.5 rounded-xl border border-gray-150 dark:border-gray-850 space-y-1">
                <div className="text-gray-400 font-bold uppercase tracking-wider text-[9px]">Potongan Diskon Khusus</div>
                <div className="text-lg font-black text-emerald-600 dark:text-emerald-450">- Rp {pesantren.discountAmount.toLocaleString("id-ID")}</div>
                <div className="text-[10px] text-gray-500">Diskon khusus pesantren mitra</div>
              </div>
              <div className="bg-brand-50/20 dark:bg-brand-500/5 p-3.5 rounded-xl border border-brand-100/50 dark:border-brand-500/20 space-y-1">
                <div className="text-brand-600 dark:text-brand-400 font-bold uppercase tracking-wider text-[9px]">Estimasi Biaya / Bulan</div>
                <div className="text-lg font-black text-brand-650 dark:text-brand-400">
                  Rp {Math.max(0, (pesantren.santriCount * pesantren.pricePerSantri) + (pesantren.musyrifCount * pesantren.pricePerMusyrif) - pesantren.discountAmount).toLocaleString("id-ID")}
                </div>
                <div className="text-[10px] text-gray-500">Dihitung otomatis per-pengguna</div>
              </div>
            </div>
          </div>
        )}

        {/* Bank Account Info */}
        <div className="rounded-2xl border border-sky-100 bg-sky-50 dark:border-sky-500/20 dark:bg-sky-500/10 p-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex gap-3 items-start">
            <Landmark size={24} className="text-sky-600 dark:text-sky-400 mt-0.5" />
            <div>
              <h4 className="font-bold text-sky-950 dark:text-sky-200 text-sm">Informasi Rekening Pembayaran</h4>
              <p className="text-xs text-sky-850 dark:text-sky-350/90 mt-0.5 leading-relaxed">
                Silakan lakukan transfer sesuai nominal tagihan ke rekening platform resmi:<br />
                <strong>Bank Syariah Indonesia (BSI) - 1234567890 a.n. PT TahfidzMU Cloud Indonesia</strong>
              </p>
            </div>
          </div>
        </div>

        {/* Tab Filters */}
        <div className="flex border-b border-gray-200 dark:border-gray-850">
          <button
            onClick={() => setActiveTab("unpaid")}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-semibold border-b-2 transition-all ${
              activeTab === "unpaid"
                ? "border-brand-500 text-brand-500 dark:text-brand-400"
                : "border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            }`}
          >
            <Clock size={16} />
            Menunggu Pembayaran
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-orange-100 text-orange-600 dark:bg-orange-950 dark:text-orange-400">
              {countUnpaid}
            </span>
          </button>
          <button
            onClick={() => setActiveTab("paid")}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-semibold border-b-2 transition-all ${
              activeTab === "paid"
                ? "border-brand-500 text-brand-500 dark:text-brand-400"
                : "border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            }`}
          >
            <CheckCircle size={16} />
            Riwayat Tagihan Lunas
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400">
              {countPaid}
            </span>
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Cari berdasarkan ID tagihan (INV)..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm"
          />
        </div>

        {/* Invoice Table */}
        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]">
            <div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500">
            <CreditCard size={36} className="mx-auto mb-3 text-gray-300 dark:text-gray-700" />
            <p className="text-sm font-medium">Tidak ada tagihan dalam kategori ini.</p>
          </div>
        ) : (
          <div className="overflow-hidden bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">No. Tagihan</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Tipe Layanan</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Jumlah Tagihan</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Jatuh Tempo</th>
                    {activeTab === "paid" ? (
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Metode & Tgl Lunas</th>
                    ) : (
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Status Bukti</th>
                    )}
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                  {filtered.map((inv) => (
                    <tr key={inv.id} className="hover:bg-gray-55/30 dark:hover:bg-gray-850/20 transition-colors">
                      <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white">{inv.id}</td>
                      <td className="px-6 py-4 text-sm text-gray-700 dark:text-gray-300">
                        {inv.subscriptionTier}
                        <div className="text-[10px] text-gray-400">Tanggal: {formatDate(inv.createdDate)}</div>
                      </td>
                      <td className="px-6 py-4 font-bold text-gray-900 dark:text-white">
                        Rp {inv.amount.toLocaleString("id-ID")}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar size={14} className="text-gray-400" />
                          {formatDate(inv.dueDate)}
                        </div>
                      </td>
                      {activeTab === "paid" ? (
                        <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                          <div className="font-semibold text-emerald-600 dark:text-emerald-450">{inv.paymentMethod || "Transfer Bank"}</div>
                          <div className="text-[10px] text-gray-400">Lunas: {formatDate(inv.paidDate)}</div>
                        </td>
                      ) : (
                        <td className="px-6 py-4 text-sm">
                          {inv.paymentProofUrl ? (
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-orange-600 dark:text-orange-450 bg-orange-100/50 dark:bg-orange-950/20 px-2.5 py-1 rounded-full">
                              Menunggu Verifikasi
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-gray-500 bg-gray-100 dark:bg-gray-800 px-2.5 py-1 rounded-full">
                              Belum Dikirim
                            </span>
                          )}
                        </td>
                      )}
                      <td className="px-6 py-4 text-right">
                        {inv.status === "unpaid" ? (
                          <button
                            onClick={() => {
                              setSelectedInv(inv);
                              setUploadError(null);
                            }}
                            className="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-xl transition shadow-sm"
                          >
                            <Upload size={12} /> {inv.paymentProofUrl ? "Ganti Bukti" : "Kirim Bukti Bayar"}
                          </button>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 dark:text-emerald-450 bg-emerald-100/50 dark:bg-emerald-950/30 px-3 py-1 rounded-full">
                            <CheckCircle size={12} /> Lunas
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

        {/* Upload Proof Dialog */}
        {selectedInv && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 backdrop-blur-sm p-4">
            <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-3xl w-full max-w-md p-6 shadow-2xl space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 dark:text-white">Kirim Bukti Pembayaran</h3>
                  <p className="text-xs text-gray-400 mt-1">Tagihan {selectedInv.id} senilai Rp {selectedInv.amount.toLocaleString("id-ID")}</p>
                </div>
                <button
                  onClick={() => {
                    setSelectedInv(null);
                    setProofFile(null);
                    setProofPreview(null);
                  }}
                  className="p-1 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <X size={18} />
                </button>
              </div>

              {uploadError && (
                <div className="flex items-start gap-2.5 p-3 text-xs font-medium text-red-700 bg-red-50 border border-red-100 rounded-xl dark:bg-red-500/10 dark:text-red-400 dark:border-red-500/20">
                  <AlertCircle size={14} className="mt-0.5" />
                  <span>{uploadError}</span>
                </div>
              )}

              <form onSubmit={handleUploadProof} className="space-y-4">
                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Rekening Bank Pengirim Anda</label>
                  <select
                    value={bankName}
                    onChange={(e) => setBankName(e.target.value)}
                    className="w-full rounded-2xl border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    <option value="Transfer Bank Mandiri">Transfer Bank Mandiri</option>
                    <option value="Transfer Bank BNI">Transfer Bank BNI</option>
                    <option value="Transfer Bank BRI">Transfer Bank BRI</option>
                    <option value="Transfer Bank BCA">Transfer Bank BCA</option>
                    <option value="Transfer Bank BSI">Transfer Bank BSI</option>
                  </select>
                </div>

                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Foto Bukti Transfer (Max 2MB)</label>
                  <div className="flex flex-col gap-3 items-center">
                    {proofPreview ? (
                      <img src={proofPreview} alt="Preview Bukti" className="h-44 w-full rounded-2xl border object-cover border-gray-200 dark:border-gray-700" />
                    ) : (
                      <div className="flex flex-col items-center justify-center h-44 w-full rounded-2xl border border-dashed border-gray-300 dark:border-gray-750 text-gray-400 bg-gray-50 dark:bg-white/5 p-4 text-center">
                        <Upload size={28} className="text-gray-300 mb-2" />
                        <p className="text-xs">Klik tombol pilih bukti untuk mengunggah screenshot / foto bukti transfer.</p>
                      </div>
                    )}

                    <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/10 dark:text-brand-400 px-4 py-2 text-sm font-semibold text-brand-600 transition">
                      Pilih Foto Bukti
                      <input type="file" accept="image/*" required onChange={handleFileChange} className="hidden" />
                    </label>
                  </div>
                </div>

                <div className="pt-4 border-t border-gray-100 dark:border-gray-850 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedInv(null);
                      setProofFile(null);
                      setProofPreview(null);
                    }}
                    className="px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-white/5 border border-gray-200 dark:border-gray-800 rounded-xl"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={uploading || !proofFile}
                    className="px-4 py-2 text-sm font-semibold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50"
                  >
                    {uploading ? "Mengunggah..." : "Kirim Bukti Pembayaran"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Upgrade / Change Plan Modal */}
        {isUpgradeOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 backdrop-blur-sm p-4">
            <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-3xl w-full max-w-md p-6 shadow-2xl space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 dark:text-white">Ubah Paket Langganan</h3>
                  <p className="text-xs text-gray-400 mt-1">Pilih paket lisensi baru untuk pesantren Anda.</p>
                </div>
                <button
                  onClick={() => setIsUpgradeOpen(false)}
                  className="p-1 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleRequestUpgrade} className="space-y-4">
                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Pilih Paket Lisensi Baru</label>
                  <select
                    value={newTierSelection}
                    onChange={(e) => setNewTierSelection(e.target.value)}
                    className="w-full rounded-2xl border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    <option value="Standar (Bulanan)">Standar (Bulanan)</option>
                    <option value="Profesional (Bulanan)">Profesional (Bulanan)</option>
                    <option value="Profesional (Tahunan)">Profesional (Tahunan)</option>
                  </select>
                </div>

                {pesantren && (
                  <div className="rounded-2xl bg-gray-50 dark:bg-white/5 border border-gray-150 dark:border-gray-800 p-4 text-[11px] text-gray-600 dark:text-gray-400 space-y-1.5 leading-relaxed">
                    <div className="font-bold text-gray-800 dark:text-gray-200 text-xs mb-1">Rincian Perhitungan Biaya:</div>
                    <div>• Santri Aktif: <strong>{pesantren.santriCount} anak</strong> × Rp {pesantren.pricePerSantri.toLocaleString("id-ID")} = Rp {(pesantren.santriCount * pesantren.pricePerSantri).toLocaleString("id-ID")}</div>
                    <div>• Musyrif/Guru: <strong>{pesantren.musyrifCount} orang</strong> × Rp {pesantren.pricePerMusyrif.toLocaleString("id-ID")} = Rp {(pesantren.musyrifCount * pesantren.pricePerMusyrif).toLocaleString("id-ID")}</div>
                    {pesantren.discountAmount > 0 && (
                      <div className="text-emerald-600 dark:text-emerald-450">• Diskon Khusus: - Rp {pesantren.discountAmount.toLocaleString("id-ID")}</div>
                    )}
                    <div className="border-t border-gray-200 dark:border-gray-700 pt-1.5 flex justify-between text-xs font-black text-gray-900 dark:text-white">
                      <span>Total Tagihan per {newTierSelection.includes("Tahunan") ? "Tahun" : "Bulan"}:</span>
                      <span>
                        Rp {Math.max(0, 
                          ((pesantren.santriCount * pesantren.pricePerSantri) + 
                          (pesantren.musyrifCount * pesantren.pricePerMusyrif) - 
                          pesantren.discountAmount) * (newTierSelection.includes("Tahunan") ? 10 : 1)
                        ).toLocaleString("id-ID")}
                      </span>
                    </div>
                    {newTierSelection.includes("Tahunan") && (
                      <div className="text-[10px] text-emerald-600 dark:text-emerald-450 italic mt-0.5">🎉 Hemat 2 bulan sewa untuk opsi penagihan tahunan!</div>
                    )}
                  </div>
                )}

                <div className="rounded-xl bg-orange-50 border border-orange-200 dark:bg-orange-950/20 dark:border-orange-900 p-4 space-y-2">
                  <h4 className="text-xs font-bold text-orange-950 dark:text-orange-300">PENTING & CATATAN:</h4>
                  <ul className="text-[10px] text-orange-850 dark:text-orange-400 leading-relaxed list-disc pl-4 space-y-1">
                    <li>Mengajukan perubahan paket akan **menerbitkan invoice (tagihan baru)** secara otomatis.</li>
                    <li>Status paket pesantren Anda akan otomatis berubah (ter-upgrade/ter-downgrade) setelah Anda **melunasi tagihan baru tersebut** dan bukti transfer diverifikasi oleh tim keuangan kami.</li>
                    <li>Sistem pembayaran menggunakan model **pay-per-user (bayar per pengguna/santri)** di luar biaya langganan dasar server.</li>
                  </ul>
                </div>

                <div className="pt-4 border-t border-gray-100 dark:border-gray-850 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setIsUpgradeOpen(false)}
                    className="px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-white/5 border border-gray-200 dark:border-gray-800 rounded-xl"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={upgradeSaving}
                    className="px-4 py-2 text-sm font-semibold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50"
                  >
                    {upgradeSaving ? "Memproses..." : "Ajukan Pindah Paket"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
