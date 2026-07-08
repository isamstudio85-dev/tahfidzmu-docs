import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import { collection, doc, getDoc, getDocs, Timestamp } from "firebase/firestore";
import { db } from "../../firebase";
import { useAuth } from "../../context/AuthContext";
import PageMeta from "../../components/common/PageMeta";
import { Users, GraduationCap, BookOpen, FolderOpen, Building2, School, ShieldCheck, CalendarDays, ChevronRight, Sparkles, Wallet } from "lucide-react";

type DashboardStats = {
  santri: number;
  musyrif: number;
  halaqah: number;
  kelas: number;
  wisuda: number;
  registrations: number;
};

type PesantrenInfo = {
  nama: string;
  alamat: string;
  noTelp: string;
  email: string;
  logoPath: string;
};

type PublishedGraduation = {
  id: string;
  title: string;
  year: string;
  description: string;
  graduationDate: string | null;
  bannerPath: string | null;
};

type GraduationDoc = {
  id: string;
  isPublished?: boolean;
  title?: string;
  year?: string;
  description?: string;
  graduationDate?: string;
  bannerPath?: string;
};

type HalaqahActivity = {
  id: string;
  name: string;
  musyrifName: string;
  santriCount: number;
};

type QuickLink = {
  title: string;
  subtitle: string;
  path: string;
  icon: typeof Users;
  color: string;
  bg: string;
};

const emptyInfo: PesantrenInfo = {
  nama: "",
  alamat: "",
  noTelp: "",
  email: "",
  logoPath: "",
};

function formatDateLabel(value: string | null) {
  if (!value) return "Belum ditentukan";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("id-ID", { day: "2-digit", month: "long", year: "numeric" }).format(date);
}

export default function Home() {
  const { profile } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({ santri: 0, musyrif: 0, halaqah: 0, kelas: 0, wisuda: 0, registrations: 0 });
  const [pesantrenInfo, setPesantrenInfo] = useState<PesantrenInfo>(emptyInfo);
  const [graduationInfo, setGraduationInfo] = useState<PublishedGraduation | null>(null);
  const [halaqahActivities, setHalaqahActivities] = useState<HalaqahActivity[]>([]);
  const [daysLeft, setDaysLeft] = useState<number | null>(null);
  const [moduleCount, setModuleCount] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      if (!profile?.pesantrenId) {
        setLoading(false);
        return;
      }
      setLoading(true);
      try {
        const pid = profile.pesantrenId;
        const [santriSnap, musyrifSnap, halaqahSnap, kelasSnap, wisudaSnap, registrationSnap, infoSnap, pesantrenSnap, modulesSnap] = await Promise.all([
          getDocs(collection(db, "pesantren", pid, "santri")),
          getDocs(collection(db, "pesantren", pid, "musyrif")),
          getDocs(collection(db, "pesantren", pid, "halaqah")),
          getDocs(collection(db, "pesantren", pid, "kelas")),
          getDocs(collection(db, "pesantren", pid, "graduation_events")),
          getDocs(collection(db, "pesantren", pid, "graduation_registrations")),
          getDoc(doc(db, "pesantren", pid, "settings", "pesantren_info")),
          getDoc(doc(db, "pesantren", pid)),
          getDoc(doc(db, "pesantren", pid, "settings", "modules")),
        ]);

        const infoData = infoSnap.exists() ? infoSnap.data() : {};
        const musyrifMap = new Map(
          musyrifSnap.docs.map((item) => [item.id, String(item.data().nama || "Musyrif belum ditentukan")])
        );
        const santriPerHalaqah = santriSnap.docs.reduce<Record<string, number>>((acc, item) => {
          const halaqahId = String(item.data().halaqahId || "");
          if (!halaqahId) return acc;
          acc[halaqahId] = (acc[halaqahId] || 0) + 1;
          return acc;
        }, {});
        const publishedGraduationDoc = wisudaSnap.docs
          .map((item) => ({ id: item.id, ...(item.data() as Record<string, unknown>) }) as GraduationDoc)
          .find((item) => item.isPublished);
        const activeHalaqah = halaqahSnap.docs
          .map((item) => {
            const data = item.data() as Record<string, unknown>;
            return {
              id: item.id,
              name: String(data.nama || "Halaqah tanpa nama"),
              musyrifName: musyrifMap.get(String(data.musyrifId || "")) || "Musyrif belum ditentukan",
              santriCount: santriPerHalaqah[item.id] || 0,
            };
          })
          .sort((a, b) => b.santriCount - a.santriCount || a.name.localeCompare(b.name, "id", { sensitivity: "base" }))
          .slice(0, 4);

        const activeUntilRaw = pesantrenSnap.exists() ? pesantrenSnap.data()?.activeUntil : null;
        const activeUntil = activeUntilRaw instanceof Timestamp ? activeUntilRaw.toDate() : null;
        const currentDaysLeft = activeUntil ? Math.floor((activeUntil.getTime() - Date.now()) / (1000 * 60 * 60 * 24)) : null;

        setStats({
          santri: santriSnap.size,
          musyrif: musyrifSnap.size,
          halaqah: halaqahSnap.size,
          kelas: kelasSnap.size,
          wisuda: wisudaSnap.size,
          registrations: registrationSnap.size,
        });
        setPesantrenInfo({
          nama: String(infoData.nama || ""),
          alamat: String(infoData.alamat || ""),
          noTelp: String(infoData.noTelp || ""),
          email: String(infoData.email || ""),
          logoPath: String(infoData.logoPath || ""),
        });
        setGraduationInfo(
          publishedGraduationDoc
            ? {
                id: String(publishedGraduationDoc.id || ""),
                title: String(publishedGraduationDoc.title || "Agenda Wisuda"),
                year: String(publishedGraduationDoc.year || ""),
                description: String(publishedGraduationDoc.description || "Lihat informasi wisuda & hasil ujian."),
                graduationDate: publishedGraduationDoc.graduationDate ? String(publishedGraduationDoc.graduationDate) : null,
                bannerPath: publishedGraduationDoc.bannerPath ? String(publishedGraduationDoc.bannerPath) : null,
              }
            : null
        );
        setHalaqahActivities(activeHalaqah);
        setDaysLeft(currentDaysLeft);
        setModuleCount(Array.isArray(modulesSnap.data()?.active) ? modulesSnap.data()!.active.length : 0);
      } catch (err) {
        console.error("Error loading dashboard:", err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [profile]);

  const cards = [
    {
      label: "Total Santri",
      value: stats.santri,
      icon: Users,
      iconClass: "text-brand-100 bg-white/15",
      cardClass: "border-brand-300/40 bg-gradient-to-br from-brand-600 via-brand-500 to-sky-500 text-white",
      textClass: "text-white/80",
    },
    {
      label: "Total Musyrif",
      value: stats.musyrif,
      icon: GraduationCap,
      iconClass: "text-emerald-100 bg-white/15",
      cardClass: "border-emerald-300/40 bg-gradient-to-br from-emerald-600 via-emerald-500 to-teal-500 text-white",
      textClass: "text-white/80",
    },
    {
      label: "Total Halaqah",
      value: stats.halaqah,
      icon: BookOpen,
      iconClass: "text-amber-100 bg-white/15",
      cardClass: "border-amber-300/40 bg-gradient-to-br from-amber-500 via-orange-500 to-rose-500 text-white",
      textClass: "text-white/80",
    },
    {
      label: "Total Kelas",
      value: stats.kelas,
      icon: FolderOpen,
      iconClass: "text-cyan-100 bg-white/15",
      cardClass: "border-cyan-300/40 bg-gradient-to-br from-cyan-600 via-sky-500 to-blue-500 text-white",
      textClass: "text-white/80",
    },
  ];

  const quickLinks: QuickLink[] = useMemo(() => ([
    { title: "Info Pesantren", subtitle: "Profil lembaga dan modul aktif", path: "/pesantren-info", icon: Building2, color: "text-brand-500", bg: "bg-brand-50 dark:bg-brand-500/10" },
    { title: "Manajemen Wisuda", subtitle: "Agenda wisuda dan pendaftaran", path: "/wisuda", icon: School, color: "text-purple-600", bg: "bg-purple-50 dark:bg-purple-500/10" },
    { title: "Data Halaqah", subtitle: "Kelola kelompok dan pembimbing", path: "/halaqah", icon: BookOpen, color: "text-amber-600", bg: "bg-amber-50 dark:bg-amber-500/10" },
    { title: "Data Santri", subtitle: "Akses cepat ke santri", path: "/santri", icon: Users, color: "text-blue-600", bg: "bg-blue-50 dark:bg-blue-500/10" },
  ]), []);

  const subscriptionState = useMemo(() => {
    if (daysLeft == null) return null;
    if (daysLeft < 0) {
      return {
        title: "Masa aktif habis",
        description: "Akses pesantren sudah melewati masa aktif. Hubungi Super Admin untuk perpanjangan.",
        color: "text-error-600",
        bg: "bg-error-50 dark:bg-error-500/10",
        border: "border-error-200 dark:border-error-500/20",
      };
    }
    if (daysLeft <= 7) {
      return {
        title: "Langganan hampir berakhir",
        description: `Sisa ${daysLeft} hari. Segera hubungi Super Admin untuk perpanjangan.`,
        color: "text-amber-700",
        bg: "bg-amber-50 dark:bg-amber-500/10",
        border: "border-amber-200 dark:border-amber-500/20",
      };
    }
    return null;
  }, [daysLeft]);

  return (
    <>
      <PageMeta title="Dashboard | TahfidzMU Web Admin" description="Ringkasan data pesantren." />
      <div className="space-y-6">
        <div className="overflow-hidden rounded-2xl bg-gradient-to-r from-brand-600 via-brand-500 to-emerald-500 text-white shadow-sm">
          <div className="flex flex-col gap-5 p-6 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center gap-4">
              {pesantrenInfo.logoPath ? (
                <img src={pesantrenInfo.logoPath} alt={pesantrenInfo.nama || "Pesantren"} className="h-16 w-16 rounded-2xl border border-white/20 object-cover" />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-white/15">
                  <School size={30} />
                </div>
              )}
              <div>
                <h2 className="text-xl font-bold md:text-2xl">{pesantrenInfo.nama || "TahfidzMU Web Admin"}</h2>
                <p className="mt-1 text-sm text-white/80">{pesantrenInfo.alamat || `Selamat datang, ${profile?.name || "Admin"}. Kelola data pesantren dari web.`}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3 lg:min-w-[320px]">
              <div className="rounded-2xl bg-white/12 p-4 backdrop-blur-sm">
                <div className="text-[11px] uppercase text-white/70">Modul Aktif</div>
                <div className="mt-1 text-2xl font-bold">{moduleCount || 1}</div>
              </div>
              <div className="rounded-2xl bg-white/12 p-4 backdrop-blur-sm">
                <div className="text-[11px] uppercase text-white/70">Pendaftaran Wisuda</div>
                <div className="mt-1 text-2xl font-bold">{stats.registrations}</div>
              </div>
            </div>
          </div>
        </div>

        {graduationInfo && (
          <Link to="/wisuda" className="block overflow-hidden rounded-2xl border border-purple-200 bg-white transition hover:shadow-sm dark:border-purple-500/20 dark:bg-white/[0.03]">
            <div className="flex flex-col md:flex-row">
              {graduationInfo.bannerPath ? (
                <img src={graduationInfo.bannerPath} alt={graduationInfo.title} className="h-44 w-full object-cover md:w-72" />
              ) : (
                <div className="flex h-44 w-full items-center justify-center bg-purple-50 text-purple-600 dark:bg-purple-500/10 md:w-72">
                  <Sparkles size={40} />
                </div>
              )}
              <div className="flex flex-1 items-center justify-between gap-4 p-5">
                <div>
                  <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-purple-50 px-3 py-1 text-[11px] font-bold uppercase text-purple-600 dark:bg-purple-500/10">
                    <CalendarDays size={12} /> Info Wisuda
                  </div>
                  <h3 className="text-lg font-bold text-gray-800 dark:text-white">{graduationInfo.title}</h3>
                  <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{graduationInfo.description || "Lihat informasi wisuda & hasil ujian."}</p>
                  <p className="mt-3 text-sm font-medium text-purple-700 dark:text-purple-300">Pelaksanaan: {formatDateLabel(graduationInfo.graduationDate)}</p>
                </div>
                <ChevronRight size={18} className="hidden text-gray-400 md:block" />
              </div>
            </div>
          </Link>
        )}

        {subscriptionState && (
          <div className={`rounded-2xl border p-4 ${subscriptionState.bg} ${subscriptionState.border}`}>
            <div className="flex items-start gap-3">
              <ShieldCheck size={22} className={subscriptionState.color} />
              <div>
                <h3 className={`font-bold ${subscriptionState.color}`}>{subscriptionState.title}</h3>
                <p className={`mt-1 text-sm ${subscriptionState.color}`}>{subscriptionState.description}</p>
              </div>
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]">
            <div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
              {cards.map((c) => (
                <div key={c.label} className={`flex items-center gap-4 rounded-2xl border p-6 shadow-sm ${c.cardClass}`}>
                  <div className={`flex h-12 w-12 items-center justify-center rounded-xl backdrop-blur-sm ${c.iconClass}`}>
                    <c.icon size={24} />
                  </div>
                  <div>
                    <span className={`text-sm font-medium ${c.textClass}`}>{c.label}</span>
                    <h4 className="mt-1 text-2xl font-bold text-white">{c.value}</h4>
                  </div>
                </div>
              ))}
            </div>

            <div className="grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,0.85fr)]">
              <div className="rounded-2xl border border-slate-200 bg-gradient-to-br from-slate-50 via-white to-brand-50 p-6 dark:border-gray-800 dark:bg-white/[0.03]">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Cepat</h3>
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Jalur cepat ke halaman yang paling sering dipakai admin.</p>
                  </div>
                </div>
                <div className="mt-5 grid gap-3 md:grid-cols-2">
                  {quickLinks.map((item) => (
                    <Link key={item.path} to={item.path} className="group rounded-2xl border border-white/70 bg-white/80 p-4 transition hover:border-brand-200 hover:shadow-sm dark:border-gray-800 dark:hover:border-brand-500/20">
                      <div className="flex items-start gap-3">
                        <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${item.bg} ${item.color}`}>
                          <item.icon size={20} />
                        </div>
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center justify-between gap-3">
                            <h4 className="font-semibold text-gray-800 dark:text-white">{item.title}</h4>
                            <ChevronRight size={16} className="text-gray-300 transition group-hover:text-brand-500" />
                          </div>
                          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{item.subtitle}</p>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>

              <div className="rounded-2xl border border-amber-200/70 bg-gradient-to-br from-amber-50 via-white to-emerald-50 p-6 dark:border-gray-800 dark:bg-white/[0.03]">
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">Ringkasan Operasional</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Ikhtisar cepat untuk kebutuhan admin harian.</p>
                <div className="mt-5 space-y-3">
                  <div className="rounded-2xl border border-emerald-100 bg-white/80 p-4 dark:bg-white/5">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10"><Wallet size={18} /></div>
                      <div>
                        <div className="text-sm font-semibold text-gray-800 dark:text-white">Agenda Wisuda</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">{stats.wisuda} agenda, {stats.registrations} pendaftar aktif.</div>
                      </div>
                    </div>
                  </div>
                  <div className="rounded-2xl border border-brand-100 bg-white/80 p-4 dark:bg-white/5">
                    <div className="text-sm font-semibold text-gray-800 dark:text-white">Aktivitas Halaqah Saat Ini</div>
                    <div className="mt-3 space-y-3">
                      {halaqahActivities.length === 0 ? (
                        <div className="text-sm text-gray-500 dark:text-gray-400">Belum ada halaqah aktif yang bisa diringkas.</div>
                      ) : (
                        halaqahActivities.map((item) => (
                          <div key={item.id} className="rounded-xl border border-brand-100/80 bg-brand-50/60 p-3 dark:border-brand-500/20 dark:bg-brand-500/5">
                            <div className="flex items-start justify-between gap-3">
                              <div>
                                <div className="font-semibold text-gray-800 dark:text-white">{item.name}</div>
                                <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">Musyrif: {item.musyrifName}</div>
                              </div>
                              <div className="rounded-full bg-white px-2.5 py-1 text-xs font-bold text-brand-600 shadow-sm dark:bg-gray-900 dark:text-brand-300">
                                {item.santriCount} santri
                              </div>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                  <div className="rounded-2xl border border-sky-100 bg-white/80 p-4 dark:bg-white/5">
                    <div className="text-sm font-semibold text-gray-800 dark:text-white">Kontak Pesantren</div>
                    <div className="mt-2 space-y-1 text-sm text-gray-500 dark:text-gray-400">
                      <p>{pesantrenInfo.noTelp || "No. telp belum diisi"}</p>
                      <p>{pesantrenInfo.email || "Email belum diisi"}</p>
                    </div>
                  </div>
                  <div className="rounded-2xl border border-violet-100 bg-white/80 p-4 dark:bg-white/5">
                    <div className="text-sm font-semibold text-gray-800 dark:text-white">Status Akun</div>
                    <div className="mt-2 text-sm text-gray-500 dark:text-gray-400">Akun ini terhubung ke pesantren dan siap dipakai untuk pengelolaan data web admin.</div>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {!profile?.pesantrenId && !loading && (
          <div className="p-6 text-sm text-center text-gray-500 bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800">
            Akun ini belum terhubung ke pesantren mana pun.
          </div>
        )}
      </div>
    </>
  );
}
