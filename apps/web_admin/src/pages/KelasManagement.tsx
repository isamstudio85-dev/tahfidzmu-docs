import { useEffect, useState } from "react";
import { collection, doc, getDocs, setDoc, deleteDoc } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Plus, Search, Trash2, Edit2, ShieldAlert, FolderOpen } from "lucide-react";

export default function KelasManagement() {
  const { profile } = useAuth();
  const [list, setList] = useState<any[]>([]);
  const [santriList, setSantriList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [id, setId] = useState("");
  const [name, setName] = useState("");
  const [isEdit, setIsEdit] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (profile?.pesantrenId) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;
      const snap = await getDocs(collection(db, "pesantren", pid, "kelas"));
      setList(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      const sSnap = await getDocs(collection(db, "pesantren", pid, "santri"));
      setSantriList(sSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const handleOpenAdd = () => { setIsEdit(false); setId(""); setName(""); setError(null); setIsOpen(true); };
  const handleOpenEdit = (k: any) => { setIsEdit(true); setId(k.id); setName(k.nama); setError(null); setIsOpen(true); };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) { setError("Nama kelas wajib diisi"); return; }
    const pid = profile?.pesantrenId;
    if (!pid) return;
    setError(null); setSaving(true);
    try {
      const docId = isEdit ? id : doc(collection(db, "pesantren", pid, "kelas")).id;
      await setDoc(doc(db, "pesantren", pid, "kelas", docId), {
        id: docId,
        nama: name.trim().toUpperCase(),
      }, { merge: true });
      setIsOpen(false); load();
    } catch (err: any) { console.error(err); setError("Gagal menyimpan: " + err.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (kelasId: string) => {
    if (!profile?.pesantrenId) return;
    const k = list.find((x) => x.id === kelasId);
    const count = k ? santriList.filter((s) => s.kelas === k.nama).length : 0;
    if (count > 0) { alert(`Kelas ${k?.nama} masih memiliki ${count} santri. Pindahkan santri dulu.`); return; }
    if (!window.confirm("Hapus kelas ini?")) return;
    try {
      await deleteDoc(doc(db, "pesantren", profile.pesantrenId, "kelas", kelasId));
      load();
    } catch (err) { console.error(err); alert("Gagal menghapus"); }
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

  const filtered = [...list]
    .filter((k) => (k.nama || "").toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => String(a.nama || "").localeCompare(String(b.nama || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Kelola Kelas | TahfidzMU Admin" description="Manajemen kelas formal santri." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Daftar Kelas</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Buat & kelola tingkatan kelas untuk santri.</p>
          </div>
          <button onClick={handleOpenAdd} className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition"><Plus size={18} /> Buat Kelas</button>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari kelas..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white shadow-sm" />
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500"><FolderOpen size={36} className="mx-auto mb-3 text-gray-300" /><p className="text-sm">Belum ada kelas.</p></div>
        ) : (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {filtered.map((k) => (
              <div key={k.id} className="p-4 bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 flex items-center justify-between">
                <span className="font-bold text-gray-800 dark:text-white">{k.nama}</span>
                <div className="flex gap-1">
                  <button onClick={() => handleOpenEdit(k)} className="p-1 text-gray-400 hover:text-blue-600"><Edit2 size={14} /></button>
                  <button onClick={() => handleDelete(k.id)} className="p-1 text-gray-400 hover:text-error-500"><Trash2 size={14} /></button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm items-start">
          <div className="mt-12 mb-12 w-full max-w-sm bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-xl p-6">
            <h3 className="text-lg font-bold text-gray-800 dark:text-white mb-4">{isEdit ? "Edit Kelas" : "Buat Kelas"}</h3>
            {error && <div className="p-3 mb-4 text-xs text-error-700 bg-error-50 border border-error-100 rounded-xl dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1">Nama Kelas *</label>
                <input required value={name} onChange={(e) => setName(e.target.value)} placeholder="Contoh: 7A" className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white uppercase" />
              </div>
              <div className="flex items-center justify-end gap-3 pt-2">
                <button type="button" onClick={() => setIsOpen(false)} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Batal</button>
                <button type="submit" disabled={saving} className="px-4 py-2 text-xs font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50">{saving ? "Menyimpan..." : "Simpan"}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
