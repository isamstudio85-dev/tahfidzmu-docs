import { useEffect, useState } from "react";
import { collection, doc, getDocs, setDoc, deleteDoc, Timestamp } from "firebase/firestore";
import { Plus, Search, Trash2, ChevronLeft, Save, BookOpen, Edit, FileText, CheckCircle } from "lucide-react";
import { db } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";

interface Kitab {
  id: string;
  nama: string;
  tipeUnit: "bait" | "hadits" | "halaman" | "nomor";
  totalUnit: number;
  deskripsi: string;
}

interface KitabContent {
  index: number;
  text: string;
  translation: string;
}

export default function KitabManagement() {
  const { profile } = useAuth();
  const [kitabs, setKitabs] = useState<Kitab[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [isEditing, setIsEditing] = useState(false);
  const [activeKitabId, setActiveKitabId] = useState<string | null>(null);
  
  // Text Content editor state
  const [isEditingContent, setIsEditingContent] = useState(false);
  const [selectedKitab, setSelectedKitab] = useState<Kitab | null>(null);
  const [contents, setContents] = useState<KitabContent[]>([]);
  const [activeContentIndex, setActiveContentIndex] = useState<number | null>(null);
  const [contentForm, setContentForm] = useState<KitabContent>({ index: 1, text: "", translation: "" });

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showSavedToast, setShowSavedToast] = useState(false);

  // Form State
  const [form, setForm] = useState<Omit<Kitab, "id">>({
    nama: "",
    tipeUnit: "nomor",
    totalUnit: 10,
    deskripsi: ""
  });

  useEffect(() => {
    if (profile?.pesantrenId) load();
  }, [profile?.pesantrenId]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const snap = await getDocs(collection(db, "pesantren", profile.pesantrenId, "kitab"));
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Kitab));
      setKitabs(items);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadContent = async (kitab: Kitab) => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const snap = await getDocs(collection(db, "pesantren", profile.pesantrenId, "kitab", kitab.id, "content"));
      const items = snap.docs.map(d => d.data() as KitabContent);
      // Sort by index ascending
      items.sort((a, b) => a.index - b.index);
      
      // Initialize full list from 1 to totalUnit if not fully populated
      const fullList: KitabContent[] = [];
      for (let i = 1; i <= kitab.totalUnit; i++) {
        const existing = items.find(item => item.index === i);
        fullList.push(existing || { index: i, text: "", translation: "" });
      }
      setContents(fullList);
      setSelectedKitab(kitab);
      setIsEditingContent(true);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddNew = () => {
    setForm({ nama: "", tipeUnit: "nomor", totalUnit: 10, deskripsi: "" });
    setActiveKitabId(null);
    setIsEditing(true);
  };

  const handleEdit = (k: Kitab) => {
    setForm({ nama: k.nama, tipeUnit: k.tipeUnit, totalUnit: k.totalUnit, deskripsi: k.deskripsi });
    setActiveKitabId(k.id);
    setIsEditing(true);
  };

  const handleSave = async () => {
    if (!form.nama.trim()) {
      setError("Nama Kitab tidak boleh kosong");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const pid = profile?.pesantrenId;
      if (!pid) {
        setError("Pesantren ID tidak ditemukan");
        return;
      }
      const id = activeKitabId || `kitab_${Date.now()}`;
      
      await setDoc(doc(db, "pesantren", pid, "kitab", id), {
        id,
        nama: form.nama,
        tipeUnit: form.tipeUnit,
        totalUnit: Number(form.totalUnit),
        deskripsi: form.deskripsi,
        createdAt: Timestamp.now()
      });

      await load();
      setShowSavedToast(true);
      setTimeout(() => setShowSavedToast(false), 2000);
      setIsEditing(false);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Hapus kitab ini beserta seluruh progress dan isinya?")) return;
    try {
      const pid = profile?.pesantrenId;
      if (!pid) return;
      await deleteDoc(doc(db, "pesantren", pid, "kitab", id));
      await load();
    } catch (err: any) {
      alert("Gagal menghapus: " + err.message);
    }
  };

  const handleEditContent = (c: KitabContent) => {
    setContentForm(c);
    setActiveContentIndex(c.index);
  };

  const handleSaveContent = async () => {
    if (!selectedKitab || !profile?.pesantrenId || activeContentIndex === null) return;
    setSaving(true);
    try {
      const pid = profile.pesantrenId;
      const kid = selectedKitab.id;
      
      // Update locally
      const updatedList = contents.map(item => 
        item.index === activeContentIndex ? { ...contentForm } : item
      );
      setContents(updatedList);

      // Save to Firebase
      await setDoc(
        doc(db, "pesantren", pid, "kitab", kid, "content", activeContentIndex.toString()),
        {
          index: activeContentIndex,
          text: contentForm.text,
          translation: contentForm.translation
        }
      );

      setActiveContentIndex(null);
      setContentForm({ index: 1, text: "", translation: "" });
      setShowSavedToast(true);
      setTimeout(() => setShowSavedToast(false), 2000);
    } catch (err: any) {
      alert("Gagal menyimpan teks: " + err.message);
    } finally {
      setSaving(false);
    }
  };

  const filtered = kitabs.filter((k) =>
    k.nama.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      <PageMeta title="Kelola Kitab - TahfidzMU" description="Manajemen Kitab Hafalan Dinamis" />

      {/* Main layout */}
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Kelola Kitab Hafalan</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Tambah dan kelola kitab hafalan dinamis seperti Nadhom, Hadits, Fiqih, dll.
            </p>
          </div>
          {!isEditing && !isEditingContent && (
            <button
              onClick={handleAddNew}
              className="flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-brand-500 rounded-lg hover:bg-brand-600 transition"
            >
              <Plus size={18} /> Tambah Kitab Baru
            </button>
          )}
        </div>

        {/* Saved Toast */}
        {showSavedToast && (
          <div className="fixed bottom-4 right-4 z-50 flex items-center gap-2 px-4 py-3 text-white bg-green-600 rounded-lg shadow-lg">
            <CheckCircle size={18} /> Berhasil disimpan
          </div>
        )}

        {/* EDIT KITAB METADATA VIEW */}
        {isEditing && (
          <div className="bg-white dark:bg-white/[0.03] p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-6">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {activeKitabId ? "Edit Kitab" : "Tambah Kitab Baru"}
            </h3>

            {error && <div className="text-sm text-red-600">{error}</div>}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Nama Kitab</label>
                <input
                  type="text"
                  value={form.nama}
                  onChange={(e) => setForm({ ...form, nama: e.target.value })}
                  placeholder="Contoh: Aqidatul Awam, Arbain Nawawi"
                  className="w-full px-3 py-2 border rounded-lg dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tipe Unit Hafalan</label>
                <select
                  value={form.tipeUnit}
                  onChange={(e: any) => setForm({ ...form, tipeUnit: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                >
                  <option value="bait">Bait (Nadhom/Syi'ir)</option>
                  <option value="hadits">Hadits (Kumpulan Hadits)</option>
                  <option value="halaman">Halaman (Kitab/Buku)</option>
                  <option value="nomor">Nomor (Umum)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Total Unit (Bait/Hadits/Hal)</label>
                <input
                  type="number"
                  value={form.totalUnit}
                  onChange={(e) => setForm({ ...form, totalUnit: Number(e.target.value) })}
                  min={1}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Deskripsi</label>
                <input
                  type="text"
                  value={form.deskripsi}
                  onChange={(e) => setForm({ ...form, deskripsi: e.target.value })}
                  placeholder="Keterangan singkat kitab..."
                  className="w-full px-3 py-2 border rounded-lg dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3">
              <button
                onClick={() => setIsEditing(false)}
                className="px-4 py-2 border rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05]"
              >
                Batal
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="px-4 py-2 text-white bg-brand-500 rounded-lg hover:bg-brand-600 font-semibold disabled:opacity-55"
              >
                {saving ? "Menyimpan..." : "Simpan"}
              </button>
            </div>
          </div>
        )}

        {/* EDIT KITAB TEXT CONTENT VIEW */}
        {isEditingContent && selectedKitab && (
          <div className="bg-white dark:bg-white/[0.03] p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-6">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsEditingContent(false)}
                className="p-2 border rounded-lg hover:bg-gray-50 dark:hover:bg-white/[0.05] text-gray-600 dark:text-gray-400"
              >
                <ChevronLeft size={18} />
              </button>
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                  Kelola Isi Teks: {selectedKitab.nama}
                </h3>
                <p className="text-xs text-gray-500">
                  Total: {selectedKitab.totalUnit} {selectedKitab.tipeUnit}
                </p>
              </div>
            </div>

            {/* Content list & mini-form */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Unit Navigation List */}
              <div className="lg:col-span-1 border rounded-xl overflow-hidden max-h-[500px] overflow-y-auto">
                <div className="bg-gray-50 dark:bg-white/[0.02] p-3 text-xs font-bold text-gray-500 border-b">
                  DAFTAR UNIT
                </div>
                <div className="divide-y">
                  {contents.map((c) => (
                    <button
                      key={c.index}
                      onClick={() => handleEditContent(c)}
                      className={`w-full p-3 text-left flex justify-between items-center transition ${
                        activeContentIndex === c.index
                          ? "bg-brand-50 dark:bg-brand-950/20 text-brand-600 font-semibold"
                          : "hover:bg-gray-50 dark:hover:bg-white/[0.02] text-gray-800 dark:text-gray-200"
                      }`}
                    >
                      <span>
                        {selectedKitab.tipeUnit.toUpperCase()} {c.index}
                      </span>
                      {c.text.trim() ? (
                        <span className="text-[10px] bg-green-100 text-green-800 px-2 py-0.5 rounded font-bold">
                          Terisi
                        </span>
                      ) : (
                        <span className="text-[10px] bg-gray-100 text-gray-500 px-2 py-0.5 rounded">
                          Kosong
                        </span>
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Text Input Panel */}
              <div className="lg:col-span-2 bg-gray-50 dark:bg-white/[0.01] p-6 rounded-xl border border-dashed flex flex-col justify-between">
                {activeContentIndex !== null ? (
                  <div className="space-y-4">
                    <div className="font-bold text-gray-900 dark:text-white">
                      Edit Teks: {selectedKitab.tipeUnit.toUpperCase()} {activeContentIndex}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Teks Arab / Asli
                      </label>
                      <textarea
                        value={contentForm.text}
                        onChange={(e) => setContentForm({ ...contentForm, text: e.target.value })}
                        rows={3}
                        dir="rtl"
                        placeholder="أكتب النص هنا..."
                        className="w-full p-3 border rounded-lg text-lg font-amiri dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white text-right"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Terjemahan Bahasa Indonesia
                      </label>
                      <textarea
                        value={contentForm.translation}
                        onChange={(e) => setContentForm({ ...contentForm, translation: e.target.value })}
                        rows={3}
                        placeholder="Tulis terjemahan di sini..."
                        className="w-full p-3 border rounded-lg text-sm dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                      />
                    </div>

                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => setActiveContentIndex(null)}
                        className="px-4 py-2 border rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50"
                      >
                        Batal
                      </button>
                      <button
                        onClick={handleSaveContent}
                        disabled={saving}
                        className="flex items-center gap-2 px-4 py-2 text-white bg-brand-500 rounded-lg hover:bg-brand-600 font-semibold"
                      >
                        <Save size={16} /> {saving ? "Menyimpan..." : "Simpan Teks"}
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="flex-1 flex flex-col items-center justify-center text-center p-8 text-gray-400">
                    <FileText size={48} className="mb-3" />
                    <p className="text-sm">Pilih unit di sebelah kiri untuk mengisi atau mengedit konten teks.</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* LIST TABLE VIEW */}
        {!isEditing && !isEditingContent && (
          <div className="bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800 overflow-hidden">
            {/* Search filter bar */}
            <div className="p-4 flex flex-col sm:flex-row items-center gap-3 bg-gray-50/50 dark:bg-white/[0.01] border-b">
              <div className="relative w-full sm:max-w-xs">
                <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Cari nama kitab..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border rounded-lg text-sm dark:bg-white/[0.05] dark:border-gray-700 text-gray-900 dark:text-white"
                />
              </div>
            </div>

            {loading ? (
              <div className="flex justify-center items-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-500"></div>
              </div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                <BookOpen size={48} className="mb-2" />
                <p className="text-sm">Belum ada kitab yang cocok atau terdaftar.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-gray-50/50 dark:bg-white/[0.02] border-b text-xs font-bold text-gray-500 uppercase">
                      <th className="p-4">Nama Kitab</th>
                      <th className="p-4">Tipe Unit</th>
                      <th className="p-4">Total Unit</th>
                      <th className="p-4">Deskripsi</th>
                      <th className="p-4 text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y text-sm text-gray-700 dark:text-gray-300">
                    {filtered.map((k) => (
                      <tr key={k.id} className="hover:bg-gray-50/50 dark:hover:bg-white/[0.01]">
                        <td className="p-4 font-semibold text-gray-900 dark:text-white">{k.nama}</td>
                        <td className="p-4">
                          <span className="capitalize px-2 py-1 rounded bg-brand-50 dark:bg-brand-950/20 text-brand-600 text-xs font-semibold">
                            {k.tipeUnit}
                          </span>
                        </td>
                        <td className="p-4">{k.totalUnit}</td>
                        <td className="p-4 text-gray-500">{k.deskripsi}</td>
                        <td className="p-4 text-right flex justify-end gap-2">
                          <button
                            onClick={() => loadContent(k)}
                            className="flex items-center gap-1 px-3 py-1.5 border rounded-lg text-xs font-semibold text-brand-600 hover:bg-brand-50 border-brand-100 transition"
                          >
                            <FileText size={14} /> Kelola Isi
                          </button>
                          <button
                            onClick={() => handleEdit(k)}
                            className="p-2 border rounded-lg hover:bg-gray-50 dark:hover:bg-white/[0.05] text-gray-600 dark:text-gray-400"
                          >
                            <Edit size={14} />
                          </button>
                          <button
                            onClick={() => handleDelete(k.id)}
                            className="p-2 border border-red-100 text-red-500 rounded-lg hover:bg-red-50 transition"
                          >
                            <Trash2 size={14} />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
    </>
  );
}
