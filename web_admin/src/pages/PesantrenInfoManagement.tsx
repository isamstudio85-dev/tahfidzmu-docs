import { useEffect, useState } from "react";
import { doc, getDoc, setDoc, collection, getDocs, deleteDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { Building2, Globe, Mail, MapPin, Phone, Save, School, ShieldAlert, Upload, UserRound, X, Download, Trash2, Database } from "lucide-react";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";

type PesantrenInfo = {
  nama: string;
  alamat: string;
  noTelp: string;
  email: string;
  logoPath: string;
  npsn: string;
  website: string;
  pimpinan: string;
  qrSecurityEnabled?: boolean;
};

type ModuleKey = "quran" | "hadits" | "tajwid" | "tahsin" | "pondok_info" | "graduation";

const moduleItems: Array<{ key: ModuleKey; title: string; description: string; locked?: boolean }> = [
  { key: "quran", title: "Quran", description: "Hafalan dan setoran Al-Quran.", locked: true },
  { key: "hadits", title: "Hadits", description: "Hafalan hadits pilihan." },
  { key: "tajwid", title: "Tajwid", description: "Panduan hukum bacaan Al-Quran." },
  { key: "tahsin", title: "Tahsin", description: "Panduan fasih dan makharijul huruf." },
  { key: "pondok_info", title: "Pengetahuan Pondok", description: "Materi pengetahuan pondok yang harus dihafal." },
  { key: "graduation", title: "Wisuda & Ujian Tasmi'", description: "Pendaftaran ujian tasmi' dan kelulusan wisuda." },
];

const emptyInfo: PesantrenInfo = {
  nama: "",
  alamat: "",
  noTelp: "",
  email: "",
  logoPath: "",
  npsn: "",
  website: "",
  pimpinan: "",
};

const inputCls = "w-full rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-700 dark:bg-gray-800 dark:text-white";
const labelCls = "mb-1 block text-xs font-bold uppercase text-gray-700 dark:text-gray-300";
const infoTabs = [
  { key: "profil", label: "Profil" },
  { key: "kontak", label: "Kontak" },
  { key: "modul", label: "Modul" },
  { key: "keamanan", label: "Keamanan & Data" },
] as const;

type InfoTabKey = (typeof infoTabs)[number]["key"];

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className={labelCls}>{label}</label>
      {children}
    </div>
  );
}

export default function PesantrenInfoManagement() {
  const { profile } = useAuth();
  const [form, setForm] = useState<PesantrenInfo>(emptyInfo);
  const [activeTab, setActiveTab] = useState<InfoTabKey>("profil");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);
  const [modules, setModules] = useState<ModuleKey[]>(["quran", "hadits", "tajwid", "tahsin", "graduation"]);

  useEffect(() => {
    if (profile?.pesantrenId) {
      load();
    } else {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile?.pesantrenId]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const [infoSnap, modulesSnap] = await Promise.all([
        getDoc(doc(db, "pesantren", profile.pesantrenId, "settings", "pesantren_info")),
        getDoc(doc(db, "pesantren", profile.pesantrenId, "settings", "modules")),
      ]);
      const data = infoSnap.exists() ? infoSnap.data() : {};
      const active = modulesSnap.exists() ? modulesSnap.data()?.active : null;
      setForm({
        nama: String(data.nama || ""),
        alamat: String(data.alamat || ""),
        noTelp: String(data.noTelp || ""),
        email: String(data.email || ""),
        logoPath: String(data.logoPath || ""),
        npsn: String(data.npsn || ""),
        website: String(data.website || ""),
        pimpinan: String(data.pimpinan || ""),
        qrSecurityEnabled: data.qrSecurityEnabled !== false, // Default true
      });
      if (Array.isArray(active) && active.length > 0) {
        const normalized = Array.from(new Set(["quran", ...active.filter((item): item is ModuleKey => typeof item === "string")])) as ModuleKey[];
        setModules(normalized);
      }
    } catch (err) {
      console.error(err);
      setError("Gagal memuat info pesantren.");
    } finally {
      setLoading(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError("Ukuran logo maksimal 2MB");
      return;
    }
    setLogoFile(file);
    setLogoPreview(URL.createObjectURL(file));
    setError(null);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.pesantrenId) return;
    if (!form.nama.trim()) {
      setError("Nama pesantren wajib diisi");
      return;
    }

    setSaving(true);
    setError(null);
    try {
      let finalLogoPath = form.logoPath || "";
      if (logoFile) {
        const logoRef = ref(storage, `pesantren_logos/${profile.pesantrenId}.jpg`);
        const uploaded = await uploadBytes(logoRef, logoFile);
        finalLogoPath = await getDownloadURL(uploaded.ref);
      }

      await Promise.all([
        setDoc(
          doc(db, "pesantren", profile.pesantrenId, "settings", "pesantren_info"),
          {
            nama: form.nama.trim(),
            alamat: form.alamat.trim(),
            noTelp: form.noTelp.trim(),
            email: form.email.trim(),
            logoPath: finalLogoPath,
            npsn: form.npsn.trim(),
            website: form.website.trim(),
            pimpinan: form.pimpinan.trim(),
            qrSecurityEnabled: form.qrSecurityEnabled ?? true,
          },
          { merge: true }
        ),
        setDoc(
          doc(db, "pesantren", profile.pesantrenId, "settings", "modules"),
          {
            active: Array.from(new Set(["quran", ...modules])),
          },
          { merge: true }
        ),
      ]);

      setForm((prev) => ({ ...prev, logoPath: finalLogoPath }));
      setLogoFile(null);
      setLogoPreview(null);
    } catch (err: any) {
      console.error(err);
      setError(`Gagal menyimpan: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  const toggleModule = (key: ModuleKey) => {
    if (key === "quran") return;
    setModules((prev) => prev.includes(key) ? prev.filter((item) => item !== key) : [...prev, key]);
  };

  const handleBackup = async () => {
    if (!profile?.pesantrenId) return;
    setSaving(true);
    setError(null);
    try {
      const backupData: any = {
        pesantrenId: profile.pesantrenId,
        timestamp: new Date().toISOString(),
        collections: {},
      };
      const collectionsList = ["santri", "musyrif", "halaqah", "kelas", "graduation_events", "graduation_registrations", "user_mappings"];
      for (const col of collectionsList) {
        const snap = await getDocs(collection(db, "pesantren", profile.pesantrenId, col));
        backupData.collections[col] = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      }
      const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `backup_tahfidzmu_${profile.pesantrenId}_${new Date().toISOString().slice(0, 10)}.json`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err: any) {
      console.error(err);
      setError(`Gagal mengekspor backup: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  const handleReset = async () => {
    if (!profile?.pesantrenId) return;
    const confirmation = prompt(
      "PERINGATAN BAHAYA!\nTindakan ini akan menghapus seluruh data santri, musyrif, halaqah, dan kelas secara permanen dari server.\n\nKetik kata 'RESET' untuk mengonfirmasi tindakan:"
    );
    if (confirmation !== "RESET") {
      alert("Konfirmasi batal. Data aman.");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const collectionsList = ["santri", "musyrif", "halaqah", "kelas", "graduation_events", "graduation_registrations", "user_mappings"];
      for (const col of collectionsList) {
        const snap = await getDocs(collection(db, "pesantren", profile.pesantrenId, col));
        await Promise.all(snap.docs.map((doc) => deleteDoc(doc.ref)));
      }
      alert("Seluruh data database berhasil di-reset bersih.");
      load();
    } catch (err: any) {
      console.error(err);
      setError(`Gagal mereset database: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  if (profile?.role !== "admin" && profile?.role !== "superAdmin") {
    return (
      <div className="flex min-h-[400px] flex-col items-center justify-center rounded-2xl border border-gray-200 bg-white p-6 text-center dark:border-gray-800 dark:bg-white/[0.03]">
        <ShieldAlert size={48} className="mb-4 text-error-500" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
      </div>
    );
  }

  return (
    <>
      <PageMeta title="Info Pesantren | TahfidzMU Admin" description="Kelola profil dan kontak pesantren." />
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Info Pesantren</h2>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Kelola profil utama pesantren pada dokumen `settings/pesantren_info`.</p>
        </div>

        {loading ? (
          <div className="flex min-h-[200px] items-center justify-center"><div className="h-8 w-8 animate-spin rounded-full border-3 border-brand-500 border-t-transparent"></div></div>
        ) : (
          <form onSubmit={handleSave} className="grid gap-6 lg:grid-cols-[320px_minmax(0,1fr)]">
            <div className="rounded-2xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-white/[0.03]">
              <div className="flex flex-col items-center text-center">
                <div className="relative">
                  {(logoPreview || form.logoPath) ? (
                    <img src={logoPreview || form.logoPath} alt={form.nama || "Pesantren"} className="h-28 w-28 rounded-full border border-gray-200 object-cover dark:border-gray-700" />
                  ) : (
                    <div className="flex h-28 w-28 items-center justify-center rounded-full bg-brand-50 text-brand-500 dark:bg-brand-500/10">
                      <School size={40} />
                    </div>
                  )}
                  {(logoPreview || form.logoPath) && (
                    <button type="button" onClick={() => { setLogoFile(null); setLogoPreview(null); setForm((prev) => ({ ...prev, logoPath: "" })); }} className="absolute -right-2 -top-2 rounded-full bg-error-500 p-1 text-white">
                      <X size={12} />
                    </button>
                  )}
                </div>
                <h3 className="mt-4 text-lg font-bold text-gray-800 dark:text-white">{form.nama || "Profil Pesantren"}</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Logo ini akan dipakai sebagai `logoPath` pada info pesantren.</p>
                <label className="mt-4 inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-50 px-3 py-2 text-xs font-bold text-brand-500 hover:bg-brand-100 dark:bg-brand-500/10">
                  <Upload size={14} /> Pilih Logo
                  <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                </label>
              </div>
            </div>

            <div className="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
              {error && <div className="mb-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{error}</div>}
              <div className="sticky top-0 z-10 rounded-t-2xl border-b border-gray-200 bg-white/95 px-6 py-4 backdrop-blur dark:border-gray-800 dark:bg-gray-900/95">
                <div className="flex flex-wrap gap-2">
                  {infoTabs.map((tab) => {
                    const active = activeTab === tab.key;
                    return (
                      <button
                        key={tab.key}
                        type="button"
                        onClick={() => setActiveTab(tab.key)}
                        className={`rounded-xl px-4 py-2 text-sm font-semibold transition ${active ? "bg-brand-500 text-white shadow-sm" : "border border-gray-200 text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"}`}
                      >
                        {tab.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="space-y-6 px-6 py-6">
                {activeTab === "profil" && (
                  <section className="grid gap-4 md:grid-cols-2">
                    <Field label="Nama Pesantren *">
                      <div className="relative">
                        <Building2 size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.nama} onChange={(e) => setForm((prev) => ({ ...prev, nama: e.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <Field label="NPSN">
                      <div className="relative">
                        <Building2 size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.npsn} onChange={(e) => setForm((prev) => ({ ...prev, npsn: e.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <Field label="Kiai / Pimpinan Pondok">
                      <div className="relative">
                        <UserRound size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.pimpinan} onChange={(e) => setForm((prev) => ({ ...prev, pimpinan: e.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <div className="md:col-span-2">
                      <Field label="Alamat">
                        <div className="relative">
                          <MapPin size={16} className="pointer-events-none absolute left-3 top-3 text-gray-400" />
                          <textarea value={form.alamat} onChange={(e) => setForm((prev) => ({ ...prev, alamat: e.target.value }))} rows={3} className={`${inputCls} pl-10`} />
                        </div>
                      </Field>
                    </div>
                  </section>
                )}

                {activeTab === "kontak" && (
                  <section className="grid gap-4 md:grid-cols-2">
                    <Field label="No. Telp / WA">
                      <div className="relative">
                        <Phone size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.noTelp} onChange={(e) => setForm((prev) => ({ ...prev, noTelp: e.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <Field label="Email">
                      <div className="relative">
                        <Mail size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input type="email" value={form.email} onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <div className="md:col-span-2">
                      <Field label="Website Pesantren">
                        <div className="relative">
                          <Globe size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                          <input value={form.website} onChange={(e) => setForm((prev) => ({ ...prev, website: e.target.value }))} className={`${inputCls} pl-10`} />
                        </div>
                      </Field>
                    </div>
                  </section>
                )}

                {activeTab === "modul" && (
                  <section>
                    <h3 className="text-sm font-bold text-gray-800 dark:text-white">Modul Pesantren</h3>
                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">Disimpan ke dokumen `settings/modules` dengan field `active`.</p>
                    <div className="mt-4 grid gap-3 md:grid-cols-2">
                      {moduleItems.map((item) => {
                        const active = modules.includes(item.key);
                        return (
                          <label key={item.key} className="flex items-center justify-between rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-white/5">
                            <div className="pr-4">
                              <div className="font-semibold text-gray-800 dark:text-white">{item.title}</div>
                              <div className="text-xs text-gray-500 dark:text-gray-400">{item.description}</div>
                            </div>
                            <input type="checkbox" checked={active} disabled={item.locked} onChange={() => toggleModule(item.key)} className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500 disabled:opacity-60" />
                          </label>
                        );
                      })}
                    </div>
                  </section>
                )}

                {activeTab === "keamanan" && (
                  <section className="space-y-6">
                    <div>
                      <h3 className="text-sm font-bold text-gray-800 dark:text-white flex items-center gap-2">
                        <ShieldAlert size={16} className="text-brand-500" />
                        Kebijakan Keamanan Aplikasi
                      </h3>
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Atur tingkat keamanan verifikasi kehadiran santri saat setoran hafalan.
                      </p>
                      <div className="mt-4">
                        <label className="flex items-center justify-between rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-white/5 cursor-pointer">
                          <div className="pr-4">
                            <div className="font-semibold text-gray-800 dark:text-white">Wajib Scan QR Santri</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">
                              Jika aktif, Musyrif wajib memindai kartu santri sebelum memulai sesi simak Al-Quran. (Sangat disarankan).
                            </div>
                          </div>
                          <input
                            type="checkbox"
                            checked={form.qrSecurityEnabled}
                            onChange={(e) => setForm(prev => ({ ...prev, qrSecurityEnabled: e.target.checked }))}
                            className="h-5 w-5 rounded border-gray-300 text-brand-500 focus:ring-brand-500"
                          />
                        </label>
                      </div>
                    </div>

                    <hr className="border-gray-200 dark:border-gray-800" />

                    <div>
                      <h3 className="text-sm font-bold text-gray-800 dark:text-white flex items-center gap-2">
                        <Database size={16} className="text-brand-500" />
                        Pencadangan Data (Backup)
                      </h3>
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Seluruh data Anda otomatis disinkronkan ke server Google Firebase. Namun, Anda dapat mengunduh berkas salinan cadangan lokal dalam format JSON demi keamanan ekstra.
                      </p>
                      <div className="mt-3">
                        <button
                          type="button"
                          onClick={handleBackup}
                          disabled={saving}
                          className="inline-flex items-center gap-2 rounded-xl bg-brand-50 px-4 py-2.5 text-xs font-bold text-brand-500 hover:bg-brand-100 dark:bg-brand-500/10"
                        >
                          <Download size={14} /> Ekspor Data Pesantren (.json)
                        </button>
                      </div>
                    </div>

                    <hr className="border-gray-200 dark:border-gray-800" />

                    <div>
                      <h3 className="text-sm font-bold text-error-500 flex items-center gap-2">
                        <ShieldAlert size={16} className="text-error-500" />
                        Reset Bersih Database
                      </h3>
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Menghapus seluruh data secara permanen (Santri, Musyrif, Halaqah, Kelas, Event Wisuda, dan Registrasi) di bawah pesantren ini. Tindakan ini tidak dapat dibatalkan.
                      </p>
                      <div className="mt-3">
                        <button
                          type="button"
                          onClick={handleReset}
                          disabled={saving}
                          className="inline-flex items-center gap-2 rounded-xl bg-error-50 px-4 py-2.5 text-xs font-bold text-error-500 hover:bg-error-100 dark:bg-error-500/10"
                        >
                          <Trash2 size={14} /> Reset Semua Data Pesantren
                        </button>
                      </div>
                    </div>
                  </section>
                )}
              </div>

              <div className="sticky bottom-0 z-10 flex justify-end border-t border-gray-200 bg-white/95 px-6 py-4 backdrop-blur dark:border-gray-800 dark:bg-gray-900/95">
                <button type="submit" disabled={saving} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-50">
                  <Save size={16} /> {saving ? "Menyimpan..." : "Simpan Perubahan"}
                </button>
              </div>
            </div>
          </form>
        )}
      </div>
    </>
  );
}