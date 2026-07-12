import { useEffect, useState } from "react";
import { Timestamp, collection, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { AlertCircle, Building2, CalendarClock, CheckCircle2, Filter, Globe, Mail, Phone, Plus, Save, Search, ShieldAlert, X } from "lucide-react";
import { useNavigate } from "react-router";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";

type TenantStatus = "active" | "suspended";
type TenantFilter = "all" | TenantStatus | "expired";
type SubscriptionTier = "Trial" | "Premium Bulanan" | "Premium Tahunan";
type ModuleKey = "quran" | "hadits" | "tajwid" | "tahsin" | "pondok_info" | "graduation";
const drawerTabs = [
  { key: "profil", label: "Profil" },
  { key: "akses", label: "Akses" },
  { key: "modul", label: "Modul" },
  { key: "branding", label: "Branding" },
] as const;

type DrawerTabKey = (typeof drawerTabs)[number]["key"];

type TenantItem = {
  id: string;
  nama: string;
  status: TenantStatus;
  subscriptionTier: SubscriptionTier;
  activeUntil: Date | null;
  logoUrl: string;
  alamat: string;
  email: string;
  noTelp: string;
  npsn: string;
  website: string;
  pimpinan: string;
  moduleCount: number;
  activeModules: ModuleKey[];
  adminLoginKey: string;
};

type TenantForm = {
  nama: string;
  email: string;
  noTelp: string;
  alamat: string;
  npsn: string;
  website: string;
  pimpinan: string;
  adminPassword: string;
  subscriptionTier: SubscriptionTier;
  status: TenantStatus;
  activeUntil: string;
  logoUrl: string;
  activeModules: ModuleKey[];
};

const defaultModules: ModuleKey[] = ["quran", "hadits", "tajwid", "tahsin", "pondok_info", "graduation"];

const moduleOptions: Array<{ key: ModuleKey; title: string; description: string; locked?: boolean }> = [
  { key: "quran", title: "Quran", description: "Setoran dan hafalan Al-Quran.", locked: true },
  { key: "hadits", title: "Hadits", description: "Hafalan hadits pilihan." },
  { key: "tajwid", title: "Tajwid", description: "Materi hukum bacaan dan evaluasi." },
  { key: "tahsin", title: "Tahsin", description: "Perbaikan bacaan dan makharijul huruf." },
  { key: "pondok_info", title: "Pengetahuan Pondok", description: "Materi pengetahuan pondok yang perlu dihafal." },
  { key: "graduation", title: "Wisuda", description: "Ujian tasmi' dan wisuda." },
];

const emptyForm: TenantForm = {
  nama: "",
  email: "",
  noTelp: "",
  alamat: "",
  npsn: "",
  website: "",
  pimpinan: "",
  adminPassword: "",
  subscriptionTier: "Trial",
  status: "active",
  activeUntil: toDateInputValue(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)),
  logoUrl: "",
  activeModules: defaultModules,
};

function toDateInputValue(date: Date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatDisplayDate(date: Date | null) {
  if (!date) return "Belum diatur";
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(date);
}

function normalizeNpsn(value: string) {
  return value.replace(/\D+/g, "").trim();
}

function normalizeModules(value: unknown): ModuleKey[] {
  if (!Array.isArray(value)) return ["quran"];
  const next = value.filter((item): item is ModuleKey => typeof item === "string" && moduleOptions.some((option) => option.key === item));
  return Array.from(new Set(["quran", ...next]));
}

export default function SuperAdminPesantrenPage() {
  const { profile, switchToTenantAdmin } = useAuth();
  const navigate = useNavigate();
  const [items, setItems] = useState<TenantItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<TenantFilter>("all");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [activeDrawerTab, setActiveDrawerTab] = useState<DrawerTabKey>("profil");
  const [mode, setMode] = useState<"create" | "edit">("create");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [form, setForm] = useState<TenantForm>(emptyForm);
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.role === "superAdmin") {
      void loadPesantren();
      return;
    }

    setLoading(false);
  }, [profile?.role]);

  async function loadPesantren() {
    setLoading(true);
    setError(null);

    try {
      const snap = await getDocs(collection(db, "pesantren"));
      const nextItems = await Promise.all(
        snap.docs.map(async (item) => {
          const data = item.data() as Record<string, unknown>;
          const [infoSnap, modulesSnap] = await Promise.all([
            getDoc(doc(db, "pesantren", item.id, "settings", "pesantren_info")),
            getDoc(doc(db, "pesantren", item.id, "settings", "modules")),
          ]);

          const info = infoSnap.exists() ? (infoSnap.data() as Record<string, unknown>) : {};
          const activeUntilRaw = data.activeUntil;
          const activeUntil = activeUntilRaw instanceof Timestamp ? activeUntilRaw.toDate() : null;
          const activeModules = normalizeModules(modulesSnap.data()?.active);

          return {
            id: item.id,
            nama: String(data.nama || info.nama || item.id),
            status: data.status === "suspended" ? "suspended" : "active",
            subscriptionTier:
              data.subscriptionTier === "Premium Bulanan" || data.subscriptionTier === "Premium Tahunan"
                ? data.subscriptionTier
                : "Trial",
            activeUntil,
            logoUrl: String(data.logoUrl || info.logoPath || ""),
            alamat: String(info.alamat || ""),
            email: String(info.email || ""),
            noTelp: String(info.noTelp || ""),
            npsn: String(info.npsn || ""),
            website: String(info.website || ""),
            pimpinan: String(info.pimpinan || ""),
            moduleCount: activeModules.length || 1,
            activeModules,
            adminLoginKey: "admin",
          } satisfies TenantItem;
        })
      );

      nextItems.sort((left, right) => left.nama.localeCompare(right.nama, "id", { sensitivity: "base" }));
      setItems(nextItems);
    } catch (err) {
      console.error(err);
      setError("Gagal memuat daftar pesantren.");
    } finally {
      setLoading(false);
    }
  }

  function openCreateDrawer() {
    setMode("create");
    setSelectedId(null);
    setForm(emptyForm);
    setLogoFile(null);
    setLogoPreview(null);
    setError(null);
    setActiveDrawerTab("profil");
    setDrawerOpen(true);
  }

  function openEditDrawer(item: TenantItem) {
    setMode("edit");
    setSelectedId(item.id);
    setForm({
      nama: item.nama,
      email: item.email,
      noTelp: item.noTelp,
      alamat: item.alamat,
      npsn: item.npsn,
      website: item.website,
      pimpinan: item.pimpinan,
      subscriptionTier: item.subscriptionTier,
      status: item.status,
      activeUntil: toDateInputValue(item.activeUntil ?? new Date()),
      logoUrl: item.logoUrl,
      activeModules: item.activeModules,
      adminPassword: "",
    });
    setLogoFile(null);
    setLogoPreview(null);
    setError(null);
    setActiveDrawerTab("profil");
    setDrawerOpen(true);
  }

  function closeDrawer() {
    setDrawerOpen(false);
    setSaving(false);
    setError(null);
    setLogoFile(null);
    setLogoPreview(null);
  }

  function handleLogoChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError("Ukuran logo maksimal 2MB.");
      return;
    }

    setLogoFile(file);
    setLogoPreview(URL.createObjectURL(file));
    setError(null);
  }

  async function uploadLogo(code: string) {
    if (!logoFile) return form.logoUrl.trim();
    const logoRef = ref(storage, `pesantren_logos/${code}.jpg`);
    const uploaded = await uploadBytes(logoRef, logoFile);
    return getDownloadURL(uploaded.ref);
  }

  function toggleModule(key: ModuleKey) {
    if (key === "quran") return;
    setForm((current) => ({
      ...current,
      activeModules: current.activeModules.includes(key)
        ? current.activeModules.filter((item) => item !== key)
        : [...current.activeModules, key],
    }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const npsn = normalizeNpsn(form.npsn);
    const tenantId = mode === "edit" && selectedId ? selectedId : npsn;
    if (!form.nama.trim()) {
      setError("Nama pesantren wajib diisi.");
      return;
    }
    if (!npsn) {
      setError("NPSN wajib diisi.");
      return;
    }
    if (mode === "create" && !form.adminPassword.trim()) {
      setError("Password admin awal wajib diisi.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const finalLogoUrl = await uploadLogo(tenantId);
      const rootRef = doc(db, "pesantren", tenantId);
      const infoRef = doc(rootRef, "settings", "pesantren_info");
      const modulesRef = doc(rootRef, "settings", "modules");
      const mappingRef = doc(rootRef, "user_mappings", "admin");
      const activeModules = normalizeModules(form.activeModules);

      if (mode === "create") {
        const existing = await getDoc(rootRef);
        if (existing.exists()) {
          setError("NPSN sudah dipakai. Gunakan NPSN lain.");
          setSaving(false);
          return;
        }

        await setDoc(rootRef, {
          id: tenantId,
          nama: form.nama.trim(),
          createdAt: serverTimestamp(),
          status: form.status,
          logoUrl: finalLogoUrl || null,
          subscriptionTier: form.subscriptionTier,
          activeUntil: Timestamp.fromDate(new Date(form.activeUntil)),
        });

        await setDoc(infoRef, {
          nama: form.nama.trim(),
          alamat: form.alamat.trim() || "Alamat belum diatur",
          noTelp: form.noTelp.trim() || "-",
          email: form.email.trim(),
          npsn,
          website: form.website.trim(),
          pimpinan: form.pimpinan.trim(),
          logoPath: finalLogoUrl || "",
        });

        await setDoc(modulesRef, { active: activeModules }, { merge: true });
        await setDoc(mappingRef, {
          linkedId: null,
          role: "admin",
          defaultPassword: form.adminPassword.trim(),
        });
      } else {
        await updateDoc(rootRef, {
          nama: form.nama.trim(),
          status: form.status,
          subscriptionTier: form.subscriptionTier,
          activeUntil: Timestamp.fromDate(new Date(form.activeUntil)),
          ...(finalLogoUrl ? { logoUrl: finalLogoUrl } : {}),
        });

        await setDoc(
          infoRef,
          {
            nama: form.nama.trim(),
            alamat: form.alamat.trim(),
            noTelp: form.noTelp.trim(),
            email: form.email.trim(),
            npsn,
            website: form.website.trim(),
            pimpinan: form.pimpinan.trim(),
            ...(finalLogoUrl ? { logoPath: finalLogoUrl } : {}),
          },
          { merge: true }
        );

        await setDoc(modulesRef, { active: activeModules }, { merge: true });

        if (form.adminPassword.trim()) {
          await setDoc(
            mappingRef,
            {
              linkedId: null,
              role: "admin",
              defaultPassword: form.adminPassword.trim(),
            },
            { merge: true }
          );
        }
      }

      closeDrawer();
      await loadPesantren();
    } catch (err) {
      console.error(err);
      setError("Gagal menyimpan data pesantren.");
      setSaving(false);
    }
  }

  async function toggleStatus(item: TenantItem) {
    const nextStatus: TenantStatus = item.status === "active" ? "suspended" : "active";
    setSaving(true);
    try {
      const payload: { status: TenantStatus; activeUntil?: Timestamp } = { status: nextStatus };

      // Re-activating an expired tenant must also restore a valid activeUntil date,
      // otherwise tenant login still fails on the subscription expiry guard.
      if (nextStatus === "active" && (!item.activeUntil || item.activeUntil.getTime() < Date.now())) {
        const confirmed = window.confirm(`Pesantren ${item.nama} sudah melewati masa aktif. Aktifkan kembali sekaligus pulihkan masa aktif 30 hari ke depan?`);
        if (!confirmed) {
          setSaving(false);
          return;
        }
        payload.activeUntil = Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));
      }

      await updateDoc(doc(db, "pesantren", item.id), payload);
      await loadPesantren();
    } catch (err) {
      console.error(err);
      setError("Gagal memperbarui status akses.");
    } finally {
      setSaving(false);
    }
  }

  async function extendThirtyDays(item: TenantItem) {
    setSaving(true);
    try {
      const baseDate = item.activeUntil && item.activeUntil.getTime() > Date.now() ? item.activeUntil : new Date();
      const nextDate = new Date(baseDate.getTime() + 30 * 24 * 60 * 60 * 1000);

      await updateDoc(doc(db, "pesantren", item.id), {
        status: "active",
        activeUntil: Timestamp.fromDate(nextDate),
      });
      await loadPesantren();
    } catch (err) {
      console.error(err);
      setError("Gagal memperpanjang masa aktif.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDeletePesantren(item: TenantItem) {
    if (item.id === "demo") {
       const confirmDemo = window.confirm("Anda akan menghapus pesantren DEMO. Ini adalah tindakan permanen. Lanjutkan?");
       if (!confirmDemo) return;
    } else {
       const confirm = window.confirm(`Hapus pesantren ${item.nama} (${item.id}) secara permanen? Seluruh data santri, musyrif, dan riwayat akan hilang.`);
       if (!confirm) return;
    }

    const finalConfirm = prompt("Ketik ID pesantren (" + item.id + ") untuk mengonfirmasi penghapusan:");
    if (finalConfirm !== item.id) {
      alert("Konfirmasi gagal. Penghapusan dibatalkan.");
      return;
    }

    setSaving(true);
    try {
      // 1. Delete all subcollections and their nested subcollections
      const collectionsList = ["santri", "musyrif", "halaqah", "kelas", "graduation_events", "graduation_registrations", "user_mappings", "presensi", "active_sessions"];

      for (const col of collectionsList) {
        const snap = await getDocs(collection(db, "pesantren", item.id, col));

        for (const parentDoc of snap.docs) {
          // If it's the santri collection, we must delete nested history
          if (col === "santri") {
            const subCols = ["setoranHistory", "tasmiHistory"];
            for (const sub of subCols) {
              const subSnap = await getDocs(collection(db, "pesantren", item.id, col, parentDoc.id, sub));
              await Promise.all(subSnap.docs.map((d) => deleteDoc(d.ref)));
            }
          }
          // Now delete the parent document
          await deleteDoc(parentDoc.ref);
        }
      }

      // 2. Delete settings folder contents
      const settingsSnap = await getDocs(collection(db, "pesantren", item.id, "settings"));
      await Promise.all(settingsSnap.docs.map((doc) => deleteDoc(doc.ref)));

      // 3. Delete the root document itself (The "Card" identity)
      await deleteDoc(doc(db, "pesantren", item.id));

      alert(`Pesantren ${item.id} berhasil dihapus total dari sistem.`);
      await loadPesantren();
    } catch (err: any) {
      console.error(err);
      setError(`Gagal menghapus pesantren: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  }

  function handleEnterTenant(item: TenantItem) {
    switchToTenantAdmin(item.id);
    navigate("/");
  }

  const filteredItems = items.filter((item) => {
    const matchesQuery = !query.trim() || item.nama.toLowerCase().includes(query.toLowerCase()) || item.npsn.toLowerCase().includes(query.toLowerCase());
    const matchesStatus =
      statusFilter === "all"
        ? true
        : statusFilter === "expired"
        ? isExpired(item.activeUntil)
        : item.status === statusFilter;
    return matchesQuery && matchesStatus;
  });

  const activeCount = items.filter((item) => item.status === "active").length;
  const suspendedCount = items.filter((item) => item.status === "suspended").length;

  if (profile?.role !== "superAdmin") {
    return (
      <div className="flex min-h-[420px] flex-col items-center justify-center rounded-2xl border border-gray-200 bg-white p-6 text-center dark:border-gray-800 dark:bg-white/[0.03]">
        <ShieldAlert size={48} className="mb-4 text-error-500" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="mt-2 max-w-md text-sm text-gray-500 dark:text-gray-400">Halaman ini khusus untuk super admin yang mengelola banyak pesantren dari satu panel pusat.</p>
      </div>
    );
  }

  return (
    <>
      <PageMeta title="Pesantren | TahfidzMU Super Admin" description="Kelola daftar pesantren, masa aktif, dan paket langganan." />
      <div className="space-y-6">
        <div className="overflow-hidden rounded-3xl bg-gradient-to-br from-slate-950 via-emerald-950 to-teal-900 p-6 text-white shadow-sm">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.18em] text-white/90">
                <Building2 size={14} /> Super Admin
              </div>
              <h2 className="mt-4 text-2xl font-bold md:text-3xl">Daftar Pesantren</h2>
              <p className="mt-2 max-w-2xl text-sm text-white/85">Kelola identitas pesantren, status akses, paket langganan, dan data kontak dari satu tempat yang lebih praktis.</p>
            </div>

            <button
              type="button"
              onClick={openCreateDrawer}
              className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-4 py-3 text-sm font-bold text-emerald-700 transition hover:bg-emerald-50"
            >
              <Plus size={18} /> Tambah Pesantren
            </button>
          </div>

          <div className="mt-6 grid gap-3 md:grid-cols-3">
            <div className="rounded-2xl bg-white/12 p-4 backdrop-blur-sm">
              <div className="text-xs uppercase text-white/70">Total Pesantren</div>
              <div className="mt-2 text-3xl font-bold">{items.length}</div>
            </div>
            <div className="rounded-2xl bg-white/12 p-4 backdrop-blur-sm">
              <div className="text-xs uppercase text-white/70">Akses Aktif</div>
              <div className="mt-2 text-3xl font-bold">{activeCount}</div>
            </div>
            <div className="rounded-2xl bg-white/12 p-4 backdrop-blur-sm">
              <div className="text-xs uppercase text-white/70">Ditangguhkan</div>
              <div className="mt-2 text-3xl font-bold">{suspendedCount}</div>
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
          <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
            <div className="relative flex-1">
              <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Cari nama atau NPSN"
                className="w-full rounded-2xl border border-gray-200 bg-gray-50 py-3 pl-10 pr-4 text-sm text-gray-800 focus:border-brand-500 focus:outline-none dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
            </div>

            <div className="flex items-center gap-2 rounded-2xl border border-gray-200 px-3 py-2 text-sm dark:border-gray-700">
              <Filter size={16} className="text-gray-400" />
              <select
                value={statusFilter}
                onChange={(event) => setStatusFilter(event.target.value as TenantFilter)}
                className="bg-transparent text-sm text-gray-700 outline-none dark:text-gray-200"
              >
                <option value="all">Semua Status</option>
                <option value="active">Aktif</option>
                <option value="suspended">Ditangguhkan</option>
                <option value="expired">Expired</option>
              </select>
            </div>
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-3 rounded-2xl border border-error-100 bg-error-50 p-4 text-sm text-error-700 dark:border-error-500/20 dark:bg-error-500/10 dark:text-error-400">
            <AlertCircle size={18} className="mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {loading ? (
          <div className="flex min-h-[260px] items-center justify-center rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
            <div className="h-9 w-9 animate-spin rounded-full border-4 border-brand-500 border-t-transparent"></div>
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-gray-300 bg-white p-10 text-center dark:border-gray-700 dark:bg-white/[0.03]">
            <Building2 size={34} className="mx-auto text-gray-300" />
            <h3 className="mt-4 text-lg font-bold text-gray-800 dark:text-white">Belum ada data yang cocok</h3>
            <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">Ubah kata kunci pencarian atau tambahkan pesantren baru dari tombol di atas.</p>
          </div>
        ) : (
          <div className="grid gap-4 xl:grid-cols-2">
            {filteredItems.map((item) => (
              <article key={item.id} className="rounded-3xl border border-gray-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-gray-800 dark:bg-gray-800/40">
                {isExpired(item.activeUntil) && (
                  <div className="mb-4 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200">
                    <div className="font-semibold">Masa Aktif Habis</div>
                    <div className="mt-1 text-xs">Tenant ini perlu diperpanjang agar login admin dan akses tenant kembali normal.</div>
                  </div>
                )}

                <div className="flex items-start gap-4">
                  {item.logoUrl ? (
                    <img src={item.logoUrl} alt={item.nama} className="h-14 w-14 rounded-2xl border border-gray-200 object-cover dark:border-gray-700" />
                  ) : (
                    <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10">
                      <Building2 size={26} />
                    </div>
                  )}

                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="text-lg font-bold text-gray-900 dark:text-white">{item.nama}</h3>
                      <span className={`rounded-full px-2.5 py-1 text-[11px] font-bold uppercase ${item.status === "active" ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300" : "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300"}`}>
                        {item.status === "active" ? "Aktif" : "Ditangguhkan"}
                      </span>
                    </div>
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">NPSN: {item.npsn || "Belum diatur"}</p>
                  </div>
                </div>

                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                  <div className="rounded-2xl bg-gray-50 p-3 dark:bg-white/5">
                    <div className="text-[11px] uppercase text-gray-400">Paket</div>
                    <div className="mt-1 font-semibold text-gray-800 dark:text-white">{item.subscriptionTier}</div>
                  </div>
                  <div className="rounded-2xl bg-gray-50 p-3 dark:bg-white/5">
                    <div className="text-[11px] uppercase text-gray-400">Masa Aktif</div>
                    <div className="mt-1 font-semibold text-gray-800 dark:text-white">{formatDisplayDate(item.activeUntil)}</div>
                  </div>
                  <div className="rounded-2xl bg-gray-50 p-3 dark:bg-white/5">
                    <div className="text-[11px] uppercase text-gray-400">Kontak</div>
                    <div className="mt-1 text-sm text-gray-700 dark:text-gray-200">{item.email || "Belum diatur"}</div>
                    <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">Login admin tenant: {item.adminLoginKey}</div>
                  </div>
                  <div className="rounded-2xl bg-gray-50 p-3 dark:bg-white/5">
                    <div className="text-[11px] uppercase text-gray-400">Profil Lembaga</div>
                    <div className="mt-1 text-sm text-gray-700 dark:text-gray-200">{item.pimpinan || "Pimpinan belum diatur"}</div>
                    <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">NPSN: {item.npsn || "-"}</div>
                    <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">Website: {item.website || "-"}</div>
                  </div>
                  <div className="rounded-2xl bg-gray-50 p-3 dark:bg-white/5">
                    <div className="text-[11px] uppercase text-gray-400">Modul Aktif</div>
                    <div className="mt-1 font-semibold text-gray-800 dark:text-white">{item.moduleCount}</div>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {item.activeModules.slice(0, 3).map((module) => (
                        <span key={module} className="rounded-full bg-white px-2 py-1 text-[10px] font-bold uppercase tracking-[0.12em] text-gray-500 dark:bg-gray-800 dark:text-gray-300">
                          {module}
                        </span>
                      ))}
                      {item.activeModules.length > 3 && (
                        <span className="rounded-full bg-white px-2 py-1 text-[10px] font-bold uppercase tracking-[0.12em] text-gray-500 dark:bg-gray-800 dark:text-gray-300">
                          +{item.activeModules.length - 3}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="mt-5 flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => handleEnterTenant(item)}
                    className="rounded-xl bg-brand-500 px-3 py-2 text-sm font-semibold text-white hover:bg-brand-600"
                  >
                    Masuk sebagai Admin
                  </button>
                  <button
                    type="button"
                    onClick={() => openEditDrawer(item)}
                    className="rounded-xl border border-gray-200 px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-white/5"
                  >
                    Edit Pesantren
                  </button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={() => void toggleStatus(item)}
                    className="rounded-xl border border-emerald-200 px-3 py-2 text-sm font-semibold text-emerald-700 hover:bg-emerald-50 disabled:opacity-60 dark:border-emerald-500/30 dark:text-emerald-300 dark:hover:bg-emerald-500/10"
                  >
                    {item.status === "active" ? "Tangguhkan" : "Aktifkan"}
                  </button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={() => void extendThirtyDays(item)}
                    className="rounded-xl border border-sky-200 px-3 py-2 text-sm font-semibold text-sky-700 hover:bg-sky-50 disabled:opacity-60 dark:border-sky-500/30 dark:text-sky-300 dark:hover:bg-sky-500/10"
                  >
                    Perpanjang 30 Hari
                  </button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={() => void handleDeletePesantren(item)}
                    className="rounded-xl border border-error-200 px-3 py-2 text-sm font-semibold text-error-700 hover:bg-error-50 disabled:opacity-60 dark:border-error-500/30 dark:text-error-400 dark:hover:bg-error-500/10"
                  >
                    Hapus
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>

      {drawerOpen && (
        <div className="fixed inset-0 z-50 flex justify-end bg-gray-900/50 backdrop-blur-sm">
          <div className="flex h-full w-full max-w-2xl flex-col overflow-y-auto bg-white shadow-2xl dark:bg-gray-900">
            <div className="flex items-start justify-between border-b border-gray-200 px-6 py-5 dark:border-gray-800">
              <div>
                <div className="text-xs font-bold uppercase tracking-[0.16em] text-gray-400">{mode === "create" ? "Tambah" : "Edit"}</div>
                <h3 className="mt-1 text-xl font-bold text-gray-900 dark:text-white">{mode === "create" ? "Pesantren Baru" : "Detail Pesantren"}</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Simpan profil pesantren, kontak, paket, dan status akses dari panel super admin.</p>
              </div>
              <button type="button" onClick={closeDrawer} className="rounded-xl border border-gray-200 p-2 text-gray-500 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="flex flex-1 flex-col">
              <div className="sticky top-0 z-10 border-b border-gray-200 bg-white/95 px-6 py-4 backdrop-blur dark:border-gray-800 dark:bg-gray-900/95">
                <div className="flex flex-wrap gap-2">
                  {drawerTabs.map((tab) => {
                    const active = activeDrawerTab === tab.key;
                    return (
                      <button
                        key={tab.key}
                        type="button"
                        onClick={() => setActiveDrawerTab(tab.key)}
                        className={`rounded-xl px-4 py-2 text-sm font-semibold transition ${active ? "bg-brand-500 text-white shadow-sm" : "border border-gray-200 text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"}`}
                      >
                        {tab.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="space-y-6 px-6 py-6">
                {error && (
                  <div className="flex items-start gap-3 rounded-2xl border border-error-100 bg-error-50 p-4 text-sm text-error-700 dark:border-error-500/20 dark:bg-error-500/10 dark:text-error-400">
                    <AlertCircle size={18} className="mt-0.5" />
                    <span>{error}</span>
                  </div>
                )}

                {activeDrawerTab === "profil" && (
                  <section className="grid gap-4 md:grid-cols-2">
                    <Field label="Nama Pesantren *">
                      <input value={form.nama} onChange={(event) => setForm((current) => ({ ...current, nama: event.target.value }))} className={inputCls} />
                    </Field>
                    <Field label="NPSN">
                      <input value={form.npsn} onChange={(event) => setForm((current) => ({ ...current, npsn: event.target.value }))} className={inputCls} />
                    </Field>
                    <Field label="Kiai / Pimpinan Pondok">
                      <input value={form.pimpinan} onChange={(event) => setForm((current) => ({ ...current, pimpinan: event.target.value }))} className={inputCls} />
                    </Field>
                    <Field label="Email Kontak">
                      <div className="relative">
                        <Mail size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input type="email" value={form.email} onChange={(event) => setForm((current) => ({ ...current, email: event.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <Field label="No. Telp / WhatsApp">
                      <div className="relative">
                        <Phone size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.noTelp} onChange={(event) => setForm((current) => ({ ...current, noTelp: event.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <Field label="Website Pesantren">
                      <div className="relative">
                        <Globe size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                        <input value={form.website} onChange={(event) => setForm((current) => ({ ...current, website: event.target.value }))} className={`${inputCls} pl-10`} />
                      </div>
                    </Field>
                    <div className="md:col-span-2">
                      <Field label="Alamat">
                        <textarea value={form.alamat} rows={3} onChange={(event) => setForm((current) => ({ ...current, alamat: event.target.value }))} className={inputCls} />
                      </Field>
                    </div>
                  </section>
                )}

                {activeDrawerTab === "akses" && (
                  <>
                    <section className="grid gap-4 md:grid-cols-2">
                      <Field label="Paket Langganan">
                        <select value={form.subscriptionTier} onChange={(event) => setForm((current) => ({ ...current, subscriptionTier: event.target.value as SubscriptionTier }))} className={inputCls}>
                          <option value="Trial">Trial</option>
                          <option value="Premium Bulanan">Premium Bulanan</option>
                          <option value="Premium Tahunan">Premium Tahunan</option>
                        </select>
                      </Field>
                      <Field label="Status Akses">
                        <select value={form.status} onChange={(event) => setForm((current) => ({ ...current, status: event.target.value as TenantStatus }))} className={inputCls}>
                          <option value="active">Aktif</option>
                          <option value="suspended">Ditangguhkan</option>
                        </select>
                      </Field>
                      <Field label="Masa Aktif Sampai">
                        <div className="relative">
                          <CalendarClock size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                          <input type="date" value={form.activeUntil} onChange={(event) => setForm((current) => ({ ...current, activeUntil: event.target.value }))} className={`${inputCls} pl-10`} />
                        </div>
                      </Field>
                      {mode === "create" && (
                        <Field label="Password Admin Awal *">
                          <input type="password" value={form.adminPassword} onChange={(event) => setForm((current) => ({ ...current, adminPassword: event.target.value }))} className={inputCls} />
                        </Field>
                      )}
                    </section>

                    <section className="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
                      <div className="mb-4">
                        <div className="text-xs font-bold uppercase tracking-[0.14em] text-gray-500 dark:text-gray-400">Admin Pesantren</div>
                        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Atur identitas login tenant yang dipakai pada alur admin pesantren. Untuk tenant baru, username admin dibuat dengan key tetap.</p>
                      </div>

                      <div className="grid gap-3 md:grid-cols-2">
                        <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                          <div className="text-[11px] uppercase text-gray-400">NPSN</div>
                          <div className="mt-1 font-semibold text-gray-800 dark:text-white">{form.npsn || "Belum diisi"}</div>
                          <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">Dipakai sebagai identitas utama tenant baru pada panel super admin.</div>
                        </div>
                        <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                          <div className="text-[11px] uppercase text-gray-400">Username Admin</div>
                          <div className="mt-1 font-semibold text-gray-800 dark:text-white">admin</div>
                          <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">Key default untuk mapping admin tenant.</div>
                        </div>
                      </div>

                      <div className="mt-4 grid gap-4 md:grid-cols-2">
                        <Field label={mode === "create" ? "Sandi Awal Admin *" : "Reset Sandi Awal Admin"}>
                          <input
                            type="password"
                            value={form.adminPassword}
                            onChange={(event) => setForm((current) => ({ ...current, adminPassword: event.target.value }))}
                            placeholder={mode === "create" ? "Masukkan sandi admin awal" : "Kosongkan jika tidak diubah"}
                            className={inputCls}
                          />
                        </Field>
                        <div className="rounded-2xl border border-sky-100 bg-sky-50 p-4 text-sm text-sky-800 dark:border-sky-500/20 dark:bg-sky-500/10 dark:text-sky-200">
                          <div className="font-semibold">Catatan</div>
                          <p className="mt-1">Perubahan sandi di sini memperbarui sandi default pada mapping admin tenant. Ini berguna untuk onboarding atau reset akses awal admin pesantren.</p>
                        </div>
                      </div>
                    </section>
                  </>
                )}

                {activeDrawerTab === "modul" && (
                  <section>
                    <div className="mb-3">
                      <div className="text-xs font-bold uppercase tracking-[0.14em] text-gray-500 dark:text-gray-400">Modul Aktif</div>
                      <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Atur modul yang akan aktif untuk pesantren ini. Modul Quran tetap aktif sebagai modul inti.</p>
                    </div>

                    <div className="grid gap-3 md:grid-cols-2">
                      {moduleOptions.map((module) => {
                        const active = form.activeModules.includes(module.key);
                        return (
                          <label key={module.key} className={`flex items-start justify-between gap-3 rounded-2xl border px-4 py-3 transition ${active ? "border-emerald-200 bg-emerald-50/70 dark:border-emerald-500/30 dark:bg-emerald-500/10" : "border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]"}`}>
                            <div>
                              <div className="font-semibold text-gray-800 dark:text-white">{module.title}</div>
                              <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">{module.description}</div>
                            </div>
                            <input
                              type="checkbox"
                              checked={active}
                              disabled={module.locked}
                              onChange={() => toggleModule(module.key)}
                              className="mt-1 h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500 disabled:opacity-60"
                            />
                          </label>
                        );
                      })}
                    </div>
                  </section>
                )}

                {activeDrawerTab === "branding" && (
                  <>
                    <section className="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
                      <div className="flex flex-col gap-4 md:flex-row md:items-center">
                        {(logoPreview || form.logoUrl) ? (
                          <img src={logoPreview || form.logoUrl} alt={form.nama || "Pesantren"} className="h-20 w-20 rounded-2xl border border-gray-200 object-cover dark:border-gray-700" />
                        ) : (
                          <div className="flex h-20 w-20 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10">
                            <Building2 size={28} />
                          </div>
                        )}

                        <div className="flex-1">
                          <div className="text-sm font-semibold text-gray-800 dark:text-white">Logo Pesantren</div>
                          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">Unggah logo baru atau pertahankan logo saat ini. Batas ukuran 2MB.</p>
                        </div>

                        <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-emerald-50 px-3 py-2 text-sm font-semibold text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:text-emerald-300">
                          <Plus size={16} /> Pilih Logo
                          <input type="file" accept="image/*" onChange={handleLogoChange} className="hidden" />
                        </label>
                      </div>
                    </section>

                    <div className="rounded-2xl border border-sky-100 bg-sky-50 p-4 text-sm text-sky-800 dark:border-sky-500/20 dark:bg-sky-500/10 dark:text-sky-200">
                      <div className="flex items-start gap-3">
                        <CheckCircle2 size={18} className="mt-0.5" />
                        <p>Data ini akan menyinkronkan dokumen utama pesantren serta profil dasar pada pengaturan pesantren agar panel admin tenant tetap konsisten.</p>
                      </div>
                    </div>
                  </>
                )}
              </div>

              <div className="sticky bottom-0 mt-auto flex items-center justify-end gap-3 border-t border-gray-200 bg-white/95 px-6 py-4 backdrop-blur dark:border-gray-800 dark:bg-gray-900/95">
                <button type="button" onClick={closeDrawer} className="rounded-xl border border-gray-200 px-4 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-white/5">
                  Batal
                </button>
                <button type="submit" disabled={saving} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-600 disabled:opacity-60">
                  <Save size={16} /> {saving ? "Menyimpan..." : mode === "create" ? "Simpan Pesantren" : "Simpan Perubahan"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

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

function isExpired(date: Date | null) {
  return !date || date.getTime() < Date.now();
}