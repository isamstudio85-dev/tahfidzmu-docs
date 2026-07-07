import { useEffect, useMemo, useState } from "react";
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { QRCodeSVG } from "qrcode.react";
import { Download, Edit2, FileSpreadsheet, Plus, QrCode, Search, ShieldAlert, Trash2, Upload, X } from "lucide-react";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";
import { downloadMusyrifExcelTemplate, parseMusyrifExcelFile, type ParsedMusyrifImportRow } from "../utils/musyrifImport";

interface Mapping {
  linkedId: string;
  role: string;
  defaultPassword: string;
}

export default function MusyrifManagement() {
  const { profile } = useAuth();
  const [list, setList] = useState<any[]>([]);
  const [mappings, setMappings] = useState<Record<string, Mapping>>({});
  const [pesantrenNama, setPesantrenNama] = useState("Halaqah Tahfidz");
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [name, setName] = useState("");
  const [nip, setNip] = useState("");
  const [gender, setGender] = useState("L");
  const [jabatan, setJabatan] = useState("");
  const [noHp, setNoHp] = useState("");
  const [email, setEmail] = useState("");
  const [catatan, setCatatan] = useState("");
  const [status, setStatus] = useState("aktif");
  const [customUsername, setCustomUsername] = useState("");
  const [customPassword, setCustomPassword] = useState("");
  const [isEdit, setIsEdit] = useState(false);
  const [existingId, setExistingId] = useState("");
  const [existingMappingKey, setExistingMappingKey] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [existingPhotoPath, setExistingPhotoPath] = useState<string | null>(null);

  const [qrOpen, setQrOpen] = useState(false);
  const [selected, setSelected] = useState<any>(null);

  const [importOpen, setImportOpen] = useState(false);
  const [importRows, setImportRows] = useState<ParsedMusyrifImportRow[]>([]);
  const [importFileName, setImportFileName] = useState("");
  const [importLoading, setImportLoading] = useState(false);
  const [importSaving, setImportSaving] = useState(false);
  const [importError, setImportError] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.pesantrenId) {
      load();
      loadPesantrenName();
    }
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

      const snap = await getDocs(collection(db, "pesantren", pid, "musyrif"));
      setList(snap.docs.map((entry) => ({ id: entry.id, ...entry.data() })));
    } catch (loadError) {
      console.error(loadError);
    } finally {
      setLoading(false);
    }
  };

  const loadPesantrenName = async () => {
    if (!profile?.pesantrenId) return;
    try {
      const infoSnap = await getDoc(doc(db, "pesantren", profile.pesantrenId, "settings", "pesantren_info"));
      if (infoSnap.exists() && infoSnap.data().nama) setPesantrenNama(infoSnap.data().nama);
    } catch {
      // ignore
    }
  };

  const resetForm = () => {
    setName("");
    setNip("");
    setGender("L");
    setJabatan("");
    setNoHp("");
    setEmail("");
    setCatatan("");
    setStatus("aktif");
    setCustomUsername("");
    setCustomPassword("");
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
    setExistingMappingKey(entry?.[0] || "");
    setName(item.nama || "");
    setNip(item.nip || "");
    setGender(item.jenisKelamin || "L");
    setJabatan(item.jabatan || "");
    setNoHp(item.nomorHp || "");
    setEmail(item.email || "");
    setCatatan(item.catatan || "");
    setStatus(item.status || "aktif");
    setCustomUsername("");
    setCustomPassword("");
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
    if (!name || !nip) {
      setError("Nama dan NIP wajib diisi");
      return;
    }
    if (email && !/\S+@\S+\.\S+/.test(email.trim())) {
      setError("Format email tidak valid");
      return;
    }

    const pid = profile?.pesantrenId;
    if (!pid) return;
    const cleanNip = nip.trim().replace(/[^0-9]/g, "");
    if (!cleanNip) {
      setError("NIP harus mengandung angka");
      return;
    }

    setError(null);
    setSaving(true);
    try {
      const docId = isEdit ? existingId : doc(collection(db, "pesantren", pid, "musyrif")).id;
      const musyrifRef = doc(db, "pesantren", pid, "musyrif", docId);
      const mappingKey = customUsername.trim()
        ? customUsername.trim().toLowerCase().replace(/[^a-z0-9]/g, "")
        : cleanNip;
      const mappingRef = doc(db, "pesantren", pid, "user_mappings", mappingKey);
      const finalJabatan = jabatan.trim() || (gender === "P" ? "Musyrifah" : "Musyrif");

      let finalPhotoUrl = existingPhotoPath;
      if (photoFile) {
        try {
          const photoRef = ref(storage, `musyrif_photos/${docId}.jpg`);
          const uploaded = await uploadBytes(photoRef, photoFile);
          finalPhotoUrl = await getDownloadURL(uploaded.ref);
        } catch (uploadError) {
          console.warn("Upload foto gagal:", uploadError);
        }
      }

      await setDoc(musyrifRef, {
        id: docId,
        nama: name.trim(),
        nip: nip.trim(),
        jenisKelamin: gender,
        jabatan: finalJabatan,
        lembaga: pesantrenNama,
        nomorHp: noHp.trim() || null,
        photoPath: finalPhotoUrl || null,
        email: email.trim() || null,
        status,
        catatan: catatan.trim() || null,
      }, { merge: true });

      if (!isEdit || !mappings[mappingKey]) {
        await setDoc(mappingRef, {
          linkedId: docId,
          role: "musyrif",
          defaultPassword: customPassword.trim() || mappingKey,
        }, { merge: true });
      } else if (customPassword.trim()) {
        await setDoc(doc(db, "pesantren", pid, "user_mappings", existingMappingKey || mappingKey), {
          linkedId: docId,
          role: "musyrif",
          defaultPassword: customPassword.trim(),
        }, { merge: true });
      }

      setIsOpen(false);
      await load();
    } catch (saveError: any) {
      console.error(saveError);
      setError(`Gagal menyimpan: ${saveError.message}`);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm("Hapus data musyrif ini? Akses login akan dihapus.")) return;
    try {
      const pid = profile.pesantrenId;
      const item = list.find((entry) => entry.id === id);
      await deleteDoc(doc(db, "pesantren", pid, "musyrif", id));
      const entry = Object.entries(mappings).find(([, value]) => value.linkedId === id);
      if (entry) await deleteDoc(doc(db, "pesantren", pid, "user_mappings", entry[0])).catch(() => {});
      const nipKey = (item?.nip || "").replace(/\D/g, "");
      if (nipKey) await deleteDoc(doc(db, "pesantren", pid, "user_mappings", nipKey)).catch(() => {});
      await load();
    } catch (deleteError) {
      console.error(deleteError);
      alert("Gagal menghapus");
    }
  };

  const handleOpenQr = (item: any) => {
    const entry = Object.entries(mappings).find(([, value]) => value.linkedId === item.id);
    const loginKey = entry ? entry[0] : ((item.nip || "").replace(/\D/g, "") || item.id);
    const password = entry?.[1]?.defaultPassword || loginKey;
    setSelected({
      ...item,
      loginKey,
      password,
      qrValue: `tahfidzmu:login:${profile?.pesantrenId}:${loginKey}:${password}`,
    });
    setQrOpen(true);
  };

  const importSummary = useMemo(() => {
    const valid = importRows.filter((row) => !row.error).length;
    return {
      total: importRows.length,
      valid,
      invalid: importRows.length - valid,
    };
  }, [importRows]);

  const handleImportFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportLoading(true);
    setImportError(null);
    try {
      const rows = await parseMusyrifExcelFile(file);
      setImportRows(rows);
      setImportFileName(file.name);
      if (rows.length === 0) setImportError("File Excel tidak berisi data.");
    } catch (err) {
      console.error(err);
      setImportError("Gagal membaca file Excel. Pastikan format file benar.");
      setImportRows([]);
    } finally {
      setImportLoading(false);
      e.target.value = "";
    }
  };

  const handleImportSave = async () => {
    const pid = profile?.pesantrenId;
    if (!pid) return;

    const validRows = importRows.filter((row) => !row.error);
    if (validRows.length === 0) {
      setImportError("Belum ada data valid untuk diimport.");
      return;
    }

    setImportSaving(true);
    setImportError(null);
    try {
      for (const row of validRows) {
        const cleanNip = row.nip.trim().replace(/\D/g, "");
        const existing = list.find((item) => String(item.nip || "").replace(/\D/g, "") === cleanNip);
        const docId = existing?.id || doc(collection(db, "pesantren", pid, "musyrif")).id;
        const musyrifRef = doc(db, "pesantren", pid, "musyrif", docId);
        const mappingRef = doc(db, "pesantren", pid, "user_mappings", cleanNip);
        const finalJabatan = row.jabatan.trim() || (row.gender === "P" ? "Musyrifah" : "Musyrif");

        await setDoc(musyrifRef, {
          id: docId,
          nama: row.name.trim(),
          nip: row.nip.trim(),
          jenisKelamin: row.gender || "L",
          jabatan: finalJabatan,
          lembaga: pesantrenNama,
          nomorHp: row.noHp.trim() || null,
          photoPath: existing?.photoPath || null,
          email: row.email.trim() || null,
          status: row.status || "aktif",
          catatan: row.catatan.trim() || null,
        }, { merge: true });

        await setDoc(mappingRef, {
          linkedId: docId,
          role: "musyrif",
          defaultPassword: cleanNip,
        }, { merge: true });
      }

      setImportOpen(false);
      setImportRows([]);
      setImportFileName("");
      await load();
    } catch (err) {
      console.error(err);
      setImportError("Gagal menyimpan hasil import ke Firebase.");
    } finally {
      setImportSaving(false);
    }
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
    .filter((item) => (item.nama || "").toLowerCase().includes(search.toLowerCase()) || (item.nip || "").includes(search))
    .sort((a, b) => String(a.nama || "").localeCompare(String(b.nama || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Kelola Musyrif | TahfidzMU Admin" description="Administrasi data musyrif dan akun login." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Data Musyrif</h2>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Daftarkan musyrif pembimbing halaqah, impor data cepat, dan kelola akun login.</p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <button onClick={() => setImportOpen(true)} className="flex items-center justify-center gap-2 rounded-xl bg-brand-50 px-4 py-2.5 text-sm font-semibold text-brand-600 transition hover:bg-brand-100 dark:bg-brand-500/10 dark:text-brand-400"><FileSpreadsheet size={18} /> Import Excel</button>
            <button onClick={handleOpenAdd} className="flex items-center justify-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-600"><Plus size={18} /> Tambah Musyrif</button>
          </div>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari nama atau NIP..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-11 pr-4 focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-800 dark:bg-white/[0.03] dark:text-white" />
        </div>

        {loading ? (
          <div className="flex min-h-[200px] items-center justify-center"><div className="h-8 w-8 animate-spin rounded-full border-3 border-brand-500 border-t-transparent"></div></div>
        ) : (
          <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-white/[0.02] dark:text-gray-400">
                    <th className="p-4">Musyrif</th>
                    <th className="p-4">NIP</th>
                    <th className="p-4">Jabatan</th>
                    <th className="p-4">No. HP</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {filtered.length === 0 ? (
                    <tr><td colSpan={6} className="p-8 text-center text-gray-500">Belum ada data musyrif.</td></tr>
                  ) : filtered.map((item) => (
                    <tr key={item.id} className="text-gray-700 hover:bg-gray-50/50 dark:text-gray-300 dark:hover:bg-white/[0.01]">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          {item.photoPath ? (
                            <img src={item.photoPath} alt={item.nama} className="h-10 w-10 rounded-full object-cover" />
                          ) : (
                            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-brand-50 font-bold text-brand-500 dark:bg-brand-500/10">{(item.nama || "M").charAt(0).toUpperCase()}</div>
                          )}
                          <div>
                            <p className="font-semibold text-gray-900 dark:text-white">{item.nama}</p>
                            {item.email ? <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p> : null}
                          </div>
                        </div>
                      </td>
                      <td className="p-4 font-mono font-bold text-gray-900 dark:text-white">{item.nip || "-"}</td>
                      <td className="p-4">{item.jabatan || "Musyrif"}</td>
                      <td className="p-4">{item.nomorHp || "-"}</td>
                      <td className="p-4"><span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${item.status === "nonaktif" ? "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300" : "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"}`}>{item.status === "nonaktif" ? "Nonaktif" : "Aktif"}</span></td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-2">
                          <button onClick={() => handleOpenQr(item)} title="Kartu Login" className="p-1.5 text-gray-400 hover:text-brand-500"><QrCode size={16} /></button>
                          <button onClick={() => handleOpenEdit(item)} title="Edit" className="p-1.5 text-gray-400 hover:text-blue-600"><Edit2 size={16} /></button>
                          <button onClick={() => handleDelete(item.id)} title="Hapus" className="p-1.5 text-gray-400 hover:text-error-500"><Trash2 size={16} /></button>
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
            <h3 className="mb-4 text-lg font-bold text-gray-800 dark:text-white">{isEdit ? "Edit Musyrif" : "Tambah Musyrif"}</h3>
            {error && <div className="mb-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-4">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <Field label="Nama Lengkap *"><input required value={name} onChange={(e) => setName(e.target.value)} className={inputCls} /></Field>
                <Field label="NIP *"><input required value={nip} onChange={(e) => setNip(e.target.value)} className={inputCls} /></Field>
                <Field label="Jenis Kelamin"><select value={gender} onChange={(e) => setGender(e.target.value)} className={inputCls}><option value="L">Laki-laki</option><option value="P">Perempuan</option></select></Field>
                <Field label="Jabatan"><input value={jabatan} onChange={(e) => setJabatan(e.target.value)} placeholder="default: Musyrif" className={inputCls} /></Field>
                <Field label="No. HP"><input value={noHp} onChange={(e) => setNoHp(e.target.value)} className={inputCls} /></Field>
                <Field label="Email"><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className={inputCls} /></Field>
                <Field label="Status"><select value={status} onChange={(e) => setStatus(e.target.value)} className={inputCls}><option value="aktif">Aktif</option><option value="nonaktif">Nonaktif</option></select></Field>
              </div>

              <Field label="Catatan"><textarea rows={2} value={catatan} onChange={(e) => setCatatan(e.target.value)} className={inputCls + " resize-none"} /></Field>

              {!isEdit && (
                <div className="grid grid-cols-1 gap-4 rounded-xl border border-dashed border-gray-200 p-3 dark:border-gray-700 sm:grid-cols-2">
                  <Field label="Username Login (opsional)"><input value={customUsername} onChange={(e) => setCustomUsername(e.target.value)} placeholder="default: NIP" className={inputCls} /></Field>
                  <Field label="Sandi Login (opsional)"><input value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="default: sama dgn username" className={inputCls} /></Field>
                </div>
              )}

              {isEdit && (
                <div className="grid grid-cols-1 gap-4 rounded-xl border border-dashed border-gray-200 p-3 dark:border-gray-700 sm:grid-cols-2">
                  <Field label="Username Login"><input disabled value={existingMappingKey || nip.replace(/\D/g, "") || "-"} className={inputCls + " opacity-70"} /></Field>
                  <Field label="Ganti Sandi Login (opsional)"><input type="password" value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="kosongkan jika tidak diubah" className={inputCls} /></Field>
                </div>
              )}

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

      {importOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
          <div className="my-8 w-full max-w-5xl rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="flex flex-col gap-4 border-b border-gray-100 pb-4 dark:border-gray-800 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">Import Musyrif dari Excel</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Field wajib hanya <span className="font-semibold">Nama</span> dan <span className="font-semibold">NIP</span>. Kolom lain boleh kosong.</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <button type="button" onClick={downloadMusyrifExcelTemplate} className="inline-flex items-center gap-2 rounded-xl bg-gray-100 px-3 py-2 text-xs font-bold text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200"><Download size={14} /> Unduh Template</button>
                <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-500 px-3 py-2 text-xs font-bold text-white hover:bg-brand-600"><Upload size={14} /> Pilih File Excel<input type="file" accept=".xlsx,.xls" onChange={handleImportFile} className="hidden" /></label>
              </div>
            </div>

            {importError && <div className="mt-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{importError}</div>}

            <div className="mt-4 grid gap-4 md:grid-cols-3">
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5"><div className="text-xs uppercase text-gray-400">File</div><div className="mt-1 text-sm font-semibold text-gray-800 dark:text-white">{importFileName || "Belum ada file"}</div></div>
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5"><div className="text-xs uppercase text-gray-400">Data Valid</div><div className="mt-1 text-sm font-semibold text-emerald-600 dark:text-emerald-400">{importSummary.valid} baris</div></div>
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5"><div className="text-xs uppercase text-gray-400">Data Invalid</div><div className="mt-1 text-sm font-semibold text-error-600 dark:text-error-400">{importSummary.invalid} baris</div></div>
            </div>

            <div className="mt-4 rounded-2xl border border-gray-200 dark:border-gray-800">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-gray-100 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-white/[0.02] dark:text-gray-400">
                      <th className="p-3">Baris</th>
                      <th className="p-3">Nama</th>
                      <th className="p-3">NIP</th>
                      <th className="p-3">Email</th>
                      <th className="p-3">Jabatan</th>
                      <th className="p-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {importLoading ? (
                      <tr><td colSpan={6} className="p-8 text-center text-gray-500">Membaca file Excel...</td></tr>
                    ) : importRows.length === 0 ? (
                      <tr><td colSpan={6} className="p-8 text-center text-gray-500">Belum ada data preview. Unduh template lalu upload file Excel.</td></tr>
                    ) : importRows.map((row) => (
                      <tr key={`${row.rowNumber}-${row.nip}`} className="text-gray-700 dark:text-gray-300">
                        <td className="p-3 font-mono text-xs">{row.rowNumber}</td>
                        <td className="p-3 font-semibold text-gray-900 dark:text-white">{row.name || "-"}</td>
                        <td className="p-3 font-mono">{row.nip || "-"}</td>
                        <td className="p-3">{row.email || "-"}</td>
                        <td className="p-3">{row.jabatan || "-"}</td>
                        <td className="p-3">{row.error ? <span className="inline-flex rounded-full bg-error-50 px-2.5 py-1 text-xs font-semibold text-error-600 dark:bg-error-500/10 dark:text-error-400">{row.error}</span> : <span className="inline-flex rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">Siap import</span>}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="mt-4 rounded-xl bg-gray-50 p-4 text-xs text-gray-600 dark:bg-white/5 dark:text-gray-300">
              <p className="font-semibold text-gray-700 dark:text-white">Catatan import</p>
              <p className="mt-1">Baris valid akan di-update bila NIP yang sama sudah ada, dan dibuat baru bila belum ada.</p>
              <p className="mt-1">Sandi login otomatis akan menggunakan angka NIP, kecuali nanti diubah manual pada form edit.</p>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
              <button type="button" onClick={() => { setImportOpen(false); setImportRows([]); setImportFileName(""); setImportError(null); }} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Tutup</button>
              <button type="button" disabled={importSaving || importSummary.valid === 0} onClick={handleImportSave} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"><FileSpreadsheet size={14} /> {importSaving ? "Mengimport..." : `Import ${importSummary.valid} Data`}</button>
            </div>
          </div>
        </div>
      )}

      {qrOpen && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="rounded-2xl border border-brand-200 bg-white p-4 dark:border-brand-500/20 dark:bg-gray-950/40">
              <div className="mb-4 flex items-center justify-between">
                <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-500">Kartu Musyrif Digital</p>
                <QrCode size={18} className="text-brand-500" />
              </div>
              <div className="mb-4 flex items-center gap-3">
                {selected.photoPath ? (
                  <img src={selected.photoPath} alt={selected.nama} className="h-12 w-12 rounded-xl border border-brand-100 object-cover dark:border-brand-500/20" />
                ) : (
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-brand-50 font-bold text-brand-500 dark:bg-brand-500/10">{(selected.nama || "M").charAt(0).toUpperCase()}</div>
                )}
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-gray-900 dark:text-white">{selected.nama}</p>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">NIP/ID: <span className="font-mono">{selected.nip || selected.id || "-"}</span></p>
                </div>
              </div>
              <div className="flex justify-center rounded-xl bg-white p-4"><QRCodeSVG value={selected.qrValue} size={180} /></div>
              <p className="mt-3 text-center text-[11px] italic text-gray-500 dark:text-gray-400">Gunakan QR ini untuk akses cepat dari aplikasi.</p>
            </div>
            <div className="mt-4 space-y-1 text-center text-sm text-gray-700 dark:text-gray-300">
              <p>Nama: <span className="font-semibold">{selected.nama || "-"}</span></p>
              <p>NIP: <span className="font-mono font-bold">{selected.nip || "-"}</span></p>
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
