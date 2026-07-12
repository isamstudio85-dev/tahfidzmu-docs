import { useEffect, useState } from "react";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { Plus, Search, Trash2, Edit3, FileText, List, ListOrdered, Image as ImageIcon, X, Save, AlertCircle, Smartphone, CheckCircle2, ChevronRight } from "lucide-react";
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
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // Studio State
  const [isEditing, setIsEditing] = useState(false);
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
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

  const handleCreateNew = () => {
    setForm({ title: "", content: "", description: "", type: "paragraph", imagePath: "" });
    setImageFile(null); setImagePreview(null); setActiveIndex(null); setIsEditing(true); setSuccess(false);
  };

  const handleSelectEdit = (idx: number) => {
    const item = items[idx];
    setForm(item);
    setActiveIndex(idx);
    setImagePreview(item.imagePath || null);
    setImageFile(null);
    setIsEditing(true);
    setSuccess(false);
  };

  const handleSave = async () => {
    if (!form.title.trim() || !form.content.trim()) { setError("Judul dan Isi wajib diisi"); return; }
    setSaving(true);
    setError(null);
    try {
      let finalImagePath = form.imagePath;
      if (imageFile) {
        const fileRef = ref(storage, `pondok_knowledge/${profile?.pesantrenId}_${Date.now()}.jpg`);
        const up = await uploadBytes(fileRef, imageFile);
        finalImagePath = await getDownloadURL(up.ref);
      }

      const cleanedContent = form.content.split('\n').filter(line => line.trim() !== "").join('\n');
      const updatedItem = { ...form, content: cleanedContent, imagePath: finalImagePath };
      const newList = [...items];

      if (activeIndex !== null) { newList[activeIndex] = updatedItem; }
      else { newList.push(updatedItem); }

      await setDoc(doc(db, "pesantren", profile!.pesantrenId, "settings", "pondok_knowledge"), {
        items: newList, initialized: true
      }, { merge: true });

      setItems(newList);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message);
    } finally { setSaving(false); }
  };

  const handleDelete = async (idx: number, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!window.confirm("Hapus materi ini?")) return;
    const newList = items.filter((_, i) => i !== idx);
    try {
      await setDoc(doc(db, "pesantren", profile!.pesantrenId, "settings", "pondok_knowledge"), { items: newList }, { merge: true });
      setItems(newList);
      if (activeIndex === idx) setIsEditing(false);
    } catch (err) { alert("Gagal menghapus"); }
  };

  const filtered = items.filter(it => it.title.toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="h-[calc(100vh-100px)] flex flex-col bg-gray-50/50 dark:bg-transparent -m-6 overflow-hidden">
      <PageMeta title="Pondok Studio | TahfidzMU" description="Ruang kreatif pengelola materi pesantren." />

      <div className="flex-1 flex overflow-hidden">

        {/* COLUMN 1: Material Explorer */}
        <div className={`w-80 flex flex-col bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 transition-all ${isEditing ? 'hidden lg:flex' : 'flex w-full lg:w-80'}`}>
           <div className="p-6 border-b border-gray-100 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 backdrop-blur-xl sticky top-0 z-10">
              <h2 className="text-lg font-black text-gray-900 dark:text-white tracking-tight">EXPLORER</h2>
              <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mt-1">Daftar Materi Pondok</p>

              <div className="mt-6 relative">
                 <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                 <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Cari materi..." className="w-full pl-9 pr-4 py-2 bg-gray-100 dark:bg-gray-800 rounded-xl text-xs outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white" />
              </div>

              <button onClick={handleCreateNew} className="w-full mt-4 flex items-center justify-center gap-2 py-3 bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold rounded-xl shadow-lg shadow-brand-500/20 transition-all active:scale-95">
                 <Plus size={16}/> TAMBAH MATERI
              </button>
           </div>

           <div className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-2">
              {loading ? (
                <div className="flex justify-center p-8"><div className="w-6 h-6 border-2 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
              ) : filtered.length === 0 ? (
                <div className="text-center py-12 px-6 border-2 border-dashed border-gray-100 dark:border-gray-800 rounded-3xl text-gray-300 italic text-xs">Belum ada materi</div>
              ) : (
                filtered.map((it, i) => (
                  <div key={i} onClick={() => handleSelectEdit(i)} className={`group p-4 rounded-2xl cursor-pointer transition-all flex items-center gap-3 border ${activeIndex === i ? 'bg-brand-50 border-brand-200 dark:bg-brand-500/10 dark:border-brand-500/50' : 'bg-white dark:bg-gray-800 border-transparent hover:border-gray-200 dark:hover:border-gray-700'}`}>
                    <div className={`p-2 rounded-xl ${activeIndex === i ? 'bg-brand-500 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-400'}`}>
                      {it.type === 'bullet' ? <List size={14}/> : it.type === 'number' ? <ListOrdered size={14}/> : <FileText size={14}/>}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className={`text-xs font-bold truncate ${activeIndex === i ? 'text-brand-700 dark:text-brand-400' : 'text-gray-700 dark:text-gray-200'}`}>{it.title}</h4>
                      <p className="text-[10px] text-gray-400 truncate">{it.description || "Klik untuk mengedit"}</p>
                    </div>
                    <button onClick={(e) => handleDelete(i, e)} className="p-1.5 opacity-0 group-hover:opacity-100 text-gray-400 hover:text-red-500 transition-all"><Trash2 size={12}/></button>
                  </div>
                ))
              )}
           </div>
        </div>

        {/* COLUMN 2: Designer Canvas (The Editor) */}
        {isEditing ? (
          <div className="flex-1 flex flex-col bg-white dark:bg-gray-950 overflow-hidden relative shadow-inner">
            <div className="px-8 py-4 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
               <div className="flex items-center gap-3">
                  <button onClick={() => setIsEditing(false)} className="lg:hidden p-2 -ml-2 text-gray-400 hover:bg-gray-100 rounded-full"><X size={20}/></button>
                  <h3 className="text-sm font-black text-gray-900 dark:text-white tracking-widest uppercase">{activeIndex !== null ? "Editor Materi" : "Kanvas Baru"}</h3>
               </div>
               <div className="flex items-center gap-4">
                  {success && <div className="flex items-center gap-2 text-emerald-500 text-[10px] font-bold animate-fade-in"><CheckCircle2 size={14}/> BERHASIL DISIMPAN</div>}
                  <button onClick={handleSave} disabled={saving} className="inline-flex items-center gap-2 px-6 py-2 bg-brand-500 hover:bg-brand-600 text-white text-[10px] font-black tracking-widest rounded-full transition-all disabled:opacity-50 shadow-lg shadow-brand-500/25">
                    <Save size={14}/> {saving ? "PROSES..." : "SAVE"}
                  </button>
               </div>
            </div>

            <div className="flex-1 overflow-y-auto p-12 custom-scrollbar flex justify-center">
               <div className="w-full max-w-2xl space-y-10">
                  {error && <div className="p-4 bg-red-50 border border-red-100 text-red-700 text-xs rounded-2xl flex items-center gap-3"><AlertCircle size={16}/> {error}</div>}

                  {/* Visual Header Input */}
                  <div className="space-y-4">
                    <input value={form.title} onChange={e => setForm({...form, title: e.target.value})} placeholder="Ketik Judul Besar di Sini..." className="w-full bg-transparent text-3xl font-black text-gray-900 dark:text-white placeholder:text-gray-200 dark:placeholder:text-gray-800 outline-none border-none" />
                    <textarea value={form.description} onChange={e => setForm({...form, description: e.target.value})} placeholder="Tulis deskripsi singkat atau pengantar materi..." className="w-full bg-transparent text-sm text-gray-400 placeholder:text-gray-300 outline-none border-none resize-none h-12" />
                  </div>

                  <div className="h-px bg-gray-100 dark:bg-gray-800"></div>

                  {/* Format Selector (Designer Style) */}
                  <div className="flex items-center gap-8">
                     <span className="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Format Visual</span>
                     <div className="flex gap-2">
                        {(['paragraph', 'bullet', 'number'] as const).map(t => (
                          <button key={t} onClick={() => setForm({...form, type: t})} className={`px-4 py-1.5 text-[10px] font-bold rounded-full border transition-all ${form.type === t ? 'bg-gray-900 text-white border-gray-900 dark:bg-white dark:text-gray-900' : 'border-gray-200 text-gray-400 hover:border-gray-900'}`}>
                             {t.toUpperCase()}
                          </button>
                        ))}
                     </div>
                  </div>

                  {/* Main Content (Notion Style) */}
                  <div className="relative group">
                     <textarea required rows={15} value={form.content} onChange={e => setForm({...form, content: e.target.value})} placeholder="Tulis konten Anda di sini. Gunakan baris baru untuk memisahkan poin..." className="w-full bg-transparent text-gray-700 dark:text-gray-300 text-lg leading-relaxed placeholder:text-gray-100 dark:placeholder:text-gray-900 outline-none border-none resize-none font-serif" />
                     <div className="absolute -left-6 top-1.5 text-gray-100 dark:text-gray-900"><ChevronRight size={24}/></div>
                  </div>

                  {/* Media Dropzone */}
                  <div className="space-y-4 pt-10">
                    <span className="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Ilustrasi Visual</span>
                    <label className="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-gray-200 dark:border-gray-800 rounded-[2rem] cursor-pointer hover:bg-gray-50 dark:hover:bg-white/[0.02] transition-all overflow-hidden relative group">
                        {imagePreview ? (
                          <>
                            <img src={imagePreview} className="w-full h-full object-cover" alt=""/>
                            <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"><ImageIcon className="text-white" size={32}/></div>
                          </>
                        ) : (
                          <div className="text-center p-6 flex flex-col items-center">
                            <ImageIcon size={32} className="text-gray-200 mb-2"/>
                            <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Upload Photo</p>
                          </div>
                        )}
                        <input type="file" accept="image/*" onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            setImageFile(file);
                            setImagePreview(URL.createObjectURL(file));
                          }
                        }} className="hidden"/>
                    </label>
                  </div>
                  <div className="h-20"></div>
               </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center bg-white dark:bg-gray-950">
             <div className="p-10 border-2 border-dashed border-gray-100 dark:border-gray-900 rounded-[3rem] text-center max-w-sm">
                <Edit3 size={48} className="mx-auto text-gray-100 mb-4" />
                <h3 className="text-lg font-bold text-gray-300">STUDIO MATERIPONDOK</h3>
                <p className="text-xs text-gray-400 mt-2 leading-relaxed uppercase tracking-widest">Pilih materi di samping atau buat baru untuk mulai mendesain konten pesantren Anda.</p>
             </div>
          </div>
        )}

        {/* COLUMN 3: Phone Sync Preview (The Result) */}
        {isEditing && (
          <div className="w-[450px] bg-gray-50 dark:bg-black/20 border-l border-gray-200 dark:border-gray-800 hidden xl:flex flex-col items-center justify-center p-8 relative overflow-hidden">
             <div className="absolute top-0 right-0 p-8 text-[100px] font-black text-gray-200/20 select-none -z-10 tracking-tighter">PREVIEW</div>

             <div className="relative">
                {/* Phone Frame */}
                <div className="w-[300px] h-[600px] bg-[#FDF9F0] border-[12px] border-slate-900 rounded-[3rem] shadow-2xl overflow-hidden flex flex-col">
                   <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-6 bg-slate-900 rounded-b-2xl z-20"></div>
                   <div className="bg-[#2E5A27] text-white pt-8 pb-4 px-6 text-xs font-black tracking-widest text-center">
                      PENGETAHUAN PONDOK
                   </div>
                   <div className="flex-1 overflow-y-auto p-6 custom-scrollbar">
                      <h4 className="text-[#2E5A27] font-black text-xl mb-1">{form.title || "Judul Materi"}</h4>
                      <p className="text-gray-500 text-[10px] mb-4 italic leading-relaxed">{form.description || "Keterangan singkat"}</p>
                      <div className="w-full h-px bg-[#E5D5B8] mb-5"></div>

                      {imagePreview && <img src={imagePreview} className="w-full h-32 object-cover rounded-2xl mb-5 shadow-md" alt=""/>}

                      <div className="space-y-4">
                         {(form.content.split('\n').filter(l => l.trim() !== "")).map((line, i) => (
                           <div key={i} className="flex gap-3 text-xs leading-relaxed">
                             {form.type === 'bullet' && <div className="mt-2 w-1.5 h-1.5 rounded-full bg-[#2E5A27] shrink-0" />}
                             {form.type === 'number' && <div className="w-6 h-6 rounded-full bg-[#2E5A27]/10 text-[#2E5A27] text-[10px] font-black flex items-center justify-center shrink-0">{i+1}</div>}
                             <div className="text-[#4E342E] flex-1 font-medium">{line}</div>
                           </div>
                         ))}
                      </div>
                   </div>
                </div>
                {/* Smartphone Badge */}
                <div className="absolute -bottom-10 left-1/2 -translate-x-1/2 flex items-center gap-2 text-gray-400 font-bold text-[10px] tracking-widest uppercase">
                   <Smartphone size={14}/> Real-time Sync
                </div>
             </div>
          </div>
        )}

      </div>
    </div>
  );
}
