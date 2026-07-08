import { useEffect, useMemo, useState } from "react";
import { collection, deleteDoc, doc, getDocs, setDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { CalendarDays, Edit2, GraduationCap, Plus, Save, Search, ShieldAlert, Trash2, Upload, X } from "lucide-react";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";

type GraduationEvent = {
  id: string;
  title: string;
  year: string;
  examStartDate: string | null;
  examEndDate: string | null;
  graduationDate: string | null;
  method: string;
  sessionsCount: number;
  requirements: string;
  description: string;
  status: string;
  isPublished: boolean;
  isCertificatesReleased: boolean;
  registrationFee: number;
  graduationFee: number;
  bannerPath: string | null;
};

type GraduationRegistration = {
  id: string;
  eventId: string;
  santriId: string;
  registrationDate: string;
  status: "menunggu" | "diterima" | "ditolak";
  registrationPaymentStatus: "belumBayar" | "lunas";
  graduationPaymentStatus: "belumBayar" | "lunas";
  notes: string | null;
  registeredBy: string;
};

type SantriLite = {
  id: string;
  name: string;
  nis: string;
  photoPath: string | null;
};

const emptyEvent = (): GraduationEvent => ({
  id: "",
  title: "",
  year: String(new Date().getFullYear()),
  examStartDate: null,
  examEndDate: null,
  graduationDate: null,
  method: "Tasmi' Sekali Duduk",
  sessionsCount: 1,
  requirements: "",
  description: "",
  status: "upcoming",
  isPublished: false,
  isCertificatesReleased: false,
  registrationFee: 0,
  graduationFee: 0,
  bannerPath: null,
});

const inputCls = "w-full rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-700 dark:bg-gray-800 dark:text-white";
const labelCls = "mb-1 block text-xs font-bold uppercase text-gray-700 dark:text-gray-300";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className={labelCls}>{label}</label>
      {children}
    </div>
  );
}

function formatDateLabel(value: string | null) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("id-ID", { day: "2-digit", month: "short", year: "numeric" }).format(date);
}

export default function WisudaManagement() {
  const { profile } = useAuth();
  const [events, setEvents] = useState<GraduationEvent[]>([]);
  const [registrations, setRegistrations] = useState<GraduationRegistration[]>([]);
  const [santriList, setSantriList] = useState<SantriLite[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<GraduationEvent>(emptyEvent());
  const [bannerFile, setBannerFile] = useState<File | null>(null);
  const [bannerPreview, setBannerPreview] = useState<string | null>(null);

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
      const [eventSnap, registrationSnap, santriSnap] = await Promise.all([
        getDocs(collection(db, "pesantren", profile.pesantrenId, "graduation_events")),
        getDocs(collection(db, "pesantren", profile.pesantrenId, "graduation_registrations")),
        getDocs(collection(db, "pesantren", profile.pesantrenId, "santri")),
      ]);
      setEvents(
        eventSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: String(data.id || d.id),
            title: String(data.title || ""),
            year: String(data.year || ""),
            examStartDate: data.examStartDate ? String(data.examStartDate) : null,
            examEndDate: data.examEndDate ? String(data.examEndDate) : null,
            graduationDate: data.graduationDate ? String(data.graduationDate) : null,
            method: String(data.method || "Tasmi' Sekali Duduk"),
            sessionsCount: Number(data.sessionsCount || 1),
            requirements: String(data.requirements || ""),
            description: String(data.description || ""),
            status: String(data.status || "upcoming"),
            isPublished: Boolean(data.isPublished),
            isCertificatesReleased: Boolean(data.isCertificatesReleased),
            registrationFee: Number(data.registrationFee || 0),
            graduationFee: Number(data.graduationFee || 0),
            bannerPath: data.bannerPath ? String(data.bannerPath) : null,
          };
        })
      );
      setRegistrations(
        registrationSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: String(data.id || d.id),
            eventId: String(data.eventId || ""),
            santriId: String(data.santriId || ""),
            registrationDate: String(data.registrationDate || ""),
            status: (String(data.status || "menunggu") as GraduationRegistration["status"]),
            registrationPaymentStatus: (String(data.registrationPaymentStatus || "belumBayar") as GraduationRegistration["registrationPaymentStatus"]),
            graduationPaymentStatus: (String(data.graduationPaymentStatus || "belumBayar") as GraduationRegistration["graduationPaymentStatus"]),
            notes: data.notes ? String(data.notes) : null,
            registeredBy: String(data.registeredBy || "unknown"),
          };
        })
      );
      setSantriList(
        santriSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            name: String(data.name || ""),
            nis: String(data.nis || ""),
            photoPath: data.photoPath ? String(data.photoPath) : null,
          };
        })
      );
    } catch (err) {
      console.error(err);
      setError("Gagal memuat agenda wisuda.");
    } finally {
      setLoading(false);
    }
  };

  const getSantri = (santriId: string) => santriList.find((item) => item.id === santriId);

  const getEventRegistrations = (eventId: string) => registrations.filter((item) => item.eventId === eventId);

  const updateRegistrationField = async (
    registration: GraduationRegistration,
    patch: Partial<GraduationRegistration>
  ) => {
    if (!profile?.pesantrenId) return;
    try {
      await setDoc(
        doc(db, "pesantren", profile.pesantrenId, "graduation_registrations", registration.id),
        {
          ...registration,
          ...patch,
        },
        { merge: true }
      );
      await load();
    } catch (err) {
      console.error(err);
      alert("Gagal memperbarui pendaftaran wisuda");
    }
  };

  const filtered = useMemo(() => {
    const needle = search.toLowerCase();
    return [...events]
      .filter((event) => [event.title, event.year, event.method].join(" ").toLowerCase().includes(needle))
      .sort((a, b) => String(b.year || "").localeCompare(String(a.year || ""), "id", { numeric: true }));
  }, [events, search]);

  const publishedCount = useMemo(() => events.filter((event) => event.isPublished).length, [events]);
  const releasedCertificatesCount = useMemo(
    () => events.filter((event) => event.isCertificatesReleased).length,
    [events]
  );
  const acceptedCount = useMemo(
    () => registrations.filter((item) => item.status === "diterima").length,
    [registrations]
  );

  const handleOpenAdd = () => {
    setIsEdit(false);
    setForm(emptyEvent());
    setBannerFile(null);
    setBannerPreview(null);
    setError(null);
    setIsOpen(true);
  };

  const handleOpenEdit = (event: GraduationEvent) => {
    setIsEdit(true);
    setForm(event);
    setBannerFile(null);
    setBannerPreview(null);
    setError(null);
    setIsOpen(true);
  };

  const handleBannerChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError("Ukuran banner maksimal 2MB");
      return;
    }
    setBannerFile(file);
    setBannerPreview(URL.createObjectURL(file));
    setError(null);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.pesantrenId) return;
    if (!form.title.trim()) {
      setError("Nama agenda wajib diisi");
      return;
    }
    if (!form.year.trim()) {
      setError("Tahun wisuda wajib diisi");
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const docId = form.id || doc(collection(db, "pesantren", profile.pesantrenId, "graduation_events")).id;
      let finalBannerPath = form.bannerPath;
      if (bannerFile) {
        const bannerRef = ref(storage, `graduation_banners/${docId}.jpg`);
        const uploaded = await uploadBytes(bannerRef, bannerFile);
        finalBannerPath = await getDownloadURL(uploaded.ref);
      }

      await setDoc(
        doc(db, "pesantren", profile.pesantrenId, "graduation_events", docId),
        {
          id: docId,
          title: form.title.trim(),
          year: form.year.trim(),
          examStartDate: form.examStartDate || null,
          examEndDate: form.examEndDate || null,
          graduationDate: form.graduationDate || null,
          method: form.method,
          sessionsCount: form.method === "Tasmi' Sekali Duduk" ? 1 : Number(form.sessionsCount || 1),
          requirements: form.requirements.trim(),
          description: form.description.trim(),
          status: form.status,
          isPublished: form.isPublished,
          isCertificatesReleased: form.isCertificatesReleased,
          registrationFee: Number(form.registrationFee || 0),
          graduationFee: Number(form.graduationFee || 0),
          bannerPath: finalBannerPath || null,
        },
        { merge: true }
      );

      setIsOpen(false);
      load();
    } catch (err: any) {
      console.error(err);
      setError(`Gagal menyimpan: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (eventId: string) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm("Hapus agenda wisuda ini?")) return;
    try {
      await deleteDoc(doc(db, "pesantren", profile.pesantrenId, "graduation_events", eventId));
      load();
    } catch (err) {
      console.error(err);
      alert("Gagal menghapus agenda wisuda");
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
      <PageMeta title="Manajemen Wisuda | TahfidzMU Admin" description="Kelola agenda wisuda dan ujian tasmi'." />
      <div className="space-y-6">
        <div className="overflow-hidden rounded-[28px] bg-gradient-to-r from-brand-700 via-brand-600 to-emerald-500 text-white shadow-sm">
          <div className="grid gap-6 px-6 py-7 lg:grid-cols-[minmax(0,1.5fr)_minmax(280px,0.8fr)] lg:px-8">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.18em]">
                <GraduationCap size={14} /> Manajemen Wisuda
              </div>
              <h2 className="mt-4 text-2xl font-bold md:text-3xl">Kelola haflah, pendaftar, biaya, dan publikasi dalam satu halaman</h2>
              <p className="mt-3 max-w-2xl text-sm text-white/80 md:text-base">Banner wisuda sekarang jadi pengantar utama. Admin bisa langsung melihat gambaran agenda aktif, lalu turun ke kartu ringkasan dan daftar peserta di bawahnya.</p>
            </div>
            <div className="flex flex-col justify-between gap-4 rounded-3xl border border-white/15 bg-black/10 p-5 backdrop-blur-sm">
              <div>
                <div className="text-xs font-bold uppercase tracking-[0.18em] text-white/70">Status Saat Ini</div>
                <div className="mt-2 text-lg font-semibold">{events.length === 0 ? "Belum ada agenda aktif" : `${publishedCount} agenda sudah dipublikasikan`}</div>
                <p className="mt-2 text-sm text-white/75">{events.length === 0 ? "Mulai dari membuat agenda pertama agar santri dan wali bisa melihat jadwal wisuda di aplikasi." : `${registrations.length} pendaftaran wisuda sudah tercatat dan siap dikelola.`}</p>
              </div>
              <button onClick={handleOpenAdd} className="inline-flex items-center justify-center gap-2 rounded-xl bg-white px-4 py-2.5 text-sm font-semibold text-brand-700 transition hover:bg-white/90">
                <Plus size={18} /> Tambah Agenda
              </button>
            </div>
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <div className="rounded-2xl border border-sky-200 bg-gradient-to-br from-sky-50 to-white p-5 dark:border-sky-500/20 dark:bg-sky-500/10">
            <div className="text-xs font-bold uppercase tracking-[0.18em] text-sky-600 dark:text-sky-300">Total Agenda</div>
            <div className="mt-3 text-3xl font-bold text-sky-950 dark:text-white">{events.length}</div>
            <div className="mt-1 text-sm text-sky-700/80 dark:text-sky-100/75">Agenda wisuda tersimpan</div>
          </div>
          <div className="rounded-2xl border border-emerald-200 bg-gradient-to-br from-emerald-50 to-white p-5 dark:border-emerald-500/20 dark:bg-emerald-500/10">
            <div className="text-xs font-bold uppercase tracking-[0.18em] text-emerald-600 dark:text-emerald-300">Dipublikasikan</div>
            <div className="mt-3 text-3xl font-bold text-emerald-950 dark:text-white">{publishedCount}</div>
            <div className="mt-1 text-sm text-emerald-700/80 dark:text-emerald-100/75">Tampil di aplikasi santri dan wali</div>
          </div>
          <div className="rounded-2xl border border-amber-200 bg-gradient-to-br from-amber-50 to-white p-5 dark:border-amber-500/20 dark:bg-amber-500/10">
            <div className="text-xs font-bold uppercase tracking-[0.18em] text-amber-600 dark:text-amber-300">Pendaftar</div>
            <div className="mt-3 text-3xl font-bold text-amber-950 dark:text-white">{registrations.length}</div>
            <div className="mt-1 text-sm text-amber-700/80 dark:text-amber-100/75">{acceptedCount} santri sudah diterima</div>
          </div>
          <div className="rounded-2xl border border-fuchsia-200 bg-gradient-to-br from-fuchsia-50 to-white p-5 dark:border-fuchsia-500/20 dark:bg-fuchsia-500/10">
            <div className="text-xs font-bold uppercase tracking-[0.18em] text-fuchsia-600 dark:text-fuchsia-300">Sertifikat</div>
            <div className="mt-3 text-3xl font-bold text-fuchsia-950 dark:text-white">{releasedCertificatesCount}</div>
            <div className="mt-1 text-sm text-fuchsia-700/80 dark:text-fuchsia-100/75">Agenda dengan sertifikat digital aktif</div>
          </div>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari agenda wisuda..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-11 pr-4 focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-800 dark:bg-white/[0.03] dark:text-white" />
        </div>

        {loading ? (
          <div className="flex min-h-[200px] items-center justify-center"><div className="h-8 w-8 animate-spin rounded-full border-3 border-brand-500 border-t-transparent"></div></div>
        ) : filtered.length === 0 ? (
          <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
            <div className="grid gap-4 p-6 lg:grid-cols-3">
              <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5 dark:border-brand-500/20 dark:bg-brand-500/10">
                <div className="text-sm font-bold text-gray-900 dark:text-white">1. Siapkan jadwal</div>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">Isi nama agenda, tahun, metode tasmi', tanggal ujian, dan hari wisuda.</p>
              </div>
              <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5 dark:border-emerald-500/20 dark:bg-emerald-500/10">
                <div className="text-sm font-bold text-gray-900 dark:text-white">2. Publikasikan ke aplikasi</div>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">Aktifkan publikasi agar santri dan wali langsung melihat informasi wisuda dari aplikasi.</p>
              </div>
              <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5 dark:border-amber-500/20 dark:bg-amber-500/10">
                <div className="text-sm font-bold text-gray-900 dark:text-white">3. Kelola pendaftar</div>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">Setelah santri mendaftar, status peserta dan pembayaran akan muncul otomatis di halaman ini.</p>
              </div>
            </div>
            <div className="border-t border-gray-100 px-6 py-4 text-sm text-gray-500 dark:border-gray-800 dark:text-gray-400">
              Saat ini ada {santriList.length} santri di database dan {registrations.length} pendaftaran wisuda tercatat.
            </div>
          </div>
        ) : (
          <div className="grid gap-4 lg:grid-cols-2">
            {filtered.map((event) => (
              <div key={event.id} className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
                {event.bannerPath ? <img src={event.bannerPath} alt={event.title} className="h-36 w-full object-cover" /> : <div className="flex h-36 items-center justify-center bg-brand-50 text-brand-500 dark:bg-brand-500/10"><GraduationCap size={42} /></div>}
                <div className="p-5">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="text-lg font-bold text-gray-800 dark:text-white">{event.title}</h3>
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">Tahun {event.year} • {event.method}</p>
                    </div>
                    <div className="flex gap-1">
                      <button onClick={() => handleOpenEdit(event)} className="p-1 text-gray-400 hover:text-blue-600"><Edit2 size={14} /></button>
                      <button onClick={() => handleDelete(event.id)} className="p-1 text-gray-400 hover:text-error-500"><Trash2 size={14} /></button>
                    </div>
                  </div>
                  <div className="mt-4 grid gap-3 text-sm text-gray-600 dark:text-gray-300 sm:grid-cols-2">
                    <div className="rounded-xl bg-gray-50 px-3 py-2 dark:bg-white/5">
                      <div className="text-[11px] uppercase text-gray-400">Mulai Ujian</div>
                      <div className="mt-1 font-semibold">{formatDateLabel(event.examStartDate)}</div>
                    </div>
                    <div className="rounded-xl bg-gray-50 px-3 py-2 dark:bg-white/5">
                      <div className="text-[11px] uppercase text-gray-400">Hari Wisuda</div>
                      <div className="mt-1 font-semibold">{formatDateLabel(event.graduationDate)}</div>
                    </div>
                    <div className="rounded-xl bg-gray-50 px-3 py-2 dark:bg-white/5">
                      <div className="text-[11px] uppercase text-gray-400">Sesi</div>
                      <div className="mt-1 font-semibold">{event.sessionsCount} kali duduk</div>
                    </div>
                    <div className="rounded-xl bg-gray-50 px-3 py-2 dark:bg-white/5">
                      <div className="text-[11px] uppercase text-gray-400">Status</div>
                      <div className="mt-1 font-semibold">{event.status}</div>
                    </div>
                  </div>

                  <div className="mt-5 border-t border-gray-100 pt-5 dark:border-gray-800">
                    <div className="mb-3 flex items-center justify-between">
                      <h4 className="text-sm font-bold text-gray-800 dark:text-white">Pendaftaran Wisuda</h4>
                      <span className="rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-bold text-brand-500 dark:bg-brand-500/10">{getEventRegistrations(event.id).length} santri</span>
                    </div>
                    {getEventRegistrations(event.id).length === 0 ? (
                      <div className="rounded-xl bg-gray-50 px-4 py-3 text-sm text-gray-500 dark:bg-white/5 dark:text-gray-400">Belum ada pendaftar.</div>
                    ) : (
                      <div className="space-y-3">
                        {getEventRegistrations(event.id).map((registration) => {
                          const santri = getSantri(registration.santriId);
                          return (
                            <div key={registration.id} className="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
                              <div className="flex items-start gap-3">
                                {santri?.photoPath ? (
                                  <img src={santri.photoPath} alt={santri.name} className="h-11 w-11 rounded-full object-cover" />
                                ) : (
                                  <div className="flex h-11 w-11 items-center justify-center rounded-full bg-brand-50 font-bold text-brand-500 dark:bg-brand-500/10">
                                    {(santri?.name || "S").charAt(0).toUpperCase()}
                                  </div>
                                )}
                                <div className="min-w-0 flex-1">
                                  <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                                    <div>
                                      <div className="truncate font-semibold text-gray-900 dark:text-white">{santri?.name || registration.santriId}</div>
                                      <div className="text-xs text-gray-500 dark:text-gray-400">NIS: {santri?.nis || "-"} • Daftar: {formatDateLabel(registration.registrationDate)}</div>
                                    </div>
                                    <div className="text-xs text-gray-500 dark:text-gray-400">Oleh: {registration.registeredBy}</div>
                                  </div>
                                  <div className="mt-3 grid gap-3 md:grid-cols-3">
                                    <div>
                                      <label className={labelCls}>Status Peserta</label>
                                      <select value={registration.status} onChange={(e) => updateRegistrationField(registration, { status: e.target.value as GraduationRegistration["status"] })} className={inputCls}>
                                        <option value="menunggu">menunggu</option>
                                        <option value="diterima">diterima</option>
                                        <option value="ditolak">ditolak</option>
                                      </select>
                                    </div>
                                    <div>
                                      <label className={labelCls}>Bayar Daftar</label>
                                      <select value={registration.registrationPaymentStatus} onChange={(e) => updateRegistrationField(registration, { registrationPaymentStatus: e.target.value as GraduationRegistration["registrationPaymentStatus"] })} className={inputCls}>
                                        <option value="belumBayar">belumBayar</option>
                                        <option value="lunas">lunas</option>
                                      </select>
                                    </div>
                                    <div>
                                      <label className={labelCls}>Bayar Wisuda</label>
                                      <select value={registration.graduationPaymentStatus} onChange={(e) => updateRegistrationField(registration, { graduationPaymentStatus: e.target.value as GraduationRegistration["graduationPaymentStatus"] })} className={inputCls}>
                                        <option value="belumBayar">belumBayar</option>
                                        <option value="lunas">lunas</option>
                                      </select>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <h3 className="mb-4 text-lg font-bold text-gray-800 dark:text-white">{isEdit ? "Edit Agenda Wisuda" : "Tambah Agenda Wisuda"}</h3>
            {error && <div className="mb-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-5">
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="Nama Agenda / Haflah *">
                  <input value={form.title} onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))} className={inputCls} placeholder="Contoh: Wisuda Tahfidz 2027" />
                </Field>
                <Field label="Tahun *">
                  <input value={form.year} onChange={(e) => setForm((prev) => ({ ...prev, year: e.target.value }))} className={inputCls} placeholder="2027" />
                </Field>
                <Field label="Metode Ujian">
                  <select value={form.method} onChange={(e) => setForm((prev) => ({ ...prev, method: e.target.value, sessionsCount: e.target.value === "Tasmi' Sekali Duduk" ? 1 : prev.sessionsCount }))} className={inputCls}>
                    <option value="Tasmi' Sekali Duduk">Tasmi' Sekali Duduk</option>
                    <option value="Tasmi' Bertahap">Tasmi' Bertahap</option>
                    <option value="Sima'an Umum">Sima'an Umum</option>
                  </select>
                </Field>
                <Field label="Jumlah Sesi">
                  <input type="number" min={1} value={form.sessionsCount} onChange={(e) => setForm((prev) => ({ ...prev, sessionsCount: Number(e.target.value || 1) }))} disabled={form.method === "Tasmi' Sekali Duduk"} className={`${inputCls} disabled:opacity-60`} />
                </Field>
                <Field label="Mulai Ujian">
                  <input type="date" value={form.examStartDate ? form.examStartDate.slice(0, 10) : ""} onChange={(e) => setForm((prev) => ({ ...prev, examStartDate: e.target.value ? new Date(e.target.value).toISOString() : null }))} className={inputCls} />
                </Field>
                <Field label="Selesai Ujian">
                  <input type="date" value={form.examEndDate ? form.examEndDate.slice(0, 10) : ""} onChange={(e) => setForm((prev) => ({ ...prev, examEndDate: e.target.value ? new Date(e.target.value).toISOString() : null }))} className={inputCls} />
                </Field>
                <Field label="Tanggal Wisuda">
                  <div className="relative">
                    <CalendarDays size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input type="date" value={form.graduationDate ? form.graduationDate.slice(0, 10) : ""} onChange={(e) => setForm((prev) => ({ ...prev, graduationDate: e.target.value ? new Date(e.target.value).toISOString() : null }))} className={`${inputCls} pl-10`} />
                  </div>
                </Field>
                <Field label="Status">
                  <select value={form.status} onChange={(e) => setForm((prev) => ({ ...prev, status: e.target.value }))} className={inputCls}>
                    <option value="upcoming">upcoming</option>
                    <option value="ongoing">ongoing</option>
                    <option value="completed">completed</option>
                  </select>
                </Field>
                <Field label="Biaya Daftar">
                  <input type="number" min={0} value={form.registrationFee} onChange={(e) => setForm((prev) => ({ ...prev, registrationFee: Number(e.target.value || 0) }))} className={inputCls} />
                </Field>
                <Field label="Biaya Wisuda">
                  <input type="number" min={0} value={form.graduationFee} onChange={(e) => setForm((prev) => ({ ...prev, graduationFee: Number(e.target.value || 0) }))} className={inputCls} />
                </Field>
                <div className="md:col-span-2">
                  <Field label="Syarat Kelulusan">
                    <textarea rows={2} value={form.requirements} onChange={(e) => setForm((prev) => ({ ...prev, requirements: e.target.value }))} className={inputCls} placeholder="Misal: Minimal 2 juz mutqin" />
                  </Field>
                </div>
                <div className="md:col-span-2">
                  <Field label="Pengumuman / Deskripsi">
                    <textarea rows={4} value={form.description} onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))} className={inputCls} placeholder="Tuliskan informasi wisuda untuk santri dan wali." />
                  </Field>
                </div>
              </div>

              <div className="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
                <label className={labelCls}>Banner Popup Motivasi</label>
                <div className="flex flex-col gap-3 md:flex-row md:items-center">
                  {(bannerPreview || form.bannerPath) ? (
                    <div className="relative">
                      <img src={bannerPreview || form.bannerPath || ""} alt="Banner wisuda" className="h-28 w-44 rounded-xl border border-gray-200 object-cover dark:border-gray-700" />
                      <button type="button" onClick={() => { setBannerFile(null); setBannerPreview(null); setForm((prev) => ({ ...prev, bannerPath: null })); }} className="absolute -right-2 -top-2 rounded-full bg-error-500 p-1 text-white"><X size={12} /></button>
                    </div>
                  ) : (
                    <div className="flex h-28 w-44 items-center justify-center rounded-xl bg-brand-50 text-brand-500 dark:bg-brand-500/10"><GraduationCap size={34} /></div>
                  )}
                  <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-50 px-3 py-2 text-xs font-bold text-brand-500 hover:bg-brand-100 dark:bg-brand-500/10">
                    <Upload size={14} /> Pilih Banner
                    <input type="file" accept="image/*" onChange={handleBannerChange} className="hidden" />
                  </label>
                </div>
              </div>

              <div className="grid gap-3 md:grid-cols-2">
                <label className="flex items-center justify-between rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-white/5">
                  <div>
                    <div className="font-semibold text-gray-800 dark:text-white">Publikasikan di aplikasi</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">Jika aktif, agenda tampil untuk santri dan wali.</div>
                  </div>
                  <input type="checkbox" checked={form.isPublished} onChange={(e) => setForm((prev) => ({ ...prev, isPublished: e.target.checked }))} className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500" />
                </label>
                <label className="flex items-center justify-between rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-white/5">
                  <div>
                    <div className="font-semibold text-gray-800 dark:text-white">Bagikan sertifikat digital</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">Jika aktif, sertifikat boleh diunduh dari aplikasi.</div>
                  </div>
                  <input type="checkbox" checked={form.isCertificatesReleased} onChange={(e) => setForm((prev) => ({ ...prev, isCertificatesReleased: e.target.checked }))} className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500" />
                </label>
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button type="button" onClick={() => setIsOpen(false)} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Batal</button>
                <button type="submit" disabled={saving} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"><Save size={14} /> {saving ? "Menyimpan..." : "Simpan"}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}