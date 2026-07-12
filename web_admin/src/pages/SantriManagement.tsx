import { useEffect, useMemo, useState } from "react";
import { collection, doc, getDocs, setDoc, deleteDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { QRCodeSVG } from "qrcode.react";
import { Plus, Search, QrCode, Trash2, Edit2, ShieldAlert, Upload, X, FileSpreadsheet, Download } from "lucide-react";
import { downloadSantriExcelTemplate, parseSantriExcelFile, type ParsedSantriImportRow } from "../utils/santriImport";
import defaultAvatar from "../../../assets/images/avatar-default.png";

interface Mapping { linkedId: string; role: string; defaultPassword: string }

export default function SantriManagement() {
  const { profile } = useAuth();
  const [santriList, setSantriList] = useState<any[]>([]);
  const [mappings, setMappings] = useState<Record<string, Mapping>>({});
  const [halaqahList, setHalaqahList] = useState<any[]>([]);
  const [kelasList, setKelasList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [name, setName] = useState("");
  const [nis, setNis] = useState("");
  const [email, setEmail] = useState("");
  const [gender, setGender] = useState("L");
  const [kelas, setKelas] = useState("");
  const [halaqahId, setHalaqahId] = useState("");
  const [wali, setWali] = useState("");
  const [hpWali, setHpWali] = useState("");
  const [targetHafalan, setTargetHafalan] = useState("30");
  const [tanggalLahir, setTanggalLahir] = useState("");
  const [initialJuzList, setInitialJuzList] = useState<number[]>([]);
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
  const [importRows, setImportRows] = useState<ParsedSantriImportRow[]>([]);
  const [importFileName, setImportFileName] = useState("");
  const [importLoading, setImportLoading] = useState(false);
  const [importSaving, setImportSaving] = useState(false);
  const [importError, setImportError] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.pesantrenId) {
      loadSantri();
      loadRefs();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  const loadSantri = async () => {
    if (!profile?.pesantrenId) return;
    setLoading(true);
    try {
      const pid = profile.pesantrenId;
      const mapSnap = await getDocs(collection(db, "pesantren", pid, "user_mappings"));
      const tmp: Record<string, Mapping> = {};
      mapSnap.forEach((d) => { tmp[d.id] = d.data() as Mapping; });
      setMappings(tmp);

      const snap = await getDocs(collection(db, "pesantren", pid, "santri"));
      const list: any[] = [];
      snap.forEach((d) => list.push({ id: d.id, ...d.data() }));
      setSantriList(list);
    } catch (err) {
      console.error("Error loading santri:", err);
    } finally {
      setLoading(false);
    }
  };

  const loadRefs = async () => {
    if (!profile?.pesantrenId) return;
    try {
      const pid = profile.pesantrenId;
      const hSnap = await getDocs(collection(db, "pesantren", pid, "halaqah"));
      setHalaqahList(hSnap.docs.map((d) => ({ id: d.id, nama: d.data().nama })));
      const kSnap = await getDocs(collection(db, "pesantren", pid, "kelas"));
      setKelasList(kSnap.docs.map((d) => ({ id: d.id, nama: d.data().nama })));
    } catch (err) {
      console.error("Error loading refs:", err);
    }
  };

  const resetForm = () => {
    setName(""); setNis(""); setEmail(""); setGender("L"); setKelas(""); setHalaqahId("");
    setWali(""); setHpWali(""); setTargetHafalan("30"); setTanggalLahir(""); setInitialJuzList([]);
    setStatus("aktif"); setCustomUsername(""); setCustomPassword("");
    setExistingMappingKey("");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); setError(null);
  };

  const handleOpenAdd = () => {
    setIsEdit(false); setExistingId(""); resetForm(); setIsOpen(true);
  };

  const handleOpenEdit = (s: any) => {
    const entry = Object.entries(mappings).find(([, value]) => value.linkedId === s.id);
    setIsEdit(true); setExistingId(s.id);
    setName(s.name || ""); setNis(s.nis || ""); setEmail(s.email || "");
    setGender(s.jenisKelamin || "L"); setKelas(s.kelas || ""); setHalaqahId(s.halaqahId || "");
    setWali(s.namaOrangTua || s.namaAyah || ""); setHpWali(s.nomorHpWali || "");
    setTargetHafalan(s.targetHafalan ? String(s.targetHafalan).replace(/\s*[Jj]uz\s*/g, "").trim() : "30");
    setTanggalLahir(s.tanggalLahir || "");
    setInitialJuzList(Array.isArray(s.initialMemorizedJuz) ? s.initialMemorizedJuz : []);
    setStatus(s.status || "aktif"); setCustomUsername(""); setCustomPassword("");
    setExistingMappingKey(entry?.[0] || "");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(s.photoPath || null);
    setError(null); setIsOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) { setError("Ukuran foto maksimal 2MB"); return; }
      setPhotoFile(file); setPhotoPreview(URL.createObjectURL(file)); setError(null);
    }
  };

  const toggleJuz = (juz: number) => {
    setInitialJuzList((prev) => prev.includes(juz) ? prev.filter((j) => j !== juz) : [...prev, juz].sort((a, b) => a - b));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !nis) { setError("Nama dan NIS wajib diisi"); return; }
    const pid = profile?.pesantrenId;
    if (!pid) return;
    const cleanNis = nis.trim().replace(/[^0-9]/g, "");
    if (!cleanNis) { setError("NIS harus mengandung angka"); return; }
    if (email.trim() && !/\S+@\S+\.\S+/.test(email.trim())) { setError("Format email tidak valid"); return; }
    setError(null); setSaving(true);
    try {
      // Doc ID = auto-id (matches Flutter generateId('santri'))
      const santriDocId = isEdit ? existingId : doc(collection(db, "pesantren", pid, "santri")).id;
      const santriRef = doc(db, "pesantren", pid, "santri", santriDocId);
      const mappingKey = customUsername.trim()
        ? customUsername.trim().toLowerCase().replace(/[^a-z0-9]/g, "")
        : cleanNis;
      const mappingRef = doc(db, "pesantren", pid, "user_mappings", mappingKey);

      let finalPhotoUrl = existingPhotoPath;
      if (photoFile) {
        try {
          const photoRef = ref(storage, `santri_photos/${santriDocId}.jpg`);
          const up = await uploadBytes(photoRef, photoFile);
          finalPhotoUrl = await getDownloadURL(up.ref);
        } catch (uErr) { console.warn("Upload foto gagal:", uErr); }
      }

      await setDoc(santriRef, {
        id: santriDocId,
        name: name.trim(),
        nis: nis.trim(), // RAW nis (matches Flutter display)
        email: email.trim() || null,
        jenisKelamin: gender,
        kelas: kelas || null,
        halaqahId: halaqahId || null,
        namaOrangTua: wali.trim() || null,
        nomorHpWali: hpWali.trim() || null,
        targetHafalan: targetHafalan ? `${targetHafalan} Juz` : "30 Juz",
        photoPath: finalPhotoUrl || null,
        tanggalLahir: tanggalLahir || null,
        status,
        initialMemorizedJuz: initialJuzList,
      }, { merge: true });

      if (!isEdit || !mappings[mappingKey]) {
        await setDoc(mappingRef, {
          linkedId: santriDocId,
          role: "orangTua",
          defaultPassword: customPassword.trim() || mappingKey,
        }, { merge: true });
      } else if (customPassword.trim()) {
        await setDoc(doc(db, "pesantren", pid, "user_mappings", existingMappingKey || mappingKey), {
          linkedId: santriDocId,
          role: "orangTua",
          defaultPassword: customPassword.trim(),
        }, { merge: true });
      }

      setIsOpen(false);
      loadSantri();
    } catch (err: any) {
      console.error(err);
      setError("Gagal menyimpan: " + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (studentId: string) => {
    if (!profile?.pesantrenId) return;
    if (!window.confirm("Hapus data santri ini? Mapping login akan ikut dihapus.")) return;
    try {
      const pid = profile.pesantrenId;
      const s = santriList.find((x) => x.id === studentId);
      await deleteDoc(doc(db, "pesantren", pid, "santri", studentId));
      const entry = Object.entries(mappings).find(([, v]) => v.linkedId === studentId);
      if (entry) await deleteDoc(doc(db, "pesantren", pid, "user_mappings", entry[0])).catch(() => {});
      const nisKey = (s?.nis || "").replace(/\D/g, "");
      if (nisKey) await deleteDoc(doc(db, "pesantren", pid, "user_mappings", nisKey)).catch(() => {});
      loadSantri();
    } catch (err) {
      console.error("Error deleting:", err);
      alert("Gagal menghapus");
    }
  };

  const handleOpenQr = (s: any) => {
    const entry = Object.entries(mappings).find(([, v]) => v.linkedId === s.id);
    const loginKey = entry ? entry[0] : ((s.nis || "").replace(/\D/g, "") || s.id);
    setSelected({ ...s, loginKey, password: entry?.[1]?.defaultPassword || loginKey, qrValue: `tahfidzmu:login:${profile?.pesantrenId}:${loginKey}` });
    setQrOpen(true);
  };

  const getHalaqahName = (id: string) => halaqahList.find((h) => h.id === id)?.nama || "-";
  const getKelasName = (id: string) => kelasList.find((k) => k.id === id)?.nama || id || "-";

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
      const rows = await parseSantriExcelFile(file);
      setImportRows(rows);
      setImportFileName(file.name);
      if (rows.length === 0) {
        setImportError("File Excel tidak berisi data.");
      }
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
        const cleanNis = row.nis.trim().replace(/\D/g, "");
        const existing = santriList.find((item) => String(item.nis || "").replace(/\D/g, "") === cleanNis);
        const santriDocId = existing?.id || doc(collection(db, "pesantren", pid, "santri")).id;
        const santriRef = doc(db, "pesantren", pid, "santri", santriDocId);
        const mappingRef = doc(db, "pesantren", pid, "user_mappings", cleanNis);

        const matchedKelas = row.kelas
          ? kelasList.find((item) => String(item.nama || "").toLowerCase() === row.kelas.toLowerCase())
          : null;
        const matchedHalaqah = row.halaqah
          ? halaqahList.find((item) => item.id === row.halaqah || String(item.nama || "").toLowerCase() === row.halaqah.toLowerCase())
          : null;

        const payload: Record<string, unknown> = {
          id: santriDocId,
          name: row.name.trim(),
          nis: row.nis.trim(),
          email: row.email.trim(),
          jenisKelamin: row.gender || "L",
          targetHafalan: row.targetHafalan ? `${row.targetHafalan.replace(/\s*[Jj]uz\s*/g, "").trim()} Juz` : (existing?.targetHafalan || "30 Juz"),
          status: row.status || "aktif",
        };

        if (existing) {
          if (row.kelas) payload.kelas = matchedKelas?.nama || null;
          if (row.halaqah) payload.halaqahId = matchedHalaqah?.id || null;
          if (row.wali) payload.namaOrangTua = row.wali.trim();
          if (row.hpWali) payload.nomorHpWali = row.hpWali.trim();
          if (row.tanggalLahir) payload.tanggalLahir = row.tanggalLahir;
          if (row.initialJuzList.length > 0) payload.initialMemorizedJuz = row.initialJuzList;
        } else {
          payload.kelas = matchedKelas?.nama || null;
          payload.halaqahId = matchedHalaqah?.id || null;
          payload.namaOrangTua = row.wali.trim() || null;
          payload.nomorHpWali = row.hpWali.trim() || null;
          payload.tanggalLahir = row.tanggalLahir || null;
          payload.initialMemorizedJuz = row.initialJuzList;
          payload.photoPath = null;
        }

        await setDoc(santriRef, payload, { merge: true });
        await setDoc(mappingRef, {
          linkedId: santriDocId,
          role: "orangTua",
          defaultPassword: row.password || cleanNis,
        }, { merge: true });
      }

      setImportOpen(false);
      setImportRows([]);
      setImportFileName("");
      await loadSantri();
    } catch (err) {
      console.error(err);
      setImportError("Gagal menyimpan hasil import ke Firebase.");
    } finally {
      setImportSaving(false);
    }
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

  const filtered = [...santriList]
    .filter((s) => {
      const matchesSearch = (s.name || "").toLowerCase().includes(search.toLowerCase()) || (s.nis || "").includes(search);

      // If Coordinator, only show santri from managed halaqahs
      if (profile?.role === "musyrif" && profile?.isKoordinator && Array.isArray(profile?.managedHalaqahIds)) {
        if (profile.managedHalaqahIds.length > 0) {
          return matchesSearch && profile.managedHalaqahIds.includes(s.halaqahId);
        }
      }

      return matchesSearch;
    })
    .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Kelola Santri | TahfidzMU Admin" description="Administrasi data santri & kartu login QR." />
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Data Santri</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Daftarkan santri, kelola kelas/halaqah, dan cetak kartu login.</p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <button onClick={() => setImportOpen(true)} className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-brand-600 bg-brand-50 rounded-xl hover:bg-brand-100 transition dark:bg-brand-500/10 dark:text-brand-400">
              <FileSpreadsheet size={18} /> Import Excel
            </button>
            <button onClick={handleOpenAdd} className="flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-white bg-brand-500 rounded-xl hover:bg-brand-600 transition">
              <Plus size={18} /> Tambah Santri
            </button>
          </div>
        </div>

        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Cari nama atau NIS..." value={search} onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:bg-white/[0.03] dark:border-gray-800 dark:text-white" />
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
        ) : (
          <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden dark:bg-white/[0.03] dark:border-gray-800">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-100 dark:border-gray-800 bg-gray-50 text-gray-500 dark:bg-white/[0.02] dark:text-gray-400">
                    <th className="p-4">Santri</th><th className="p-4">NIS</th><th className="p-4">L/P</th>
                    <th className="p-4">Wali</th><th className="p-4">Kelas</th><th className="p-4">Halaqah</th><th className="p-4">Status</th><th className="p-4 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {filtered.length === 0 ? (
                    <tr><td colSpan={8} className="p-8 text-center text-gray-500">Belum ada data santri.</td></tr>
                  ) : filtered.map((s) => (
                    <tr key={s.id} className="text-gray-700 dark:text-gray-300 hover:bg-gray-50/50 dark:hover:bg-white/[0.01]">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={s.photoPath || defaultAvatar}
                            alt={s.name}
                            className="h-10 w-10 rounded-full object-cover border border-gray-100 dark:border-gray-800"
                          />
                          <div>
                            <p className="font-semibold text-gray-900 dark:text-white">{s.name}</p>
                            {s.email ? <p className="text-xs text-gray-500 dark:text-gray-400">{s.email}</p> : null}
                          </div>
                        </div>
                      </td>
                      <td className="p-4 font-mono font-bold text-gray-900 dark:text-white">{s.nis || "-"}</td>
                      <td className="p-4">{s.jenisKelamin === "P" ? "P" : "L"}</td>
                      <td className="p-4">{s.namaOrangTua || "-"}</td>
                      <td className="p-4">{getKelasName(s.kelas)}</td>
                      <td className="p-4">{getHalaqahName(s.halaqahId)}</td>
                      <td className="p-4">
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${s.status === "nonaktif" ? "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300" : "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"}`}>
                          {s.status === "nonaktif" ? "Nonaktif" : "Aktif"}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-2">
                          <button onClick={() => handleOpenQr(s)} title="Kartu Login" className="p-1.5 text-gray-400 hover:text-brand-500"><QrCode size={16} /></button>
                          <button onClick={() => handleOpenEdit(s)} title="Edit" className="p-1.5 text-gray-400 hover:text-blue-600"><Edit2 size={16} /></button>
                          <button onClick={() => handleDelete(s.id)} title="Hapus" className="p-1.5 text-gray-400 hover:text-error-500"><Trash2 size={16} /></button>
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

      {/* Modal Add/Edit */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex justify-center p-4 bg-black/50 backdrop-blur-sm overflow-y-auto items-start">
          <div className="w-full max-w-2xl mt-12 mb-12 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-xl p-6">
            <h3 className="text-lg font-bold text-gray-800 dark:text-white mb-4">{isEdit ? "Edit Santri" : "Tambah Santri"}</h3>
            {error && <div className="p-3 mb-4 text-xs text-error-700 bg-error-50 border border-error-100 rounded-xl dark:bg-error-500/10 dark:text-error-400">{error}</div>}
            <form onSubmit={handleSave} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Field label="Nama Lengkap *"><input required value={name} onChange={(e) => setName(e.target.value)} className={inputCls} /></Field>
                <Field label="NIS *"><input required value={nis} onChange={(e) => setNis(e.target.value)} placeholder="TH-2024-001" className={inputCls} /></Field>
                <Field label="Jenis Kelamin">
                  <select value={gender} onChange={(e) => setGender(e.target.value)} className={inputCls}><option value="L">Laki-laki</option><option value="P">Perempuan</option></select>
                </Field>
                <Field label="Tanggal Lahir"><input type="date" value={tanggalLahir} onChange={(e) => setTanggalLahir(e.target.value)} className={inputCls} /></Field>
                <Field label="Kelas">
                  <select value={kelas} onChange={(e) => setKelas(e.target.value)} className={inputCls}><option value="">-- Belum ditentukan --</option>{kelasList.map((k) => <option key={k.id} value={k.nama}>{k.nama}</option>)}</select>
                </Field>
                <Field label="Halaqah">
                  <select value={halaqahId} onChange={(e) => setHalaqahId(e.target.value)} className={inputCls}><option value="">-- Belum ditentukan --</option>{halaqahList.map((h) => <option key={h.id} value={h.id}>{h.nama}</option>)}</select>
                </Field>
                <Field label="Nama Orang Tua / Wali"><input value={wali} onChange={(e) => setWali(e.target.value)} className={inputCls} /></Field>
                <Field label="No. HP Wali"><input value={hpWali} onChange={(e) => setHpWali(e.target.value)} placeholder="0812..." className={inputCls} /></Field>
                <Field label="Email"><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className={inputCls} /></Field>
                <Field label="Target Hafalan (Juz)"><input type="number" min={1} max={30} value={targetHafalan} onChange={(e) => setTargetHafalan(e.target.value)} className={inputCls} /></Field>
              </div>

              <Field label="Status">
                <select value={status} onChange={(e) => setStatus(e.target.value)} className={inputCls}><option value="aktif">Aktif</option><option value="nonaktif">Nonaktif</option></select>
              </Field>

              <div>
                <label className={labelCls}>Hafalan Awal (Juz sudah dihafal)</label>
                <div className="flex flex-wrap gap-1.5">
                  {Array.from({ length: 30 }, (_, i) => i + 1).map((j) => (
                    <button type="button" key={j} onClick={() => toggleJuz(j)}
                      className={`w-9 h-9 text-xs font-bold rounded-lg border transition ${initialJuzList.includes(j) ? "bg-brand-500 text-white border-brand-500" : "bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-300 border-gray-200 dark:border-gray-700"}`}>{j}</button>
                  ))}
                </div>
              </div>

              {!isEdit && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-3 border border-dashed border-gray-200 dark:border-gray-700 rounded-xl">
                  <Field label="Username Login (opsional)"><input value={customUsername} onChange={(e) => setCustomUsername(e.target.value)} placeholder="default: NIS" className={inputCls} /></Field>
                  <Field label="Sandi Login (opsional)"><input value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="default: sama dgn username" className={inputCls} /></Field>
                </div>
              )}

              {isEdit && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-3 border border-dashed border-gray-200 dark:border-gray-700 rounded-xl">
                  <Field label="Username Login"><input disabled value={existingMappingKey || nis.replace(/\D/g, "") || "-"} className={inputCls + " opacity-70"} /></Field>
                  <Field label="Ganti Sandi Login (opsional)"><input type="password" value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="kosongkan jika tidak diubah" className={inputCls} /></Field>
                </div>
              )}

              <div>
                <label className={labelCls}>Foto Santri</label>
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <img
                      src={photoPreview || existingPhotoPath || defaultAvatar}
                      alt="Foto"
                      className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-700"
                    />
                    {(photoPreview || existingPhotoPath) && (
                      <button type="button" onClick={() => { setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); }} className="absolute -top-2 -right-2 p-1 bg-error-500 text-white rounded-full">
                        <X size={12} />
                      </button>
                    )}
                  </div>
                  <label className="flex items-center gap-2 px-3 py-2 text-xs font-bold text-brand-500 bg-brand-50 dark:bg-brand-500/10 rounded-xl cursor-pointer hover:bg-brand-100"><Upload size={14} /> Pilih Foto<input type="file" accept="image/*" onChange={handleFileChange} className="hidden" /></label>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-800">
                <button type="button" onClick={() => setIsOpen(false)} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Batal</button>
                <button type="submit" disabled={saving} className="px-4 py-2 text-xs font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50">{saving ? "Menyimpan..." : "Simpan"}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {importOpen && (
        <div className="fixed inset-0 z-50 flex justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm items-start">
          <div className="mt-12 mb-12 w-full max-w-5xl rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="flex flex-col gap-4 border-b border-gray-100 pb-4 dark:border-gray-800 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">Import Santri dari Excel</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Field wajib hanya <span className="font-semibold">Nama</span> dan <span className="font-semibold">NIS</span>. Kolom lain boleh kosong.</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <button type="button" onClick={downloadSantriExcelTemplate} className="inline-flex items-center gap-2 rounded-xl bg-gray-100 px-3 py-2 text-xs font-bold text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200">
                  <Download size={14} /> Unduh Template
                </button>
                <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-500 px-3 py-2 text-xs font-bold text-white hover:bg-brand-600">
                  <Upload size={14} /> Pilih File Excel
                  <input type="file" accept=".xlsx,.xls" onChange={handleImportFile} className="hidden" />
                </label>
              </div>
            </div>

            {importError && <div className="mt-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{importError}</div>}

            <div className="mt-4 grid gap-4 md:grid-cols-3">
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                <div className="text-xs uppercase text-gray-400">File</div>
                <div className="mt-1 text-sm font-semibold text-gray-800 dark:text-white">{importFileName || "Belum ada file"}</div>
              </div>
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                <div className="text-xs uppercase text-gray-400">Data Valid</div>
                <div className="mt-1 text-sm font-semibold text-emerald-600 dark:text-emerald-400">{importSummary.valid} baris</div>
              </div>
              <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                <div className="text-xs uppercase text-gray-400">Data Invalid</div>
                <div className="mt-1 text-sm font-semibold text-error-600 dark:text-error-400">{importSummary.invalid} baris</div>
              </div>
            </div>

            <div className="mt-4 rounded-2xl border border-gray-200 dark:border-gray-800">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-gray-100 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-white/[0.02] dark:text-gray-400">
                      <th className="p-3">Baris</th>
                      <th className="p-3">Nama</th>
                      <th className="p-3">NIS</th>
                      <th className="p-3">Email</th>
                      <th className="p-3">Kelas</th>
                      <th className="p-3">Halaqah</th>
                      <th className="p-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {importLoading ? (
                      <tr><td colSpan={7} className="p-8 text-center text-gray-500">Membaca file Excel...</td></tr>
                    ) : importRows.length === 0 ? (
                      <tr><td colSpan={7} className="p-8 text-center text-gray-500">Belum ada data preview. Unduh template lalu upload file Excel.</td></tr>
                    ) : importRows.map((row) => (
                      <tr key={`${row.rowNumber}-${row.nis}`} className="text-gray-700 dark:text-gray-300">
                        <td className="p-3 font-mono text-xs">{row.rowNumber}</td>
                        <td className="p-3 font-semibold text-gray-900 dark:text-white">{row.name || "-"}</td>
                        <td className="p-3 font-mono">{row.nis || "-"}</td>
                        <td className="p-3">{row.email || "-"}</td>
                        <td className="p-3">{row.kelas || "-"}</td>
                        <td className="p-3">{row.halaqah || "-"}</td>
                        <td className="p-3">
                          {row.error ? (
                            <span className="inline-flex rounded-full bg-error-50 px-2.5 py-1 text-xs font-semibold text-error-600 dark:bg-error-500/10 dark:text-error-400">{row.error}</span>
                          ) : (
                            <span className="inline-flex rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">Siap import</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="mt-4 rounded-xl bg-gray-50 p-4 text-xs text-gray-600 dark:bg-white/5 dark:text-gray-300">
              <p className="font-semibold text-gray-700 dark:text-white">Catatan import</p>
              <p className="mt-1">Jika nama kelas atau halaqah tidak cocok dengan data yang sudah ada di sistem, nilainya akan dikosongkan saat disimpan.</p>
              <p className="mt-1">Baris valid akan di-update bila NIS yang sama sudah ada, dan akan dibuat baru bila belum ada.</p>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
              <button type="button" onClick={() => { setImportOpen(false); setImportRows([]); setImportFileName(""); setImportError(null); }} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Tutup</button>
              <button type="button" disabled={importSaving || importSummary.valid === 0} onClick={handleImportSave} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50">
                <FileSpreadsheet size={14} /> {importSaving ? "Mengimport..." : `Import ${importSummary.valid} Data`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* QR Modal */}
      {qrOpen && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="rounded-2xl border border-brand-200 bg-white p-4 dark:border-brand-500/20 dark:bg-gray-950/40">
              <div className="mb-4 flex items-center justify-between">
                <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-500">Kartu Santri Digital</p>
                <QrCode size={18} className="text-brand-500" />
              </div>
              <div className="mb-4 flex items-center gap-3">
                <img
                  src={selected.photoPath || defaultAvatar}
                  alt={selected.name}
                  className="h-12 w-12 rounded-xl object-cover border border-brand-100 dark:border-brand-500/20"
                />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-gray-900 dark:text-white">{selected.name}</p>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">NIS/ID: <span className="font-mono">{selected.nis || selected.id || "-"}</span></p>
                </div>
              </div>
              <div className="flex justify-center rounded-xl bg-white p-4">
                <QRCodeSVG value={selected.qrValue} size={180} />
              </div>
              <p className="mt-3 text-center text-[11px] italic text-gray-500 dark:text-gray-400">Gunakan QR ini untuk akses cepat dari aplikasi.</p>
            </div>
            <div className="mt-4 space-y-1 text-center text-sm text-gray-700 dark:text-gray-300">
              <p>Nama: <span className="font-semibold">{selected.name || "-"}</span></p>
              <p>NIS: <span className="font-mono font-bold">{selected.nis || "-"}</span></p>
            </div>
            <button onClick={() => setQrOpen(false)} className="mt-5 w-full rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white hover:bg-brand-600">Tutup</button>
          </div>
        </div>
      )}
    </>
  );
}

const inputCls = "w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white";
const labelCls = "block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (<div><label className={labelCls}>{label}</label>{children}</div>);
}
