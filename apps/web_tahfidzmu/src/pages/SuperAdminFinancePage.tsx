import { useEffect, useState } from "react";
import { collection, doc, getDocs, updateDoc, setDoc, Timestamp, getDoc } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Search, ShieldAlert, CheckCircle, Clock, CreditCard, Calendar, Plus, FileText, Image as ImageIcon, X } from "lucide-react";

type InvoiceItem = {
  id: string;
  pesantrenId: string;
  pesantrenNama: string;
  amount: number;
  subscriptionTier: string;
  status: "unpaid" | "paid" | "expired";
  dueDate: any;
  paidDate?: any;
  createdDate: any;
  paymentMethod?: string;
  paymentProofUrl?: string;
};

type PesantrenOption = {
  id: string;
  nama: string;
  subscriptionTier: string;
  activeUntil: any;
  pricePerSantri: number;
  pricePerMusyrif: number;
  discountAmount: number;
};

const inputCls = "w-full rounded-2xl border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-700 dark:bg-gray-800 dark:text-white";
const labelCls = "mb-1.5 block text-xs font-bold uppercase tracking-[0.14em] text-gray-500 dark:text-gray-400";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className={labelCls}>{label}</label>
      {children}
    </div>
  );
}

export default function SuperAdminFinancePage() {
  const { profile } = useAuth();
  const [invoices, setInvoices] = useState<InvoiceItem[]>([]);
  const [pesantrenList, setPesantrenList] = useState<PesantrenOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<"unpaid" | "paid">("unpaid");
  const [processingId, setProcessingId] = useState<string | null>(null);

  // Modal states
  const [isOpen, setIsOpen] = useState(false);
  const [selectedPesantrenId, setSelectedPesantrenId] = useState("");
  const [amount, setAmount] = useState(150000);
  const [tier, setTier] = useState("Standar");
  const [dueDate, setDueDate] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Proof Modal
  const [proofUrl, setProofUrl] = useState<string | null>(null);

  // Dynamic user calculations states
  const [calcLoading, setCalcLoading] = useState(false);
  const [calcDetails, setCalcDetails] = useState<{
    santriCount: number;
    musyrifCount: number;
    text: string;
  } | null>(null);

  useEffect(() => {
    if (profile?.role === "superAdmin") {
      loadData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const loadData = async () => {
    setLoading(true);
    try {
      // 1. Load all Pesantren options for dropdown manual billing
      const pesSnap = await getDocs(collection(db, "pesantren"));
      const pOptions = pesSnap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          nama: data.nama || "Pesantren",
          subscriptionTier: data.subscriptionTier || "Standar",
          activeUntil: data.activeUntil,
          pricePerSantri: typeof data.pricePerSantri === "number" ? data.pricePerSantri : 5000,
          pricePerMusyrif: typeof data.pricePerMusyrif === "number" ? data.pricePerMusyrif : 0,
          discountAmount: typeof data.discountAmount === "number" ? data.discountAmount : 0,
        };
      });
      setPesantrenList(pOptions);

      // 2. Load all Invoices across all tenants
      // Since invoices are saved under /pesantren/{pid}/invoices, we iterate and load
      const allInvoices: InvoiceItem[] = [];
      for (const p of pOptions) {
        const invSnap = await getDocs(collection(db, "pesantren", p.id, "invoices"));
        invSnap.forEach((doc) => {
          const data = doc.data();
          allInvoices.push({
            id: doc.id,
            pesantrenId: p.id,
            pesantrenNama: p.nama,
            amount: Number(data.amount || 0),
            subscriptionTier: data.subscriptionTier || "Standar",
            status: data.status || "unpaid",
            dueDate: data.dueDate,
            paidDate: data.paidDate,
            createdDate: data.createdDate || Timestamp.now(),
            paymentMethod: data.paymentMethod,
            paymentProofUrl: data.paymentProofUrl,
          });
        });
      }

      // Sort by createdDate descending
      allInvoices.sort((a, b) => {
        const tA = a.createdDate?.seconds || 0;
        const tB = b.createdDate?.seconds || 0;
        return tB - tA;
      });

      setInvoices(allInvoices);
    } catch (err) {
      console.error("Gagal memuat data keuangan:", err);
    } finally {
      setLoading(false);
    }
  };

  const handlePesantrenChange = async (pid: string) => {
    setSelectedPesantrenId(pid);
    setCalcDetails(null);
    if (!pid) return;

    const matched = pesantrenList.find((p) => p.id === pid);
    if (!matched) return;

    const defaultTier = matched.subscriptionTier === "Profesional" ? "Profesional (Bulanan)" : "Standar (Bulanan)";
    setTier(defaultTier);

    setCalcLoading(true);
    try {
      const [santriSnap, musyrifSnap] = await Promise.all([
        getDocs(collection(db, "pesantren", pid, "santri")),
        getDocs(collection(db, "pesantren", pid, "musyrif")),
      ]);

      const sCount = santriSnap.docs.length;
      const mCount = musyrifSnap.docs.length;

      const priceSantriTotal = sCount * matched.pricePerSantri;
      const priceMusyrifTotal = mCount * matched.pricePerMusyrif;
      const totalAmount = Math.max(0, priceSantriTotal + priceMusyrifTotal - matched.discountAmount);

      setAmount(totalAmount);
      setCalcDetails({
        santriCount: sCount,
        musyrifCount: mCount,
        text: `Kalkulasi Otomatis Berlangganan:\n` +
          `• Santri: ${sCount} anak × Rp ${matched.pricePerSantri.toLocaleString("id-ID")} = Rp ${priceSantriTotal.toLocaleString("id-ID")}\n` +
          `• Musyrif: ${mCount} orang × Rp ${matched.pricePerMusyrif.toLocaleString("id-ID")} = Rp ${priceMusyrifTotal.toLocaleString("id-ID")}\n` +
          `• Diskon khusus pesantren: - Rp ${matched.discountAmount.toLocaleString("id-ID")}`
      });
    } catch (err) {
      console.error(err);
      setAmount(matched.subscriptionTier === "Profesional" ? 300000 : 150000);
    } finally {
      setCalcLoading(false);
    }
  };

  const handleCreateInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPesantrenId || !dueDate) {
      setError("Pesantren dan Tanggal Jatuh Tempo wajib diisi.");
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const selectedPes = pesantrenList.find((p) => p.id === selectedPesantrenId);
      if (!selectedPes) throw new Error("Pesantren tidak valid");

      const invId = `INV-${Date.now().toString().substring(4)}`;
      const invRef = doc(db, "pesantren", selectedPesantrenId, "invoices", invId);

      await setDoc(invRef, {
        id: invId,
        pesantrenId: selectedPesantrenId,
        amount,
        subscriptionTier: tier,
        status: "unpaid",
        dueDate: Timestamp.fromDate(new Date(dueDate)),
        createdDate: Timestamp.now(),
      });

      setIsOpen(false);
      setSelectedPesantrenId("");
      setDueDate("");
      await loadData();
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Gagal membuat invoice");
    } finally {
      setSaving(false);
    }
  };

  const handleConfirmPaid = async (inv: InvoiceItem) => {
    const confirm = window.confirm(`Konfirmasi pembayaran tagihan ${inv.id} senilai Rp ${inv.amount.toLocaleString("id-ID")} secara LUNAS?\n\nTindakan ini otomatis memperpanjang masa aktif pesantren terkait.`);
    if (!confirm) return;

    setProcessingId(inv.id);
    try {
      // 1. Update status invoice to paid in subcollection
      await updateDoc(doc(db, "pesantren", inv.pesantrenId, "invoices", inv.id), {
        status: "paid",
        paidDate: Timestamp.now(),
        paymentMethod: inv.paymentMethod || "Transfer Bank Manual",
      });

      // 2. Extend Pesantren tenant activeUntil date
      const pDoc = await getDoc(doc(db, "pesantren", inv.pesantrenId));
      if (pDoc.exists()) {
        const pData = pDoc.data();
        const currentActiveUntil = pData.activeUntil;
        let baseDate = new Date();

        if (currentActiveUntil && currentActiveUntil.toDate().getTime() > Date.now()) {
          baseDate = currentActiveUntil.toDate();
        }

        // Extend based on tier
        const days = inv.subscriptionTier.toLowerCase().includes("tahunan") ? 365 : 30;
        const nextDate = new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000);
        const resolvedTier = inv.subscriptionTier.includes("Profesional") ? "Profesional" : "Standar";

        await updateDoc(doc(db, "pesantren", inv.pesantrenId), {
          activeUntil: Timestamp.fromDate(nextDate),
          subscriptionTier: resolvedTier,
          status: "active", // Reactivate tenant status in case it was suspended
        });
      }

      alert(`Pembayaran invoice ${inv.id} berhasil dikonfirmasi lunas dan masa sewa pesantren diperpanjang.`);
      await loadData();
    } catch (err: any) {
      console.error(err);
      alert("Gagal mengonfirmasi lunas: " + err.message);
    } finally {
      setProcessingId(null);
    }
  };

  const isFinanceOrSuperAdmin = profile?.role === "superAdmin";

  if (!isFinanceOrSuperAdmin) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Halaman ini hanya untuk Administrator Keuangan (Super Admin).</p>
      </div>
    );
  }

  const filtered = invoices.filter((inv) => {
    const matchesSearch =
      inv.id.toLowerCase().includes(search.toLowerCase()) ||
      inv.pesantrenNama.toLowerCase().includes(search.toLowerCase());
    const matchesTab = inv.status === activeTab;
    return matchesSearch && matchesTab;
  });

  // Financial Stats
  const revenuePaid = invoices.filter((i) => i.status === "paid").reduce((sum, i) => sum + i.amount, 0);
  const revenueUnpaid = invoices.filter((i) => i.status === "unpaid").reduce((sum, i) => sum + i.amount, 0);
  const unpaidCount = invoices.filter((i) => i.status === "unpaid").length;
  const paidCount = invoices.filter((i) => i.status === "paid").length;

  const formatDate = (ts: any) => {
    if (!ts) return "-";
    const date = ts.toDate ? ts.toDate() : new Date(ts);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  };

  return (
    <>
      <PageMeta title="Keuangan & Tagihan | TahfidzMU Super Admin" description="Manajemen invoice billing langganan pesantren." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Keuangan & Invoice Langganan</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Pantau laporan omset bulanan, terbitkan tagihan manual, dan verifikasi bukti transfer pembayaran sewa.
            </p>
          </div>
          <button
            onClick={() => {
              setError(null);
              setIsOpen(true);
            }}
            className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition"
          >
            <Plus size={18} /> Terbitkan Tagihan Baru
          </button>
        </div>

        {/* Stats Grid */}
        <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-emerald-600 dark:text-emerald-450 uppercase tracking-wider">OMSET LUNAS (PAID)</div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">Rp {revenuePaid.toLocaleString("id-ID")}</div>
            <div className="text-xs text-gray-400">Total sewa terkumpul</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-orange-600 dark:text-orange-450 uppercase tracking-wider">PENDING REVENUE</div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">Rp {revenueUnpaid.toLocaleString("id-ID")}</div>
            <div className="text-xs text-gray-400">Total tagihan tertunggak</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-gray-500 dark:text-gray-450 uppercase tracking-wider">INVOICE PAID</div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">{paidCount} Tagihan</div>
            <div className="text-xs text-gray-400">Berhasil diselesaikan</div>
          </div>
          <div className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-1">
            <div className="text-xs font-bold text-orange-500 uppercase tracking-wider">INVOICE UNPAID</div>
            <div className="text-xl font-black text-gray-950 dark:text-white md:text-2xl">{unpaidCount} Tagihan</div>
            <div className="text-xs text-gray-400">Menunggu konfirmasi lunas</div>
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
            Tagihan Tertunggak (Unpaid)
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-orange-100 text-orange-600 dark:bg-orange-950 dark:text-orange-400">
              {unpaidCount}
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
            Riwayat Pembayaran (Paid)
            <span className="ml-1 px-2 py-0.5 text-xs font-bold rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400">
              {paidCount}
            </span>
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Cari berdasarkan ID invoice atau nama pesantren..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm"
          />
        </div>

        {/* Table List */}
        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]">
            <div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500">
            <CreditCard size={36} className="mx-auto mb-3 text-gray-300 dark:text-gray-700" />
            <p className="text-sm font-medium">Tidak ada invoice dalam kategori ini.</p>
          </div>
        ) : (
          <div className="overflow-hidden bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">ID / Pesantren</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Paket Sewa</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Nominal Tagihan</th>
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Jatuh Tempo</th>
                    {activeTab === "paid" ? (
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Metode & Tgl Lunas</th>
                    ) : (
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Bukti Transfer</th>
                    )}
                    <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                  {filtered.map((inv) => (
                    <tr key={inv.id} className="hover:bg-gray-50/30 dark:hover:bg-gray-800/20 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-gray-950 dark:text-white flex items-center gap-2">
                          <FileText size={14} className="text-gray-450" />
                          {inv.id}
                        </div>
                        <div className="text-xs text-gray-400">{inv.pesantrenNama}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm font-medium text-gray-850 dark:text-gray-300">{inv.subscriptionTier}</div>
                        <div className="text-[10px] text-gray-400">Diterbitkan: {formatDate(inv.createdDate)}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="font-bold text-gray-900 dark:text-white">
                          Rp {inv.amount.toLocaleString("id-ID")}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar size={14} className="text-gray-400" />
                          {formatDate(inv.dueDate)}
                        </div>
                      </td>
                      {activeTab === "paid" ? (
                        <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                          <div className="font-medium text-emerald-600 dark:text-emerald-450">{inv.paymentMethod || "Transfer Bank"}</div>
                          <div className="text-[10px] text-gray-400">Lunas: {formatDate(inv.paidDate)}</div>
                        </td>
                      ) : (
                        <td className="px-6 py-4 text-sm">
                          {inv.paymentProofUrl ? (
                            <button
                              onClick={() => setProofUrl(inv.paymentProofUrl || null)}
                              className="inline-flex items-center gap-1 text-xs font-semibold text-brand-600 hover:text-brand-700 bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/10 dark:text-brand-400 dark:hover:bg-brand-500/20 px-3 py-1.5 rounded-lg border border-brand-200 dark:border-brand-500/30"
                            >
                              <ImageIcon size={12} /> Lihat Bukti
                            </button>
                          ) : (
                            <span className="text-xs text-gray-400 italic">Belum diunggah</span>
                          )}
                        </td>
                      )}
                      <td className="px-6 py-4 text-right">
                        {inv.status === "unpaid" ? (
                          <button
                            onClick={() => handleConfirmPaid(inv)}
                            disabled={processingId === inv.id}
                            className="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 disabled:bg-emerald-800/50 rounded-xl transition shadow-sm"
                          >
                            {processingId === inv.id ? "Memproses..." : "Konfirmasi Lunas"}
                          </button>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 dark:text-emerald-450 bg-emerald-100/50 dark:bg-emerald-950/30 px-3 py-1 rounded-full">
                            <CheckCircle size={12} /> Paid / Lunas
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

        {/* Create Invoice Modal */}
        {isOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 backdrop-blur-sm p-4">
            <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-3xl w-full max-w-md p-6 shadow-2xl space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 dark:text-white">Terbitkan Tagihan Baru</h3>
                  <p className="text-xs text-gray-400 mt-1">Buat tagihan manual untuk pesantren mitra.</p>
                </div>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-1 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <X size={18} />
                </button>
              </div>

              {error && (
                <div className="p-3 text-xs font-medium text-red-700 bg-red-50 border border-red-100 rounded-xl dark:bg-red-500/10 dark:text-red-400 dark:border-red-500/20">
                  {error}
                </div>
              )}

              <form onSubmit={handleCreateInvoice} className="space-y-4">
                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Pesantren Penerima</label>
                  <select
                    value={selectedPesantrenId}
                    required
                    onChange={(e) => void handlePesantrenChange(e.target.value)}
                    className={inputCls}
                  >
                    <option value="">-- Pilih Pesantren --</option>
                    {pesantrenList.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.nama} ({p.id})
                      </option>
                    ))}
                  </select>
                </div>

                {calcLoading && (
                  <div className="flex items-center gap-2 text-xs text-brand-600 font-medium">
                    <div className="w-3.5 h-3.5 border-2 border-brand-500/20 border-t-brand-500 rounded-full animate-spin"></div>
                    <span>Mengalkulasi jumlah pengguna riil pesantren...</span>
                  </div>
                )}

                {calcDetails && (
                  <div className="rounded-xl bg-gray-50 dark:bg-white/5 border border-gray-150 dark:border-gray-800 p-3 text-[11px] text-gray-600 dark:text-gray-400 font-medium whitespace-pre-line leading-relaxed">
                    {calcDetails.text}
                  </div>
                )}

                <div className="grid gap-4 grid-cols-2">
                  <Field label="Nominal Tagihan (Rp)">
                    <input
                      type="number"
                      required
                      value={amount}
                      onChange={(e) => setAmount(Number(e.target.value))}
                      placeholder="Contoh: 150000"
                      className={inputCls}
                    />
                  </Field>
                  <Field label="Paket Langganan">
                    <select value={tier} onChange={(e) => setTier(e.target.value)} className={inputCls}>
                      <option value="Standar (Bulanan)">Standar (Bulanan)</option>
                      <option value="Profesional (Bulanan)">Profesional (Bulanan)</option>
                      <option value="Profesional (Tahunan)">Profesional (Tahunan)</option>
                    </select>
                  </Field>
                </div>

                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Jatuh Tempo Pembayaran</label>
                  <input
                    type="date"
                    required
                    value={dueDate}
                    onChange={(e) => setDueDate(e.target.value)}
                    className={inputCls}
                  />
                </div>

                <div className="pt-4 border-t border-gray-100 dark:border-gray-850 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setIsOpen(false)}
                    className="px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-white/5 border border-gray-200 dark:border-gray-800 rounded-xl"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="px-4 py-2 text-sm font-semibold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50"
                  >
                    {saving ? "Memproses..." : "Terbitkan Tagihan"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* View Proof Image Dialog */}
        {proofUrl && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 backdrop-blur-sm p-4">
            <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 dark:text-white">Bukti Transfer Pembayaran</h3>
                  <p className="text-xs text-gray-400 mt-1">Harap teliti kecocokan nominal dan nama bank pengirim sebelum klik lunas.</p>
                </div>
                <button
                  onClick={() => setProofUrl(null)}
                  className="p-1 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-700 bg-gray-50 flex items-center justify-center max-h-[450px]">
                <img src={proofUrl} alt="Bukti Transfer" className="max-w-full max-h-[420px] object-contain" />
              </div>

              <div className="flex justify-end pt-2">
                <button
                  onClick={() => setProofUrl(null)}
                  className="px-5 py-2.5 text-sm font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-xl transition"
                >
                  Tutup Preview
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
