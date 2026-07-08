import { useEffect, useState } from "react";
import { collection, deleteDoc, doc, getDocs, setDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { QRCodeSVG } from "qrcode.react";
import { Edit2, Plus, QrCode, Search, ShieldAlert, Trash2, Upload, X } from "lucide-react";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";

interface Mapping {
  linkedId: string;
  role: string;
  defaultPassword: string;
}

export default function PengawasManagement() {
  const { profile } = useAuth();
  const [list, setList] = useState<any[]>([]);
  const [mappings, setMappings] = useState<Record<string, Mapping>>({});
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [existingId, setExistingId] = useState("");
  const [existingMappingKey, setExistingMappingKey] = useState("");
  const [name, setName] = useState("");
  const [nip, setNip] = useState("");
  const [password, setPassword] = useState("");
  const [noHp, setNoHp] = useState("");
  const [jabatan, setJabatan] = useState("Pengawas");
  const [status, setStatus] = useState("aktif");
  const [catatan, setCatatan] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [existingPhotoPath, setExistingPhotoPath] = useState<string | null>(null);

  const [qrOpen, setQrOpen] = useState(false);
  const [selected, setSelected] = useState<any>(null);

  useEffect(() => {
    if (profile?.pesantrenId) {
      load();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const load = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;
      const mapSnap = await getDocs(collection(db, "pesantren", pid, "user_mappings"));
      const nextMappings: Record<string, Mapping> = {};
      mapSnap.forEach((entry) => {
        nextMappings[entry.id] = entry.data() as Mapping;
      });
      setMappings(nextMappings);

      const snap = await getDocs(collection(db, "pesantren", pid, "pengawas"));
      setList(snap.docs.map((entry) => ({ id: entry.id, ...entry.data() })));
    } catch (loadError) {
      console.error("Error loading pengawas:", loadError);
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setName("");
    setNip("");
    setPassword("");
    setNoHp("");
    setJabatan("Pengawas");
    setStatus("aktif");
    setCatatan("");
    setExistingMappingKey("");
    setPhotoFile(null);
    setPhotoPreview(null);
    setExistingPhotoPath(null);
    setError(null);
  };

  const handleOpenAdd = () => {
    setIsEdit(false);
    setExistingId("");
    resetForm();
    setIsOpen(true);
  };

  const handleOpenEdit = (item: any) => {
    const entry = Object.entries(mappings).find(([, value]) => value.linkedId === item.id);
    setIsEdit(true);
    setExistingId(item.id);
    setExistingMappingKey(entry?.[0] || String(item.nip || item.username || "").replace(/\D/g, ""));
    setName(item.nama || "");
    setNip(item.nip || item.username || "");
    setPassword("");
    setNoHp(item.nomorHp || "");
    setJabatan(item.jabatan || "Pengawas");
    setStatus(item.status || "aktif");
    setCatatan(item.catatan || "");
    setPhotoFile(null);
    setPhotoPreview(null);
    setExistingPhotoPath(item.photoPath || null);
    setError(null);
    setIsOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError("Ukuran foto maksimal 2MB");
      return;
    }
    setPhotoFile(file);
    setPhotoPreview(URL.createObjectURL(file));
    setError(null);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const pid = profile?.pesantrenId;
    if (!pid) return;

    const rawNip = nip.trim();
    const normalizedNip = rawNip.replace(/\D/g, "");
    if (!name.trim() || !rawNip) {
      setError("Nama dan NIP wajib diisi");
      return;
    }
    if (!normalizedNip) {
      setError("NIP harus mengandung angka");
      return;
    }
    if (!isEdit && password.trim() && password.trim().length < 6) {
      setError("Sandi minimal 6 karakter");
      return;
    }
    if (isEdit && password.trim() && password.trim().length < 6) {
      setError("Sandi baru minimal 6 karakter");
      return;
    }

    setError(null);
    setSaving(true);
    try {
      const docId = isEdit ? existingId : doc(collection(db, "pesantren", pid, "pengawas")).id;
      const pengawasRef = doc(db, "pesantren", pid, "pengawas", docId);
      let finalPhotoUrl = existingPhotoPath;

      if (photoFile) {
        try {
          const photoRef = ref(storage, `pengawas_photos/${docId}.jpg`);
          const uploaded = await uploadBytes(photoRef, photoFile);
          finalPhotoUrl = await getDownloadURL(uploaded.ref);
        } catch (uploadError) {
          console.warn("Upload foto gagal:", uploadError);
        }
      }

      await setDoc(
        pengawasRef,
        {
          id: docId,
          nama: name.trim(),
          nip: rawNip,
          username: rawNip,
          nomorHp: noHp.trim(),
          jabatan: jabatan || "Pengawas",
          status,
          photoPath: finalPhotoUrl || null,
          catatan: catatan.trim() || null,
        },
        { merge: true }
      );

      const nextMappingKey = normalizedNip;
      const currentMappingKey = existingMappingKey || nextMappingKey;
      const currentDefaultPassword = mappings[currentMappingKey]?.defaultPassword || currentMappingKey;
      const nextDefaultPassword = password.trim() || currentDefaultPassword || nextMappingKey;

      if (!isEdit) {
        await setDoc(
          doc(db, "pesantren", pid, "user_mappings", nextMappingKey),
          {
            linkedId: docId,
            role: "pengawas",
            defaultPassword: password.trim() || nextMappingKey,
          },
          { merge: true }
        );
      } else {
        await setDoc(
          doc(db, "pesantren", pid, "user_mappings", nextMappingKey),
          {
            linkedId: docId,
            role: "pengawas",
            defaultPassword: nextDefaultPassword,
          },
          { merge: true }
        );

        if (currentMappingKey && currentMappingKey !== nextMappingKey) {
          await deleteDoc(doc(db, "pesantren", pid, "user_mappings", currentMappingKey)).catch(() => {});
        }
      }

      setIsOpen(false);
      load();
    } catch (saveError: any) {
      console.error(saveError);
      setError(`Gagal menyimpan: ${saveError.message}`);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (item: any) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm(`Hapus akun "${item.nama}" dari sistem?`)) return;
    try {
      const pid = profile.pesantrenId;
      await deleteDoc(doc(db, "pesantren", pid, "pengawas", item.id));
      const entry = Object.entries(mappings).find(([, value]) => value.linkedId === item.id);
      if (entry) {
        await deleteDoc(doc(db, "pesantren", pid, "user_mappings", entry[0])).catch(() => {});
      }
      const legacyKeys = [item.nip, item.username]
        .map((value: string | undefined) => String(value || "").replace(/\D/g, ""))
        .filter(Boolean);
      for (const legacyKey of legacyKeys) {
        await deleteDoc(doc(db, "pesantren", pid, "user_mappings", legacyKey)).catch(() => {});
      }
      load();
    } catch (deleteError) {
      console.error(deleteError);
      alert("Gagal menghapus");
    }
  };

  const handleOpenQr = (item: any) => {
    const entry = Object.entries(mappings).find(([, value]) => value.linkedId === item.id);
    const fallbackKey = String(item.nip || item.username || item.id || "").replace(/\D/g, "") || item.id;
    const loginKey = entry ? entry[0] : fallbackKey;
    const pwd = entry?.[1]?.defaultPassword || loginKey;
    setSelected({
      ...item,
      qrValue: `tahfidzmu:login:${profile?.pesantrenId}:${loginKey}:${pwd}`,
    });
    setQrOpen(true);
  };

  if (profile?.role !== "admin" && profile?.role !== "superAdmin") {
    return (
      <div className="flex min-h-[400px] flex-col items-center justify-center rounded-2xl border border-gray-200 bg-white p-6 text-center dark:border-gray-800 dark:bg-white/[0.03]">
        <ShieldAlert size={48} className="mb-4 text-error-500" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Halaman ini hanya untuk Administrator.</p>
      </div>
    );
  }

  const filtered = [...list]
    .filter((item) => {
      const needle = search.toLowerCase();
      return [item.nama, item.nip, item.username, item.jabatan].join(" ").toLowerCase().includes(needle);
    })
    .sort((a, b) => String(a.nama || "").localeCompare(String(b.nama || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Kelola Pengawas | TahfidzMU Admin" description="Administrasi data pengawas dan pimpinan pondok." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Data Pengawas</h2>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Kelola pimpinan dan pengawas yang memiliki akses web/aplikasi.</p>
          </div>
          <button onClick={handleOpenAdd} className="flex items-center justify-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-600"><Plus size={18} /> Tambah Pengawas</button>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari nama, NIP, jabatan..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-11 pr-4 focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-800 dark:bg-white/[0.03] dark:text-white" />
        </div>

        {loading ? (
          <div className="flex min-h-[200px] items-center justify-center"><div className="h-8 w-8 animate-spin rounded-full border-3 border-brand-500 border-t-transparent"></div></div>
        ) : (
          <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-white/[0.02] dark:text-gray-400">
                    <th className="p-4">Pengawas</th>
                    <th className="p-4">NIP</th>
                    <th className="p-4">Jabatan</th>
                    <th className="p-4">No. HP</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {filtered.length === 0 ? (
                    <tr><td colSpan={6} className="p-8 text-center text-gray-500">Belum ada data pengawas.</td></tr>
                  ) : filtered.map((item) => (
                    <tr key={item.id} className="text-gray-700 hover:bg-gray-50/50 dark:text-gray-300 dark:hover:bg-white/[0.01]">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          {item.photoPath ? (
                            <img src={item.photoPath} alt={item.nama} className="h-10 w-10 rounded-full object-cover" />
                          ) : (
                            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-brand-50 font-bold text-brand-500 dark:bg-brand-500/10">
                              {(item.nama || "P").charAt(0).toUpperCase()}
                            </div>
                          )}
                          <div>
                            <p className="font-semibold text-gray-900 dark:text-white">{item.nama}</p>
                            {item.catatan ? <p className="text-xs text-gray-500 dark:text-gray-400">{item.catatan}</p> : null}
                          </div>
                        </div>
                      </td>
                      <td className="p-4 font-mono font-bold text-gray-900 dark:text-white">{item.nip || item.username || "-"}</td>
                      <td className="p-4">{item.jabatan || "Pengawas"}</td>
                      <td className="p-4">{item.nomorHp || "-"}</td>
                      <td className="p-4">
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${item.status === "nonaktif" ? "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300" : "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"}`}>
                          {item.status === "nonaktif" ? "Nonaktif" : "Aktif"}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-2">
                          <button onClick={() => handleOpenQr(item)} title="Kartu Login" className="p-1.5 text-gray-400 hover:text-brand-500"><QrCode size={16} /></button>
                          <button onClick={() => handleOpenEdit(item)} title="Edit" className="p-1.5 text-gray-400 hover:text-blue-600"><Edit2 size={16} /></button>
                          <button onClick={() => handleDelete(item)} title="Hapus" className="p-1.5 text-gray-400 hover:text-error-500"><Trash2 size={16} /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
          <div className="my-8 w-full max-w-2xl rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <h3 className="mb-4 text-lg font-bold text-gray-800 dark:text-white">{isEdit ? "Edit Pengawas" : "Tambah Pengawas"}</h3>
            {error && <div className="mb-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-4">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <Field label="Nama Lengkap *"><input required value={name} onChange={(e) => setName(e.target.value)} className={inputCls} /></Field>
                <Field label="NIP Login *"><input required value={nip} onChange={(e) => setNip(e.target.value)} placeholder="contoh: 1987654321" className={inputCls} /></Field>
                <Field label="No. HP / WhatsApp"><input value={noHp} onChange={(e) => setNoHp(e.target.value)} className={inputCls} /></Field>
                <Field label="Jabatan *">
                  <select value={jabatan} onChange={(e) => setJabatan(e.target.value)} className={inputCls}>
                    <option value="Pimpinan">Pimpinan</option>
                    <option value="Pengawas">Pengawas</option>
                  </select>
                </Field>
                <Field label="Status">
                  <select value={status} onChange={(e) => setStatus(e.target.value)} className={inputCls}>
                    <option value="aktif">Aktif</option>
                    <option value="nonaktif">Nonaktif</option>
                  </select>
                </Field>
              </div>

              {!isEdit && (
                <div className="grid grid-cols-1 gap-4 rounded-xl border border-dashed border-gray-200 p-3 dark:border-gray-700 sm:grid-cols-2">
                  <Field label="ID Login"><input disabled value={existingMappingKey || nip.replace(/\D/g, "") || "-"} className={inputCls + " opacity-70"} /></Field>
                  <Field label="Sandi Login (opsional)"><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="default: sama dengan NIP" className={inputCls} /></Field>
                </div>
              )}

              {isEdit && (
                <div className="grid grid-cols-1 gap-4 rounded-xl border border-dashed border-gray-200 p-3 dark:border-gray-700 sm:grid-cols-2">
                  <Field label="ID Login"><input disabled value={nip.replace(/\D/g, "") || existingMappingKey || "-"} className={inputCls + " opacity-70"} /></Field>
                  <Field label="Ganti Sandi Login (opsional)"><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="kosongkan jika tidak diubah" className={inputCls} /></Field>
                </div>
              )}

              <Field label="Catatan"><textarea rows={3} value={catatan} onChange={(e) => setCatatan(e.target.value)} className={inputCls + " resize-none"} /></Field>

              <div>
                <label className={labelCls}>Foto Profil</label>
                <div className="flex items-center gap-3">
                  {(photoPreview || existingPhotoPath) ? (
                    <div className="relative">
                      <img src={photoPreview || existingPhotoPath || ""} alt="Foto" className="h-16 w-16 rounded-xl border border-gray-200 object-cover dark:border-gray-700" />
                      <button type="button" onClick={() => { setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); }} className="absolute -right-2 -top-2 rounded-full bg-error-500 p-1 text-white"><X size={12} /></button>
                    </div>
                  ) : null}
                  <label className="cursor-pointer rounded-xl bg-brand-50 px-3 py-2 text-xs font-bold text-brand-500 hover:bg-brand-100 dark:bg-brand-500/10"><span className="flex items-center gap-2"><Upload size={14} /> Pilih Foto</span><input type="file" accept="image/*" onChange={handleFileChange} className="hidden" /></label>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
                <button type="button" onClick={() => setIsOpen(false)} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Batal</button>
                <button type="submit" disabled={saving} className="rounded-xl bg-brand-500 px-4 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50">{saving ? "Menyimpan..." : "Simpan"}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {qrOpen && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="rounded-2xl border border-brand-200 bg-white p-4 dark:border-brand-500/20 dark:bg-gray-950/40">
              <div className="mb-4 flex items-center justify-between">
                <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-500">Kartu Pengawas Digital</p>
                <QrCode size={18} className="text-brand-500" />
              </div>
              <div className="mb-4 flex items-center gap-3">
                {selected.photoPath ? (
                  <img src={selected.photoPath} alt={selected.nama} className="h-12 w-12 rounded-xl border border-brand-100 object-cover dark:border-brand-500/20" />
                ) : (
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-brand-50 font-bold text-brand-500 dark:bg-brand-500/10">
                    {(selected.nama || "P").charAt(0).toUpperCase()}
                  </div>
                )}
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-gray-900 dark:text-white">{selected.nama}</p>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">NIP: <span className="font-mono">{selected.nip || selected.username || selected.id || "-"}</span></p>
                </div>
              </div>
              <div className="flex justify-center rounded-xl bg-white p-4"><QRCodeSVG value={selected.qrValue} size={180} /></div>
              <p className="mt-3 text-center text-[11px] italic text-gray-500 dark:text-gray-400">Gunakan QR ini untuk akses cepat dari aplikasi.</p>
            </div>
            <div className="mt-4 space-y-1 text-center text-sm text-gray-700 dark:text-gray-300">
              <p>Nama: <span className="font-semibold">{selected.nama || "-"}</span></p>
              <p>NIP: <span className="font-mono font-bold">{selected.nip || selected.username || "-"}</span></p>
            </div>
            <button onClick={() => setQrOpen(false)} className="mt-5 w-full rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white hover:bg-brand-600">Tutup</button>
          </div>
        </div>
      )}
    </>
  );
}

const inputCls = "w-full rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-700 dark:bg-gray-800 dark:text-white";
const labelCls = "mb-1 block text-xs font-bold uppercase text-gray-700 dark:text-gray-300";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><label className={labelCls}>{label}</label>{children}</div>;
}
