import { useEffect, useState } from "react";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { Plus, Search, Trash2, ChevronLeft, List, ListOrdered, Type, Image as ImageIcon, Save, Smartphone, CheckCircle, Edit2 } from "lucide-react";
import { db, storage } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";

interface PondokItem {
  title: string;
  content: string;
  description: string;
  type: "paragraph" | "bullet" | "number";
  imagePath: string;
}

export default function PondokKnowledgeManagement() {
  const { profile } = useAuth();
  const [items, setItems] = useState<PondokItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [isEditing, setIsEditing] = useState(false);
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showSavedToast, setShowSavedToast] = useState(false);

  // Form State
  const [form, setForm] = useState<PondokItem>({
    title: "",
    content: "",
    description: "",
    type: "paragraph",
    imagePath: ""
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.pesantrenId) load();
  }, [profile?.pesantrenId]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const snap = await getDoc(doc(db, "pesantren", profile.pesantrenId, "settings", "pondok_knowledge"));
      if (snap.exists()) {
        setItems(snap.data().items || []);
      }
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const handleAddNew = () => {
    setForm({ title: "", content: "", description: "", type: "paragraph", imagePath: "" });
    setImagePreview(null); setImageFile(null); setActiveIndex(null); setIsEditing(true);
  };

  const handleEdit = (idx: number) => {
    setForm(items[idx]);
    setImagePreview(items[idx].imagePath || null);
    setActiveIndex(idx);
    setIsEditing(true);
  };

  const handleSave = async () => {
    if (!form.title.trim() || !form.content.trim()) { setError("Judul dan Konten tidak boleh kosong"); return; }
    setSaving(true);
    setError(null);
    try {
      let finalImagePath = form.imagePath;
      if (imageFile) {
        const fileRef = ref(storage, `pondok_knowledge/${profile?.pesantrenId}_${Date.now()}.jpg`);
        const up = await uploadBytes(fileRef, imageFile);
        finalImagePath = await getDownloadURL(up.ref);
      }

      const cleanedContent = form.content.split('\n').filter(l => l.trim() !== "").join('\n');
      const updatedItem = { ...form, content: cleanedContent, imagePath: finalImagePath };
      const newList = [...items];

      if (activeIndex !== null) newList[activeIndex] = updatedItem;
      else newList.push(updatedItem);

      await setDoc(doc(db, "pesantren", profile!.pesantrenId as string, "settings", "pondok_knowledge"), {
        items: newList, initialized: true
      }, { merge: true });

      setItems(newList);
      setShowSavedToast(true);
      setTimeout(() => setShowSavedToast(false), 2000);
      setIsEditing(false);
    } catch (err: any) {
      setError(err.message);
    } finally { setSaving(false); }
  };

  const handleDelete = async (idx: number) => {
    if (!window.confirm("Hapus materi ini?")) return;
    const newList = items.filter((_, i) => i !== idx);
    try {
      await setDoc(doc(db, "pesantren", profile!.pesantrenId as string, "settings", "pondok_knowledge"), { items: newList }, { merge: true });
      setItems(newList);
    } catch (err) { alert("Gagal menghapus"); }
  };

  const filtered = items.filter(it => it.title.toLowerCase().includes(search.toLowerCase()));

  // Render the Listing UI
  if (!isEditing) {
    return (
      <div className="space-y-8 animate-in fade-in duration-500">
        <PageMeta title="Materi Pondok | Admin" description="Kelola profil dan materi hafalan pesantren." />

        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div className="text-left">
            <h2 className="text-3xl font-black text-gray-900 dark:text-white">Materi Pondok</h2>
            <p className="text-gray-500 text-sm mt-1">Buat profil, sejarah, atau visi misi yang tampil di aplikasi santri.</p>
          </div>
          <button onClick={handleAddNew} className="flex items-center gap-2 px-6 py-3 bg-brand-500 hover:bg-brand-600 text-white rounded-2xl font-bold shadow-lg shadow-brand-500/20 transition-all active:scale-95">
            <Plus size={20}/> Tambah Baru
          </button>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Cari judul materi..." className="w-full pl-12 pr-4 py-4 bg-white dark:bg-white/5 border-none rounded-[2rem] shadow-sm focus:ring-2 focus:ring-brand-500/20 dark:text-white text-lg" />
        </div>

        {loading ? (
          <div className="flex justify-center py-20"><div className="w-10 h-10 border-4 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center bg-gray-50 dark:bg-white/5 rounded-[3rem] border-2 border-dashed border-gray-200 dark:border-gray-800">
             <Plus size={48} className="mx-auto text-gray-300 mb-4" />
             <p className="text-gray-400 font-bold">Belum ada materi. Mulai dengan membuat satu.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filtered.map((it, i) => (
              <div key={i} className="group bg-white dark:bg-gray-800 rounded-[2.5rem] p-6 shadow-sm hover:shadow-xl transition-all border border-gray-100 dark:border-gray-700 flex flex-col">
                <div className="flex items-center justify-between mb-6">
                   <div className={`p-3 rounded-2xl ${it.type === 'bullet' ? 'bg-blue-50 text-blue-500' : it.type === 'number' ? 'bg-purple-50 text-purple-500' : 'bg-emerald-50 text-emerald-500'}`}>
                      {it.type === 'bullet' ? <List size={24}/> : it.type === 'number' ? <ListOrdered size={24}/> : <Type size={24}/>}
                   </div>
                   <div className="flex gap-1">
                      <button onClick={() => handleEdit(i)} className="p-2 text-gray-400 hover:bg-gray-50 rounded-full transition-colors"><Edit2 size={18}/></button>
                      <button onClick={() => handleDelete(i)} className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition-colors"><Trash2 size={18}/></button>
                   </div>
                </div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2 text-left">{it.title}</h3>
                <p className="text-gray-500 text-sm line-clamp-2 mb-6 text-left flex-1">{it.description || it.content}</p>
                {it.imagePath && <img src={it.imagePath} className="w-full h-32 object-cover rounded-3xl" alt=""/>}
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // Render the "Writing Studio" UI (Full Screen Editor)
  return (
    <div className="fixed inset-0 z-[60] bg-[#FDF9F0] dark:bg-gray-950 flex flex-col animate-in slide-in-from-bottom duration-500">
      <div className="max-w-7xl mx-auto w-full flex-1 flex flex-col lg:flex-row overflow-hidden">

        {/* LEFT: The Editor (Focused Column) */}
        <div className="flex-1 flex flex-col bg-white dark:bg-gray-900 shadow-2xl lg:rounded-[3rem] lg:my-6 lg:ml-6 overflow-hidden">
           {/* Header / Actions */}
           <div className="px-8 py-6 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
              <button onClick={() => setIsEditing(false)} className="flex items-center gap-2 text-gray-500 hover:text-gray-900 font-bold text-sm">
                <ChevronLeft size={20}/> KEMBALI
              </button>
              <div className="flex items-center gap-4">
                 {error && <span className="text-red-500 text-xs font-bold">{error}</span>}
                 <button onClick={handleSave} disabled={saving} className="flex items-center gap-2 px-8 py-2.5 bg-brand-500 hover:bg-brand-600 text-white rounded-full font-black text-[10px] tracking-widest shadow-lg shadow-brand-500/30 disabled:opacity-50">
                    <Save size={16}/> {saving ? "MENYIMPAN..." : "PUBLIKASIKAN"}
                 </button>
              </div>
           </div>

           {/* Writing Area */}
           <div className="flex-1 overflow-y-auto custom-scrollbar p-12 lg:p-20 text-left">
              <div className="max-w-2xl mx-auto space-y-12">

                 {/* Title & Description */}
                 <div className="space-y-4">
                    <input autoFocus value={form.title} onChange={e => setForm({...form, title: e.target.value})} placeholder="Judul Materi..." className="w-full bg-transparent border-none outline-none text-4xl font-black text-gray-900 dark:text-white placeholder:text-gray-100" />
                    <input value={form.description} onChange={e => setForm({...form, description: e.target.value})} placeholder="Deskripsi ringkas (Sub-judul)..." className="w-full bg-transparent border-none outline-none text-lg text-gray-400 placeholder:text-gray-200" />
                 </div>

                 <div className="flex items-center gap-6 border-y border-gray-50 dark:border-gray-800 py-6">
                    <span className="text-[10px] font-black text-gray-300 uppercase tracking-widest">FORMAT VISUAL</span>
                    <div className="flex bg-gray-100 dark:bg-gray-800 p-1 rounded-2xl">
                       {(['paragraph', 'bullet', 'number'] as const).map(t => (
                         <button key={t} onClick={() => setForm({...form, type: t})} className={`px-5 py-2 rounded-xl text-[10px] font-bold transition-all ${form.type === t ? 'bg-white dark:bg-gray-700 text-brand-600 shadow-sm' : 'text-gray-400'}`}>
                           {t.toUpperCase()}
                         </button>
                       ))}
                    </div>
                 </div>

                 {/* Content */}
                 <textarea required rows={12} value={form.content} onChange={e => setForm({...form, content: e.target.value})} placeholder="Tulis konten di sini. Setiap baris baru akan otomatis menjadi poin jika format List dipilih." className="w-full bg-transparent border-none outline-none text-xl leading-relaxed text-gray-700 dark:text-gray-300 placeholder:text-gray-100 resize-none font-serif" />

                 {/* Image */}
                 <div className="pt-10">
                    <label className="block w-full h-48 border-4 border-dashed border-gray-100 dark:border-gray-800 rounded-[3rem] cursor-pointer hover:bg-gray-50 transition-all overflow-hidden group relative">
                       {imagePreview ? (
                         <>
                           <img src={imagePreview} className="w-full h-full object-cover" alt=""/>
                           <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white font-bold"><ImageIcon size={32}/></div>
                         </>
                       ) : (
                         <div className="flex flex-col items-center justify-center h-full text-gray-300">
                            <ImageIcon size={40} className="mb-2"/>
                            <span className="text-xs font-bold uppercase tracking-widest">Unggah Foto Ilustrasi</span>
                         </div>
                       )}
                       <input type="file" accept="image/*" onChange={e => {
                         const file = e.target.files?.[0];
                         if (file) { setImageFile(file); setImagePreview(URL.createObjectURL(file)); }
                       }} className="hidden" />
                    </label>
                 </div>
              </div>
           </div>
        </div>

        {/* RIGHT: Mobile Preview (Designer's Satisfaction) */}
        <div className="hidden lg:flex w-[480px] flex-col items-center justify-center p-12">
           <div className="relative">
              {/* Device Mockup */}
              <div className="w-[300px] h-[600px] bg-[#FDF9F0] border-[12px] border-slate-900 rounded-[3.5rem] shadow-2xl overflow-hidden flex flex-col">
                 <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-900 rounded-b-2xl z-20"></div>
                 <div className="bg-[#2E5A27] text-white pt-8 pb-4 px-6 text-[10px] font-black tracking-widest text-center">TENTANG PONDOK</div>
                 <div className="flex-1 overflow-y-auto p-6 custom-scrollbar text-left">
                    <h4 className="text-[#2E5A27] font-black text-xl mb-1 leading-tight">{form.title || "Judul Utama"}</h4>
                    <p className="text-gray-400 text-[10px] mb-4 italic">{form.description || "Sub-judul materi"}</p>
                    <div className="w-full h-px bg-[#E5D5B8] mb-5"></div>
                    {imagePreview && <img src={imagePreview} className="w-full h-32 object-cover rounded-2xl mb-5 shadow-sm" alt=""/>}
                    <div className="space-y-4">
                       {form.content.split('\n').filter(l => l.trim() !== "").map((line, i) => (
                         <div key={i} className="flex gap-3 text-xs leading-relaxed">
                           {form.type === 'bullet' && <div className="mt-2 w-1.5 h-1.5 rounded-full bg-[#2E5A27] shrink-0" />}
                           {form.type === 'number' && <div className="w-5 h-5 rounded-full bg-[#2E5A27]/10 text-[#2E5A27] text-[10px] font-black flex items-center justify-center shrink-0">{i+1}</div>}
                           <div className="text-[#4E342E] flex-1 font-medium">{line}</div>
                         </div>
                       ))}
                    </div>
                 </div>
              </div>
              <div className="absolute -bottom-10 left-1/2 -translate-x-1/2 flex items-center gap-2 text-gray-400 text-[10px] font-black tracking-widest uppercase">
                 <Smartphone size={14}/> Live Sync Active
              </div>
           </div>
        </div>

      </div>

      {showSavedToast && (
        <div className="fixed bottom-10 left-1/2 -translate-x-1/2 flex items-center gap-3 bg-emerald-500 text-white px-8 py-4 rounded-full shadow-2xl font-bold animate-in fade-in slide-in-from-bottom-4">
           <CheckCircle size={20}/> MATERI BERHASIL DIPUBLIKASIKAN
        </div>
      )}
    </div>
  );
}
