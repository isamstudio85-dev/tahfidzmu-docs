import { useEffect, useState } from "react";
import { collection, doc, getDocs, setDoc, updateDoc, deleteDoc, query, where, serverTimestamp } from "firebase/firestore";
import { initializeApp } from "firebase/app";
import { getAuth, createUserWithEmailAndPassword, signOut } from "firebase/auth";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Search, ShieldAlert, UserPlus, Trash2, ShieldCheck, UserCheck, UserX, Key } from "lucide-react";

type StaffUser = {
  uid: string;
  name: string;
  email: string;
  role: string;
  superAdminRole: "owner" | "support" | "finance";
  status: "active" | "inactive";
  createdAt?: any;
};

// Secondary Firebase App config to create user auth without logging out current user session
const firebaseConfig = {
  apiKey: "AIzaSyD2Ko6exFRNxF5a2YcWm6oupub3OegtBBE",
  authDomain: "tahfidzmu-db5d9.firebaseapp.com",
  projectId: "tahfidzmu-db5d9",
  storageBucket: "tahfidzmu-db5d9.firebasestorage.app",
  messagingSenderId: "523716467425",
  appId: "1:523716467425:web:a6cac187e23ce329bff5a0",
};

export default function SuperAdminStaffPage() {
  const { profile } = useAuth();
  const [list, setList] = useState<StaffUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form states
  const [isOpen, setIsOpen] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [staffRole, setStaffRole] = useState<"support" | "finance">("support");

  useEffect(() => {
    if (profile?.email === "dasamsamsudin87@gmail.com") {
      loadStaff();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const loadStaff = async () => {
    setLoading(true);
    try {
      // Load all users where role == 'superAdmin'
      const q = query(collection(db, "users"), where("role", "==", "superAdmin"));
      const snap = await getDocs(q);
      const items = snap.docs.map((d) => {
        const data = d.data();
        return {
          uid: d.id,
          name: data.nama || data.name || data.displayName || "Karyawan",
          email: data.email || "",
          role: data.role || "superAdmin",
          superAdminRole: data.superAdminRole || "support",
          status: data.status || "active",
        } as StaffUser;
      });

      // Ensure Owner (dasamsamsudin87@gmail.com) is always marked as owner
      const normalized = items.map((item) => {
        if (item.email.toLowerCase() === "dasamsamsudin87@gmail.com") {
          return { ...item, superAdminRole: "owner" as const };
        }
        return item;
      });

      setList(normalized);
    } catch (err) {
      console.error("Gagal memuat staf:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.trim() || !password.trim()) {
      setError("Semua field wajib diisi");
      return;
    }
    if (password.length < 6) {
      setError("Kata sandi minimal 6 karakter");
      return;
    }

    setSaving(true);
    setError(null);

    let secondaryApp;
    try {
      // 1. Initialize secondary app to register auth
      secondaryApp = initializeApp(firebaseConfig, "secondary-auth-creator");
      const secondaryAuth = getAuth(secondaryApp);

      const userCredential = await createUserWithEmailAndPassword(
        secondaryAuth,
        email.trim(),
        password
      );
      const newUid = userCredential.user.uid;

      // Clean secondary session
      await signOut(secondaryAuth);

      // 2. Save user profile metadata in Firestore under /users/{newUid}
      await setDoc(doc(db, "users", newUid), {
        uid: newUid,
        nama: name.trim(),
        email: email.trim().toLowerCase(),
        role: "superAdmin",
        superAdminRole: staffRole,
        status: "active",
        createdAt: serverTimestamp(),
      });

      // Reset
      setName("");
      setEmail("");
      setPassword("");
      setIsOpen(false);
      await loadStaff();
    } catch (err: any) {
      console.error("Registrasi staf gagal:", err);
      setError(err.message || "Gagal membuat akun staf");
    } finally {
      // Clean secondary app memory
      if (secondaryApp) {
        try {
          // Destory secondary app instance to prevent reuse error
          secondaryApp.automaticDataCollectionEnabled = false;
        } catch {}
      }
      setSaving(false);
    }
  };

  const handleToggleStatus = async (staff: StaffUser) => {
    if (staff.superAdminRole === "owner") return;
    const nextStatus = staff.status === "active" ? "inactive" : "active";
    const confirm = window.confirm(`Ubah status staf "${staff.name}" menjadi ${nextStatus === "active" ? "Aktif" : "Nonaktif"}?`);
    if (!confirm) return;

    try {
      await updateDoc(doc(db, "users", staff.uid), {
        status: nextStatus,
      });
      await loadStaff();
    } catch (err: any) {
      console.error(err);
      alert("Gagal mengubah status: " + err.message);
    }
  };

  const handleDeleteStaff = async (staff: StaffUser) => {
    if (staff.superAdminRole === "owner") return;
    const confirm = window.confirm(`Hapus akun staf "${staff.name}" secara permanen? Akses login ke dashboard super admin akan dinonaktifkan.`);
    if (!confirm) return;

    try {
      await deleteDoc(doc(db, "users", staff.uid));
      await loadStaff();
    } catch (err: any) {
      console.error(err);
      alert("Gagal menghapus staf: " + err.message);
    }
  };

  const isOwner = profile?.email === "dasamsamsudin87@gmail.com";

  if (!isOwner) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Terbatas</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Menu pengelolaan staf super admin hanya dapat diakses oleh Owner utama.</p>
      </div>
    );
  }

  const filtered = list.filter((s) =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      <PageMeta title="Kelola Staf | TahfidzMU Super Admin" description="Manajemen karyawan dan staf internal platform." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Daftar Karyawan & Staf</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Atur hak akses staf internal platform untuk operasional harian.
            </p>
          </div>
          <button
            onClick={() => {
              setError(null);
              setIsOpen(true);
            }}
            className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition"
          >
            <UserPlus size={18} /> Tambah Staf Baru
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama atau email karyawan..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm"
          />
        </div>

        {/* List View */}
        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]">
            <div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500">
            <ShieldAlert size={36} className="mx-auto mb-3 text-gray-300 dark:text-gray-700" />
            <p className="text-sm font-medium">Tidak ada karyawan yang terdaftar.</p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((s) => (
              <div
                key={s.uid}
                className="bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 p-5 shadow-sm space-y-4 flex flex-col justify-between"
              >
                <div>
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-bold text-gray-900 dark:text-white">{s.name}</h4>
                      <p className="text-xs text-gray-400 mt-0.5">{s.email}</p>
                    </div>
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                        s.status === "active"
                          ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-450"
                          : "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-450"
                      }`}
                    >
                      {s.status === "active" ? "Aktif" : "Nonaktif"}
                    </span>
                  </div>

                  <div className="mt-4 space-y-2">
                    <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-400">
                      <ShieldCheck size={14} className="text-brand-500" />
                      <span>Role: <strong className="uppercase">{s.superAdminRole}</strong></span>
                    </div>
                    <p className="text-[11px] text-gray-400">
                      {s.superAdminRole === "owner" && "Akses penuh platform & manajemen keuangan."}
                      {s.superAdminRole === "support" && "Hanya akses baca tenant & reset password pondok."}
                      {s.superAdminRole === "finance" && "Kelola invoice, pembayaran, dan paket langganan."}
                    </p>
                  </div>
                </div>

                {s.superAdminRole !== "owner" && (
                  <div className="pt-4 border-t border-gray-100 dark:border-gray-800 flex justify-end gap-2">
                    <button
                      onClick={() => handleToggleStatus(s)}
                      className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold transition border ${
                        s.status === "active"
                          ? "border-orange-200 text-orange-600 hover:bg-orange-50 dark:border-orange-950 dark:text-orange-450 dark:hover:bg-orange-950/20"
                          : "border-emerald-200 text-emerald-600 hover:bg-emerald-50 dark:border-emerald-950 dark:text-emerald-450 dark:hover:bg-emerald-950/20"
                      }`}
                    >
                      {s.status === "active" ? <UserX size={12} /> : <UserCheck size={12} />}
                      {s.status === "active" ? "Nonaktifkan" : "Aktifkan"}
                    </button>
                    <button
                      onClick={() => handleDeleteStaff(s)}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold text-red-600 hover:bg-red-50 border border-red-200 dark:border-red-950 dark:text-red-400 dark:hover:bg-red-950/20"
                    >
                      <Trash2 size={12} /> Hapus
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Modal Dialog Form */}
        {isOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 backdrop-blur-sm p-4">
            <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-3xl w-full max-w-md p-6 shadow-2xl space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 dark:text-white">Tambah Staf Karyawan</h3>
                  <p className="text-xs text-gray-400 mt-1">Daftarkan akun staf baru untuk operasional internal.</p>
                </div>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-1 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <UserX size={18} />
                </button>
              </div>

              {error && (
                <div className="p-3 text-xs font-medium text-red-700 bg-red-50 border border-red-100 rounded-xl dark:bg-red-500/10 dark:text-red-400 dark:border-red-500/20">
                  {error}
                </div>
              )}

              <form onSubmit={handleCreateStaff} className="space-y-4">
                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Nama Lengkap</label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Contoh: Ahmad Fauzi"
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 text-gray-950 dark:text-white"
                  />
                </div>

                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Alamat Email</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Contoh: ahmad@tahfidzmu.com"
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 text-gray-950 dark:text-white"
                  />
                </div>

                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Kata Sandi</label>
                  <div className="relative">
                    <Key size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Minimal 6 karakter"
                      className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 text-gray-950 dark:text-white"
                    />
                  </div>
                </div>

                <div>
                  <label className="block mb-1.5 text-xs font-bold text-gray-500 uppercase tracking-wider">Hak Akses Operasional</label>
                  <select
                    value={staffRole}
                    onChange={(e) => setStaffRole(e.target.value as any)}
                    className="w-full px-3 py-2 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 text-gray-950 dark:text-white"
                  >
                    <option value="support">Tim Support (Hanya Baca Tenant & Reset Pass)</option>
                    <option value="finance">Tim Finance (Kelola Invoice & Paket Sewa)</option>
                  </select>
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
                    {saving ? "Memproses..." : "Daftarkan Staf"}
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
