import { useEffect, useMemo, useState } from "react";
import { collection, doc, getDocs, setDoc, deleteDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "../firebase";
import { useAuth } from "../context/AuthContext";
import PageMeta from "../components/common/PageMeta";
import { QRCodeSVG } from "qrcode.react";
import { Plus, Search, QrCode, Trash2, Edit2, ShieldAlert, Upload, X, FileSpreadsheet, Download } from "lucide-react";
import { downloadSantriExcelTemplate, parseSantriExcelFile, type ParsedSantriImportRow } from "../utils/santriImport";
import defaultAvatar from "../assets/images/avatar-default.png";

interface Mapping { linkedId: string; role: string; defaultPassword: string }

export default function SantriManagement() {
  const { profile } = useAuth();
  const [santriList, setSantriList] = useState<any[]>([]);
  const [mappings, setMappings] = useState<Record<string, Mapping>>({});
  const [kelasList, setKelasList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [isOpen, setIsOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [activeTab, setActiveTab] = useState<"pribadi"|"kontak"|"alamat"|"ortu"|"akademik">("pribadi");
  
  // Flat form data for Dapodik
  const [formData, setFormData] = useState({
    name: "", nisn: "", nis_lokal: "", nik: "", jenisKelamin: "L", tempatLahir: "", tanggalLahir: "", agama: "Islam", kewarganegaraan: "WNI", anak_ke: "",
    email: "", no_hp: "",
    jalan: "", rt: "", rw: "", dusun: "", desa_kelurahan: "", kecamatan: "", kode_pos: "", jenis_tinggal: "", transportasi: "",
    ayah_nama: "", ayah_nik: "", ayah_pendidikan: "", ayah_pekerjaan: "", ayah_penghasilan: "",
    ibu_nama: "", ibu_nik: "", ibu_pendidikan: "", ibu_pekerjaan: "", ibu_penghasilan: "",
    wali_nama: "", wali_nik: "", wali_pendidikan: "", wali_pekerjaan: "", wali_penghasilan: "",
    unit_sekolah: "", kelas: "", status: "aktif",
  });

  const [customUsername, setCustomUsername] = useState("");
  const [customPassword, setCustomPassword] = useState("");
  const [existingId, setExistingId] = useState("");
  const [existingMappingKey, setExistingMappingKey] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [existingPhotoPath, setExistingPhotoPath] = useState<string | null>(null);

  const [qrOpen, setQrOpen] = useState(false);
  const [selected, setSelected] = useState<any>(null);

  // Import states
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
      const kSnap = await getDocs(collection(db, "pesantren", pid, "kelas"));
      setKelasList(kSnap.docs.map((d) => ({ id: d.id, nama: d.data().nama })));
    } catch (err) {
      console.error("Error loading refs:", err);
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const resetForm = () => {
    setFormData({
      name: "", nisn: "", nis_lokal: "", nik: "", jenisKelamin: "L", tempatLahir: "", tanggalLahir: "", agama: "Islam", kewarganegaraan: "WNI", anak_ke: "",
      email: "", no_hp: "",
      jalan: "", rt: "", rw: "", dusun: "", desa_kelurahan: "", kecamatan: "", kode_pos: "", jenis_tinggal: "", transportasi: "",
      ayah_nama: "", ayah_nik: "", ayah_pendidikan: "", ayah_pekerjaan: "", ayah_penghasilan: "",
      ibu_nama: "", ibu_nik: "", ibu_pendidikan: "", ibu_pekerjaan: "", ibu_penghasilan: "",
      wali_nama: "", wali_nik: "", wali_pendidikan: "", wali_pekerjaan: "", wali_penghasilan: "",
      unit_sekolah: "", kelas: "", status: "aktif",
    });
    setCustomUsername(""); setCustomPassword(""); setExistingMappingKey("");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(null); setError(null);
    setActiveTab("pribadi");
  };

  const handleOpenAdd = () => {
    setIsEdit(false); setExistingId(""); resetForm(); setIsOpen(true);
  };

  const handleOpenEdit = (s: any) => {
    const entry = Object.entries(mappings).find(([, value]) => value.linkedId === s.id);
    setIsEdit(true); setExistingId(s.id);
    
    // Map nested objects to flat state
    setFormData({
      name: s.nama_lengkap || s.name || "",
      nisn: s.nisn || "",
      nis_lokal: s.nis_lokal || s.nis || "",
      nik: s.nik || "",
      jenisKelamin: s.jenis_kelamin || s.jenisKelamin || "L",
      tempatLahir: s.tempat_lahir || "",
      tanggalLahir: s.tanggal_lahir || s.tanggalLahir || "",
      agama: s.agama || "Islam",
      kewarganegaraan: s.kewarganegaraan || "WNI",
      anak_ke: s.anak_ke?.toString() || "",
      email: s.kontak?.email || s.email || "",
      no_hp: s.kontak?.no_hp || s.nomorHpWali || "",
      jalan: s.alamat?.jalan || "",
      rt: s.alamat?.rt || "",
      rw: s.alamat?.rw || "",
      dusun: s.alamat?.dusun || "",
      desa_kelurahan: s.alamat?.desa_kelurahan || "",
      kecamatan: s.alamat?.kecamatan || "",
      kode_pos: s.alamat?.kode_pos || "",
      jenis_tinggal: s.alamat?.jenis_tinggal || "",
      transportasi: s.alamat?.transportasi || "",
      ayah_nama: s.orang_tua?.ayah?.nama || s.namaAyah || "",
      ayah_nik: s.orang_tua?.ayah?.nik || "",
      ayah_pendidikan: s.orang_tua?.ayah?.pendidikan || "",
      ayah_pekerjaan: s.orang_tua?.ayah?.pekerjaan || "",
      ayah_penghasilan: s.orang_tua?.ayah?.penghasilan || "",
      ibu_nama: s.orang_tua?.ibu?.nama || s.namaIbu || "",
      ibu_nik: s.orang_tua?.ibu?.nik || "",
      ibu_pendidikan: s.orang_tua?.ibu?.pendidikan || "",
      ibu_pekerjaan: s.orang_tua?.ibu?.pekerjaan || "",
      ibu_penghasilan: s.orang_tua?.ibu?.penghasilan || "",
      wali_nama: s.orang_tua?.wali?.nama || s.namaOrangTua || "",
      wali_nik: s.orang_tua?.wali?.nik || "",
      wali_pendidikan: s.orang_tua?.wali?.pendidikan || "",
      wali_pekerjaan: s.orang_tua?.wali?.pekerjaan || "",
      wali_penghasilan: s.orang_tua?.wali?.penghasilan || "",
      unit_sekolah: s.akademik?.unit_sekolah || s.unit_sekolah || "",
      kelas: s.akademik?.kelas || s.kelas || "",
      status: s.akademik?.status || s.status || "aktif",
    });

    setCustomUsername(""); setCustomPassword("");
    setExistingMappingKey(entry?.[0] || "");
    setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(s.photoPath || null);
    setError(null); setActiveTab("pribadi"); setIsOpen(true);
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
    if (!formData.name) { setError("Nama wajib diisi"); return; }
    if (!formData.nisn && !formData.nis_lokal && !formData.nik) {
      setError("Minimal satu identitas (NISN / NIS Lokal / NIK) wajib diisi!");
      setActiveTab("pribadi");
      return;
    }
    const pid = profile?.pesantrenId;
    if (!pid) return;

    // Use primary identitas for default mapping
    const primaryId = formData.nisn || formData.nis_lokal || formData.nik;
    const cleanPrimaryId = primaryId.trim().replace(/[^a-z0-9]/gi, "");
    
    if (formData.email.trim() && !/\S+@\S+\.\S+/.test(formData.email.trim())) { setError("Format email tidak valid"); return; }
    setError(null); setSaving(true);
    
    try {
      const santriDocId = isEdit ? existingId : doc(collection(db, "pesantren", pid, "santri")).id;
      const santriRef = doc(db, "pesantren", pid, "santri", santriDocId);
      
      const mappingKey = customUsername.trim()
        ? customUsername.trim().toLowerCase().replace(/[^a-z0-9]/g, "")
        : cleanPrimaryId;
      const mappingRef = doc(db, "pesantren", pid, "user_mappings", mappingKey);

      let finalPhotoUrl = existingPhotoPath;
      if (photoFile) {
        try {
          const photoRef = ref(storage, `santri_photos/${santriDocId}.jpg`);
          const up = await uploadBytes(photoRef, photoFile);
          finalPhotoUrl = await getDownloadURL(up.ref);
        } catch (uErr) { console.warn("Upload foto gagal:", uErr); }
      }

      // Build structured Dapodik payload
      const payload = {
        id: santriDocId,
        nisn: formData.nisn.trim(),
        nis_lokal: formData.nis_lokal.trim(),
        nik: formData.nik.trim(),
        nama_lengkap: formData.name.trim(),
        name: formData.name.trim(), // backward compatibility
        jenis_kelamin: formData.jenisKelamin,
        tempat_lahir: formData.tempatLahir.trim(),
        tanggal_lahir: formData.tanggalLahir || null,
        agama: formData.agama,
        kewarganegaraan: formData.kewarganegaraan,
        anak_ke: formData.anak_ke ? parseInt(formData.anak_ke) : null,
        photoPath: finalPhotoUrl || null,
        kontak: {
          email: formData.email.trim() || null,
          no_hp: formData.no_hp.trim() || null,
        },
        alamat: {
          jalan: formData.jalan.trim(),
          rt: formData.rt.trim(),
          rw: formData.rw.trim(),
          dusun: formData.dusun.trim(),
          desa_kelurahan: formData.desa_kelurahan.trim(),
          kecamatan: formData.kecamatan.trim(),
          kode_pos: formData.kode_pos.trim(),
          jenis_tinggal: formData.jenis_tinggal.trim(),
          transportasi: formData.transportasi.trim(),
        },
        orang_tua: {
          ayah: { nama: formData.ayah_nama, nik: formData.ayah_nik, pendidikan: formData.ayah_pendidikan, pekerjaan: formData.ayah_pekerjaan, penghasilan: formData.ayah_penghasilan },
          ibu: { nama: formData.ibu_nama, nik: formData.ibu_nik, pendidikan: formData.ibu_pendidikan, pekerjaan: formData.ibu_pekerjaan, penghasilan: formData.ibu_penghasilan },
          wali: { nama: formData.wali_nama, nik: formData.wali_nik, pendidikan: formData.wali_pendidikan, pekerjaan: formData.wali_pekerjaan, penghasilan: formData.wali_penghasilan },
        },
        akademik: {
          unit_sekolah: formData.unit_sekolah,
          kelas: formData.kelas || null,
          status: formData.status,
          tanggal_masuk: isEdit ? undefined : new Date().toISOString(),
        }
      };

      await setDoc(santriRef, payload, { merge: true });

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
    if (!window.confirm("Hapus data santri ini beserta mapping loginnya?")) return;
    try {
      const pid = profile.pesantrenId;
      await deleteDoc(doc(db, "pesantren", pid, "santri", studentId));
      const entry = Object.entries(mappings).find(([, v]) => v.linkedId === studentId);
      if (entry) await deleteDoc(doc(db, "pesantren", pid, "user_mappings", entry[0])).catch(() => {});
      loadSantri();
    } catch (err) {
      console.error("Error deleting:", err);
      alert("Gagal menghapus");
    }
  };

  const handleOpenQr = (s: any) => {
    const entry = Object.entries(mappings).find(([, v]) => v.linkedId === s.id);
    const loginKey = entry ? entry[0] : ((s.nisn || s.nis_lokal || s.nik || "").replace(/[^a-z0-9]/gi, "") || s.id);
    setSelected({ ...s, loginKey, password: entry?.[1]?.defaultPassword || loginKey, qrValue: `pesantrenmu:login:${profile?.pesantrenId}:${loginKey}` });
    setQrOpen(true);
  };

  // Import logic
  const importSummary = useMemo(() => {
    const valid = importRows.filter((row) => !row.error).length;
    return { total: importRows.length, valid, invalid: importRows.length - valid };
  }, [importRows]);

  const handleImportFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportLoading(true); setImportError(null);
    try {
      const rows = await parseSantriExcelFile(file);
      setImportRows(rows); setImportFileName(file.name);
      if (rows.length === 0) setImportError("File Excel tidak berisi data.");
    } catch (err) {
      setImportError("Gagal membaca file Excel. Pastikan format file benar."); setImportRows([]);
    } finally {
      setImportLoading(false); e.target.value = "";
    }
  };

  const handleImportSave = async () => {
    const pid = profile?.pesantrenId;
    if (!pid) return;
    const validRows = importRows.filter((row) => !row.error);
    if (validRows.length === 0) { setImportError("Belum ada data valid untuk diimport."); return; }
    setImportSaving(true); setImportError(null);
    
    try {
      for (const row of validRows) {
        const cleanId = (row.nisn || row.nis_lokal || row.nik).trim().replace(/[^a-z0-9]/gi, "");
        const existing = santriList.find((item) => {
          const itemID = (item.nisn || item.nis_lokal || item.nik || "").replace(/[^a-z0-9]/gi, "");
          return itemID === cleanId;
        });

        const santriDocId = existing?.id || doc(collection(db, "pesantren", pid, "santri")).id;
        const santriRef = doc(db, "pesantren", pid, "santri", santriDocId);
        const mappingRef = doc(db, "pesantren", pid, "user_mappings", cleanId);

        const matchedKelas = row.kelas ? kelasList.find((item) => String(item.nama || "").toLowerCase() === row.kelas.toLowerCase()) : null;

        const payload: any = {
          id: santriDocId,
          nama_lengkap: row.name.trim(),
          name: row.name.trim(),
          nisn: row.nisn.trim() || existing?.nisn || "",
          nis_lokal: row.nis_lokal.trim() || existing?.nis_lokal || "",
          nik: row.nik.trim() || existing?.nik || "",
          jenis_kelamin: row.gender || "L",
          tempat_lahir: row.tempatLahir || existing?.tempat_lahir || "",
          tanggal_lahir: row.tanggalLahir || existing?.tanggal_lahir || null,
        };

        if (!existing) {
          payload.kontak = { email: row.email.trim() || null, no_hp: row.hpWali.trim() || null };
          payload.akademik = { unit_sekolah: row.unit_sekolah || "", kelas: matchedKelas?.nama || null, status: row.status || "aktif" };
        } else {
          if (row.email) payload.kontak = { ...existing.kontak, email: row.email };
          if (row.hpWali) payload.kontak = { ...existing.kontak, no_hp: row.hpWali };
          if (row.unit_sekolah || row.kelas || row.status) {
             payload.akademik = { 
               ...existing.akademik, 
               unit_sekolah: row.unit_sekolah || existing.akademik?.unit_sekolah,
               kelas: matchedKelas?.nama || existing.akademik?.kelas,
               status: row.status || existing.akademik?.status
             };
          }
        }

        await setDoc(santriRef, payload, { merge: true });
        await setDoc(mappingRef, { linkedId: santriDocId, role: "orangTua", defaultPassword: row.password || cleanId }, { merge: true });
      }
      setImportOpen(false); setImportRows([]); setImportFileName(""); await loadSantri();
    } catch (err) {
      console.error(err); setImportError("Gagal menyimpan hasil import ke Firebase.");
    } finally {
      setImportSaving(false);
    }
  };

  const canManage = profile?.role === "admin" || profile?.role === "superAdmin";

  if (!canManage) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center p-6 bg-white dark:bg-white/[0.03] rounded-2xl border border-gray-200 dark:border-gray-800">
        <ShieldAlert size={48} className="text-error-500 mb-4" />
        <h3 className="text-lg font-bold text-gray-800 dark:text-white">Akses Ditolak</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Halaman ini hanya untuk Administrator.</p>
      </div>
    );
  }

  const filtered = [...santriList].filter((s) => {
    const sName = s.nama_lengkap || s.name || "";
    const primaryId = s.nisn || s.nis_lokal || s.nik || "";
    return sName.toLowerCase().includes(search.toLowerCase()) || primaryId.toLowerCase().includes(search.toLowerCase());
  }).sort((a, b) => String(a.nama_lengkap || a.name || "").localeCompare(String(b.nama_lengkap || b.name || ""), "id", { sensitivity: "base" }));

  return (
    <>
      <PageMeta title="Master Data Santri | PesantrenMu Admin" description="Kelola master data santri seluruh unit pesantren" />
      
      <div className="space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Data Santri (Dapodik)</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Pusat master data santri lintas unit pesantren.</p>
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
          <input type="text" placeholder="Cari nama atau NISN/NIK..." value={search} onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-4 py-2.5 bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 text-gray-900 dark:text-white" />
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-brand-500 border-t-transparent rounded-full animate-spin"></div></div>
        ) : (
          <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden dark:bg-white/[0.03] dark:border-gray-800">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-100 dark:border-gray-800 bg-gray-50 text-gray-500 dark:bg-white/[0.02] dark:text-gray-400">
                    <th className="p-4">Santri</th>
                    <th className="p-4">Identitas Dasar</th>
                    <th className="p-4">Unit / Kelas</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {filtered.length === 0 ? (
                    <tr><td colSpan={5} className="p-8 text-center text-gray-500">Belum ada data santri.</td></tr>
                  ) : filtered.map((s) => (
                    <tr key={s.id} className="text-gray-700 dark:text-gray-300 hover:bg-gray-50/50 dark:hover:bg-white/[0.01]">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <img src={s.photoPath || defaultAvatar} alt={s.nama_lengkap || s.name} className="h-10 w-10 rounded-full object-cover border border-gray-100 dark:border-gray-800" />
                          <div>
                            <p className="font-semibold text-gray-900 dark:text-white">{s.nama_lengkap || s.name}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">{s.jenis_kelamin === "P" ? "Perempuan" : "Laki-laki"}</p>
                          </div>
                        </div>
                      </td>
                      <td className="p-4 text-xs space-y-1">
                        <div>NISN: <span className="font-mono font-semibold text-gray-900 dark:text-white">{s.nisn || "-"}</span></div>
                        <div>NIS Lokal: <span className="font-mono">{s.nis_lokal || s.nis || "-"}</span></div>
                        <div>NIK: <span className="font-mono">{s.nik || "-"}</span></div>
                      </td>
                      <td className="p-4">
                        <p className="font-semibold text-gray-800 dark:text-gray-200">{s.akademik?.unit_sekolah || s.unit_sekolah || "-"}</p>
                        <p className="text-xs text-gray-500">Kelas: {s.akademik?.kelas || s.kelas || "-"}</p>
                      </td>
                      <td className="p-4">
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${(s.akademik?.status || s.status) === "nonaktif" ? "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300" : "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"}`}>
                          {(s.akademik?.status || s.status) === "nonaktif" ? "Nonaktif" : "Aktif"}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-2">
                          <button onClick={() => handleOpenQr(s)} title="Kartu Login" className="p-1.5 text-gray-400 hover:text-brand-500"><QrCode size={16} /></button>
                          <button onClick={() => handleOpenEdit(s)} title="Detail & Edit" className="p-1.5 text-gray-400 hover:text-blue-600"><Edit2 size={16} /></button>
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

      {/* Modal Edit Dapodik */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex justify-center p-4 bg-black/50 backdrop-blur-sm overflow-y-auto items-start">
          <div className="w-full max-w-4xl mt-6 mb-12 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-xl flex flex-col h-[85vh]">
            
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <h3 className="text-lg font-bold text-gray-800 dark:text-white">
                {isEdit ? "Kelola Master Data Dapodik Santri" : "Pendaftaran Santri Baru"}
              </h3>
              <button onClick={() => setIsOpen(false)} className="p-2 bg-gray-100 dark:bg-gray-800 text-gray-500 rounded-full hover:bg-gray-200 transition"><X size={16} /></button>
            </div>

            {/* Error Banner */}
            {error && <div className="mx-6 mt-4 p-3 text-xs font-semibold text-error-700 bg-error-50 border border-error-100 rounded-xl dark:bg-error-500/10 dark:text-error-400 shrink-0">{error}</div>}

            {/* Tab Navigation (Only show in Edit mode to prevent overwhelming on Add) */}
            {isEdit && (
              <div className="px-6 flex items-center gap-1 overflow-x-auto border-b border-gray-100 dark:border-gray-800 custom-scrollbar shrink-0 pt-4">
                {[
                  { id: "pribadi", label: "Data Pribadi" },
                  { id: "akademik", label: "Akademik" },
                  { id: "kontak", label: "Kontak & Akun" },
                  { id: "alamat", label: "Alamat Tinggal" },
                  { id: "ortu", label: "Data Orang Tua" },
                ].map((t) => (
                  <button key={t.id} type="button" onClick={() => setActiveTab(t.id as any)}
                    className={`px-4 py-2 text-sm font-semibold whitespace-nowrap transition-colors border-b-2 ${activeTab === t.id ? "border-brand-500 text-brand-600 dark:text-brand-400" : "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400"}`}>
                    {t.label}
                  </button>
                ))}
              </div>
            )}

            {/* Modal Body */}
            <div className="p-6 flex-1 overflow-y-auto custom-scrollbar">
              <form id="santriForm" onSubmit={handleSave} className="space-y-6">
                
                {(!isEdit || activeTab === "pribadi") && (
                  <div className="space-y-4">
                    <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider">Identitas Diri</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <Field label="Nama Lengkap *"><input required value={formData.name} onChange={(e) => handleInputChange("name", e.target.value)} className={inputCls} /></Field>
                      <Field label="Jenis Kelamin"><select value={formData.jenisKelamin} onChange={(e) => handleInputChange("jenisKelamin", e.target.value)} className={inputCls}><option value="L">Laki-laki</option><option value="P">Perempuan</option></select></Field>
                      <Field label="NISN (Nasional)"><input value={formData.nisn} onChange={(e) => handleInputChange("nisn", e.target.value)} className={inputCls} /></Field>
                      <Field label="NIS Lokal"><input value={formData.nis_lokal} onChange={(e) => handleInputChange("nis_lokal", e.target.value)} className={inputCls} /></Field>
                      <Field label="NIK"><input value={formData.nik} onChange={(e) => handleInputChange("nik", e.target.value)} className={inputCls} /></Field>
                      <Field label="Tempat Lahir"><input value={formData.tempatLahir} onChange={(e) => handleInputChange("tempatLahir", e.target.value)} className={inputCls} /></Field>
                      <Field label="Tanggal Lahir"><input type="date" value={formData.tanggalLahir} onChange={(e) => handleInputChange("tanggalLahir", e.target.value)} className={inputCls} /></Field>
                      <Field label="Agama"><input value={formData.agama} onChange={(e) => handleInputChange("agama", e.target.value)} className={inputCls} /></Field>
                      <Field label="Kewarganegaraan"><input value={formData.kewarganegaraan} onChange={(e) => handleInputChange("kewarganegaraan", e.target.value)} className={inputCls} /></Field>
                      <Field label="Anak Ke-"><input type="number" value={formData.anak_ke} onChange={(e) => handleInputChange("anak_ke", e.target.value)} className={inputCls} /></Field>
                    </div>
                  </div>
                )}

                {(!isEdit || activeTab === "akademik") && (
                  <div className="space-y-4 mt-6">
                    <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider">Data Akademik</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <Field label="Unit Sekolah">
                        <select value={formData.unit_sekolah} onChange={(e) => handleInputChange("unit_sekolah", e.target.value)} className={inputCls}>
                          <option value="">-- Pilih Unit --</option>
                          <option value="SD">SD</option><option value="SMP">SMP</option><option value="SMA">SMA</option><option value="MTS">MTS</option><option value="MA">MA</option>
                        </select>
                      </Field>
                      <Field label="Kelas">
                        <select value={formData.kelas} onChange={(e) => handleInputChange("kelas", e.target.value)} className={inputCls}>
                          <option value="">-- Belum ditentukan --</option>
                          {kelasList.map((k) => <option key={k.id} value={k.nama}>{k.nama}</option>)}
                        </select>
                      </Field>
                      <Field label="Status Santri"><select value={formData.status} onChange={(e) => handleInputChange("status", e.target.value)} className={inputCls}><option value="aktif">Aktif</option><option value="nonaktif">Nonaktif</option></select></Field>
                    </div>
                  </div>
                )}

                {(!isEdit || activeTab === "kontak") && (
                  <div className="space-y-4 mt-6">
                    <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider">Kontak & Akses Login</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <Field label="Email (Pribadi/Ortu)"><input type="email" value={formData.email} onChange={(e) => handleInputChange("email", e.target.value)} className={inputCls} /></Field>
                      <Field label="No. HP (Pribadi/Ortu)"><input value={formData.no_hp} onChange={(e) => handleInputChange("no_hp", e.target.value)} placeholder="0812..." className={inputCls} /></Field>
                    </div>
                    
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-4 mt-2 bg-blue-50 dark:bg-blue-900/10 border border-dashed border-blue-200 dark:border-blue-800 rounded-xl">
                      {!isEdit ? (
                        <>
                          <Field label="Username Login (opsional)"><input value={customUsername} onChange={(e) => setCustomUsername(e.target.value)} placeholder="Bawaan: NISN/NIK" className={inputCls + " border-blue-100 dark:border-blue-800"} /></Field>
                          <Field label="Sandi Login (opsional)"><input value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="Bawaan: NISN/NIK" className={inputCls + " border-blue-100 dark:border-blue-800"} /></Field>
                        </>
                      ) : (
                        <>
                          <Field label="Username Login"><input disabled value={existingMappingKey || (formData.nisn || formData.nis_lokal || formData.nik || "").replace(/[^a-z0-9]/gi, "") || "-"} className={inputCls + " opacity-70 border-blue-100 dark:border-blue-800"} /></Field>
                          <Field label="Ganti Sandi Login"><input type="password" value={customPassword} onChange={(e) => setCustomPassword(e.target.value)} placeholder="Kosongkan jika tidak diubah" className={inputCls + " border-blue-100 dark:border-blue-800"} /></Field>
                        </>
                      )}
                    </div>
                    
                    <div>
                      <label className={labelCls}>Foto Santri</label>
                      <div className="flex items-center gap-3">
                        <img src={photoPreview || existingPhotoPath || defaultAvatar} alt="Foto" className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-700" />
                        <label className="flex items-center gap-2 px-3 py-2 text-xs font-bold text-brand-500 bg-brand-50 dark:bg-brand-500/10 rounded-xl cursor-pointer hover:bg-brand-100">
                          <Upload size={14} /> Pilih Foto<input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                        </label>
                      </div>
                    </div>
                  </div>
                )}

                {(isEdit && activeTab === "alamat") && (
                  <div className="space-y-4 mt-6">
                    <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider">Alamat Tempat Tinggal</h4>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="md:col-span-3"><Field label="Jalan / Perumahan"><textarea rows={2} value={formData.jalan} onChange={(e) => handleInputChange("jalan", e.target.value)} className={inputCls} /></Field></div>
                      <Field label="RT"><input value={formData.rt} onChange={(e) => handleInputChange("rt", e.target.value)} className={inputCls} /></Field>
                      <Field label="RW"><input value={formData.rw} onChange={(e) => handleInputChange("rw", e.target.value)} className={inputCls} /></Field>
                      <Field label="Dusun"><input value={formData.dusun} onChange={(e) => handleInputChange("dusun", e.target.value)} className={inputCls} /></Field>
                      <Field label="Kelurahan / Desa"><input value={formData.desa_kelurahan} onChange={(e) => handleInputChange("desa_kelurahan", e.target.value)} className={inputCls} /></Field>
                      <Field label="Kecamatan"><input value={formData.kecamatan} onChange={(e) => handleInputChange("kecamatan", e.target.value)} className={inputCls} /></Field>
                      <Field label="Kode Pos"><input value={formData.kode_pos} onChange={(e) => handleInputChange("kode_pos", e.target.value)} className={inputCls} /></Field>
                      <Field label="Jenis Tinggal"><input value={formData.jenis_tinggal} onChange={(e) => handleInputChange("jenis_tinggal", e.target.value)} placeholder="Asrama / Bersama Ortu" className={inputCls} /></Field>
                      <Field label="Alat Transportasi"><input value={formData.transportasi} onChange={(e) => handleInputChange("transportasi", e.target.value)} placeholder="Jalan Kaki / Diantar" className={inputCls} /></Field>
                    </div>
                  </div>
                )}

                {(isEdit && activeTab === "ortu") && (
                  <div className="space-y-8 mt-6">
                    <div>
                      <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider mb-4 border-b border-gray-200 dark:border-gray-800 pb-2">Data Ayah Kandung</h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Field label="Nama Ayah"><input value={formData.ayah_nama} onChange={(e) => handleInputChange("ayah_nama", e.target.value)} className={inputCls} /></Field>
                        <Field label="NIK Ayah"><input value={formData.ayah_nik} onChange={(e) => handleInputChange("ayah_nik", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pendidikan Ayah"><input value={formData.ayah_pendidikan} onChange={(e) => handleInputChange("ayah_pendidikan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pekerjaan Ayah"><input value={formData.ayah_pekerjaan} onChange={(e) => handleInputChange("ayah_pekerjaan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Penghasilan Ayah"><input value={formData.ayah_penghasilan} onChange={(e) => handleInputChange("ayah_penghasilan", e.target.value)} className={inputCls} /></Field>
                      </div>
                    </div>
                    <div>
                      <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider mb-4 border-b border-gray-200 dark:border-gray-800 pb-2">Data Ibu Kandung</h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Field label="Nama Ibu"><input value={formData.ibu_nama} onChange={(e) => handleInputChange("ibu_nama", e.target.value)} className={inputCls} /></Field>
                        <Field label="NIK Ibu"><input value={formData.ibu_nik} onChange={(e) => handleInputChange("ibu_nik", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pendidikan Ibu"><input value={formData.ibu_pendidikan} onChange={(e) => handleInputChange("ibu_pendidikan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pekerjaan Ibu"><input value={formData.ibu_pekerjaan} onChange={(e) => handleInputChange("ibu_pekerjaan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Penghasilan Ibu"><input value={formData.ibu_penghasilan} onChange={(e) => handleInputChange("ibu_penghasilan", e.target.value)} className={inputCls} /></Field>
                      </div>
                    </div>
                    <div>
                      <h4 className="text-sm font-bold uppercase text-brand-500 tracking-wider mb-4 border-b border-gray-200 dark:border-gray-800 pb-2">Data Wali (Opsional)</h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Field label="Nama Wali"><input value={formData.wali_nama} onChange={(e) => handleInputChange("wali_nama", e.target.value)} className={inputCls} /></Field>
                        <Field label="NIK Wali"><input value={formData.wali_nik} onChange={(e) => handleInputChange("wali_nik", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pendidikan Wali"><input value={formData.wali_pendidikan} onChange={(e) => handleInputChange("wali_pendidikan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Pekerjaan Wali"><input value={formData.wali_pekerjaan} onChange={(e) => handleInputChange("wali_pekerjaan", e.target.value)} className={inputCls} /></Field>
                        <Field label="Penghasilan Wali"><input value={formData.wali_penghasilan} onChange={(e) => handleInputChange("wali_penghasilan", e.target.value)} className={inputCls} /></Field>
                      </div>
                    </div>
                  </div>
                )}
              </form>
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-gray-100 dark:border-gray-800 flex items-center justify-end gap-3 shrink-0 bg-gray-50/50 dark:bg-gray-800/20 rounded-b-2xl">
              <button type="button" onClick={() => setIsOpen(false)} className="px-4 py-2.5 text-sm font-bold text-gray-500 dark:text-gray-400">Tutup</button>
              <button type="submit" form="santriForm" disabled={saving} className="px-6 py-2.5 text-sm font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-xl disabled:opacity-50">
                {saving ? "Menyimpan..." : "Simpan Data"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Excel Import Modal */}
      {importOpen && (
        <div className="fixed inset-0 z-50 flex justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm items-start">
          <div className="mt-12 mb-12 w-full max-w-5xl rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="flex flex-col gap-4 border-b border-gray-100 pb-4 dark:border-gray-800 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">Import Data Dapodik Santri (Excel)</h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Sistem akan otomatis mendeteksi kolom sesuai template standar Dapodik.</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <button type="button" onClick={downloadSantriExcelTemplate} className="inline-flex items-center gap-2 rounded-xl bg-gray-100 px-3 py-2 text-xs font-bold text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200">
                  <Download size={14} /> Unduh Template Dapodik
                </button>
                <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-500 px-3 py-2 text-xs font-bold text-white hover:bg-brand-600">
                  <Upload size={14} /> Pilih File Excel
                  <input type="file" accept=".xlsx,.xls" onChange={handleImportFile} className="hidden" />
                </label>
              </div>
            </div>

            {importError && <div className="mt-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{importError}</div>}

            {importRows.length > 0 && (
               <div className="mt-4 grid gap-4 md:grid-cols-3">
                 <div className="rounded-2xl bg-gray-50 p-4 dark:bg-white/5">
                   <div className="text-xs uppercase text-gray-400">File</div>
                   <div className="mt-1 text-sm font-semibold text-gray-800 dark:text-white">{importFileName}</div>
                 </div>
                 <div className="rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 p-4 border border-emerald-100 dark:border-emerald-800">
                   <div className="text-xs uppercase text-emerald-600 dark:text-emerald-400 font-bold">Data Valid Siap Import</div>
                   <div className="mt-1 text-lg font-bold text-emerald-700 dark:text-emerald-300">{importSummary.valid} baris</div>
                 </div>
                 <div className="rounded-2xl bg-error-50 dark:bg-error-500/10 p-4 border border-error-100 dark:border-error-800">
                   <div className="text-xs uppercase text-error-600 dark:text-error-400 font-bold">Data Invalid (Ditolak)</div>
                   <div className="mt-1 text-lg font-bold text-error-700 dark:text-error-300">{importSummary.invalid} baris</div>
                 </div>
               </div>
            )}

            <div className="mt-4 rounded-2xl border border-gray-200 dark:border-gray-800">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-gray-100 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-white/[0.02] dark:text-gray-400">
                      <th className="p-3">Baris</th>
                      <th className="p-3">Nama</th>
                      <th className="p-3">Identitas Utama</th>
                      <th className="p-3">Unit</th>
                      <th className="p-3">Kelas</th>
                      <th className="p-3">Status Evaluasi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {importLoading ? (
                      <tr><td colSpan={6} className="p-8 text-center text-gray-500">Membaca file Excel...</td></tr>
                    ) : importRows.length === 0 ? (
                      <tr><td colSpan={6} className="p-8 text-center text-gray-500">Belum ada preview data.</td></tr>
                    ) : importRows.map((row) => (
                      <tr key={`${row.rowNumber}-${row.nisn}`} className="text-gray-700 dark:text-gray-300">
                        <td className="p-3 font-mono text-xs">{row.rowNumber}</td>
                        <td className="p-3 font-semibold text-gray-900 dark:text-white">{row.name || "-"}</td>
                        <td className="p-3 text-xs">
                           <div>NISN: <span className="font-mono">{row.nisn || "-"}</span></div>
                           <div>NIK: <span className="font-mono">{row.nik || "-"}</span></div>
                        </td>
                        <td className="p-3">{row.unit_sekolah || "-"}</td>
                        <td className="p-3">{row.kelas || "-"}</td>
                        <td className="p-3">
                          {row.error ? (
                            <span className="inline-flex rounded-full bg-error-50 px-2.5 py-1 text-xs font-semibold text-error-600 dark:bg-error-500/10 dark:text-error-400">{row.error}</span>
                          ) : (
                            <span className="inline-flex rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">Valid</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
              <button type="button" onClick={() => { setImportOpen(false); setImportRows([]); setImportFileName(""); setImportError(null); }} className="px-4 py-2 text-xs font-bold text-gray-500 dark:text-gray-400">Batal</button>
              <button type="button" disabled={importSaving || importSummary.valid === 0} onClick={handleImportSave} className="inline-flex items-center gap-2 rounded-xl bg-brand-500 px-6 py-2 text-sm font-bold text-white hover:bg-brand-600 disabled:opacity-50">
                <FileSpreadsheet size={16} /> {importSaving ? "Memproses Data..." : `Eksekusi Import (${importSummary.valid})`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* QR Code Modal (Login Access) */}
      {qrOpen && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-6 shadow-xl dark:border-gray-800 dark:bg-gray-900">
            <div className="rounded-2xl border border-brand-200 bg-white p-4 dark:border-brand-500/20 dark:bg-gray-950/40">
              <div className="mb-4 flex items-center justify-between">
                <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-500">Akses Portal Wali</p>
                <QrCode size={18} className="text-brand-500" />
              </div>
              <div className="mb-4 flex items-center gap-3">
                <img src={selected.photoPath || defaultAvatar} alt={selected.nama_lengkap || selected.name} className="h-12 w-12 rounded-xl object-cover border border-brand-100 dark:border-brand-500/20" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-gray-900 dark:text-white">{selected.nama_lengkap || selected.name}</p>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">ID: <span className="font-mono">{selected.loginKey}</span></p>
                </div>
              </div>
              <div className="flex justify-center rounded-xl bg-white p-4">
                <QRCodeSVG value={selected.qrValue} size={180} />
              </div>
            </div>
            <button onClick={() => setQrOpen(false)} className="mt-5 w-full rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white hover:bg-brand-600">Tutup</button>
          </div>
        </div>
      )}
    </>
  );
}

const inputCls = "w-full px-3 py-2.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:text-white transition-all";
const labelCls = "block text-xs font-bold text-gray-700 dark:text-gray-300 uppercase mb-1.5";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (<div><label className={labelCls}>{label}</label>{children}</div>);
}
