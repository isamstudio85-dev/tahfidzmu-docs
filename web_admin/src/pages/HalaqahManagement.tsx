import { useEffect, useState } from "react";
import { collection, doc, getDocs, setDoc, deleteDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { Plus, Search, Trash2, Edit2, ShieldAlert, BookOpen, Upload, X } from "lucide-react";

export default function HalaqahManagement() {
  const { profile } = useAuth();
  const [list, setList] = useState<any[]>([]);
  const [musyrifList, setMusyrifList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [id, setId] = useState("");
  const [name, setName] = useState("");
  const [musyrifId, setMusyrifId] = useState("");
  const [isEdit, setIsEdit] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [existingPhotoPath, setExistingPhotoPath] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.pesantrenId) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;
      const snap = await getDocs(collection(db, "pesantren", pid, "halaqah"));
      setList(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      const mSnap = await getDocs(collection(db, "pesantren", pid, "musyrif"));
      setMusyrifList(mSnap.docs.map((d) => ({ id: d.id, nama: d.data().nama })));
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const handleOpenAdd = () => {
    setIsEdit(false); setId(""); setName(""); setMusyrifId("");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); setError(null); setIsOpen(true);
  };
  const handleOpenEdit = (h: any) => {
    setIsEdit(true); setId(h.id); setName(h.nama || ""); setMusyrifId(h.musyrifId || "");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(h.photoPath || null); setError(null); setIsOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) { setError("Ukuran foto maksimal 2MB"); return; }
      setPhotoFile(file); setPhotoPreview(URL.createObjectURL(file)); setError(null);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) { setError("Nama halaqah wajib diisi"); return; }
    const pid = profile?.pesantrenId;
    if (!pid) return;
    setError(null); setSaving(true);
    try {
      const docId = isEdit ? id : doc(collection(db, "pesantren", pid, "halaqah")).id;
      let finalPhotoUrl = existingPhotoPath;
      if (photoFile) {
        try {
          const photoRef = ref(storage, `halaqah_photos/${docId}.jpg`);
          const up = await uploadBytes(photoRef, photoFile);
          finalPhotoUrl = await getDownloadURL(up.ref);
        } catch (uErr) { console.warn("Upload foto gagal:", uErr); }
      }
      await setDoc(doc(db, "pesantren", pid, "halaqah", docId), {
        id: docId,
        nama: name.trim(),
        musyrifId: musyrifId || null,
        photoPath: finalPhotoUrl || null,
      }, { merge: true });
      setIsOpen(false); load();
    } catch (err: any) { console.error(err); setError("Gagal menyimpan: " + err.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (halaqahId: string) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm("Hapus halaqah ini?")) return;
    try {
      await deleteDoc(doc(db, "pesantren", profile.pesantrenId, "halaqah", halaqahId));
      load();
    } catch (err) { console.error(err); alert("Gagal menghapus"); }
  };

  const getMusyrifName = (mid: string) => musyrifList.find((m) => m.id === mid)?.nama || "-";

  if (profile?.role !== "admin" && profile?.role !== "superAdmin") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
      </div>
    );
  }

  const filtered = [...list]
    .filter((h) => (h.nama || "").toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => String(a.nama || "").localeCompare(String(b.nama || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Kelola Halaqah | TahfidzMU Admin" description="Manajemen kelompok halaqah tahfidz." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Daftar Halaqah</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Kelola kelompok halaqah dan musyrif pembimbingnya.</p>
          </div>
          <button onClick={handleOpenAdd} className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition"><Plus size={18} /> Buat Halaqah</button>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari halaqah..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full pl-11 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:bg-white/[0.03] dark:border-gray-800 dark:text-white" />
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800 text-gray-500"><BookOpen size={36} className="mx-auto mb-3 text-gray-300" /><p className="text-sm">Belum ada halaqah.</p></div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((h) => (
              <div key={h.id} className="p-5 bg-white border border-gray-200 rounded-2xl dark:bg-white/[0.03] dark:border-gray-800">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    {h.photoPath ? <img src={h.photoPath} alt={h.nama} className="w-12 h-12 rounded-xl object-cover" /> : <div className="flex items-center justify-center w-12 h-12 rounded-xl bg-brand-50 text-brand-500 dark:bg-brand-500/10"><BookOpen size={22} /></div>}
                    <div>
                      <h4 className="font-bold text-gray-800 dark:text-white">{h.nama}</h4>
                      <p className="text-xs text-gray-500 dark:text-gray-400">Musyrif: {getMusyrifName(h.musyrifId)}</p>
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <button onClick={() => handleOpenEdit(h)} className="p-1 text-gray-400 hover:text-blue-600"><Edit2 size={14} /></button>
                    <button onClick={() => handleDelete(h.id)} className="p-1 text-gray-400 hover:text-error-500"><Trash2 size={14} /></button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="w-full max-w-md bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-xl p-6">
            <h3 className="text-lg font-bold text-gray-800 dark:text-white mb-4">{isEdit ? "Edit Halaqah" : "Buat Halaqah"}</h3>
            {error && <div className="p-3 mb-4 text-xs text-error-700 bg-error-50 border border-error-100 rounded-xl dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1">Nama Halaqah *</label>
                <input required value={name} onChange={(e) => setName(e.target.value)} placeholder="Contoh: Halaqah Al-Ikhlas" className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white" />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1">Musyrif Pembimbing</label>
                <select value={musyrifId} onChange={(e) => setMusyrifId(e.target.value)} className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white">
                  <option value="">-- Belum ditentukan --</option>
                  {musyrifList.map((m) => <option key={m.id} value={m.id}>{m.nama}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1">Foto Halaqah</label>
                <div className="flex items-center gap-3">
                  {(photoPreview || existingPhotoPath) ? (
                    <div className="relative">
                      <img src={photoPreview || existingPhotoPath || ""} alt="Foto" className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-700" />
                      <button type="button" onClick={() => { setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); }} className="absolute -top-2 -right-2 p-1 bg-error-500 text-white rounded-full"><X size={12} /></button>
                    </div>
                  ) : null}
                  <label className="flex items-center gap-2 px-3 py-2 text-xs font-bold text-brand-500 bg-brand-50 dark:bg-brand-500/10 rounded-xl cursor-pointer hover:bg-brand-100"><Upload size={14} /> Pilih Foto<input type="file" accept="image/*" onChange={handleFileChange} className="hidden" /></label>
                </div>
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
