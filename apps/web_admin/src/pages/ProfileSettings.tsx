import { useState } from "react";
import { EmailAuthProvider, reauthenticateWithCredential, updatePassword, updateProfile } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import PageMeta from "../components/common/PageMeta";
import { useAuth } from "../context/AuthContext";
import { db, storage } from "../firebase";
import { Camera, X } from "lucide-react";
import defaultAvatar from "../../../assets/images/avatar-default.png";

export default function ProfileSettings() {
  const { user, profile, refreshProfile } = useAuth();
  const [name, setName] = useState(profile?.name || "");
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [existingPhotoPath, setExistingPhotoPath] = useState(profile?.photoPath || "");
  const [savingProfile, setSavingProfile] = useState(false);
  const [profileMessage, setProfileMessage] = useState<string | null>(null);
  const [profileError, setProfileError] = useState<string | null>(null);

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [savingPassword, setSavingPassword] = useState(false);
  const [passwordMessage, setPasswordMessage] = useState<string | null>(null);
  const [passwordError, setPasswordError] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        setProfileError("Ukuran foto maksimal 2MB");
        return;
      }
      setPhotoFile(file);
      setPhotoPreview(URL.createObjectURL(file));
      setProfileError(null);
    }
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    if (!name.trim()) {
      setProfileError("Nama wajib diisi.");
      return;
    }

    setSavingProfile(true);
    setProfileError(null);
    setProfileMessage(null);
    try {
      let finalPhotoUrl = existingPhotoPath;

      if (photoFile) {
        const photoRef = ref(storage, `admin_photos/${user.uid}.jpg`);
        const uploaded = await uploadBytes(photoRef, photoFile);
        finalPhotoUrl = await getDownloadURL(uploaded.ref);
      }

      await setDoc(
        doc(db, "users", user.uid),
        {
          name: name.trim(),
          photoPath: finalPhotoUrl || null,
        },
        { merge: true }
      );

      await updateProfile(user, {
        displayName: name.trim(),
        photoURL: finalPhotoUrl || null,
      });

      setExistingPhotoPath(finalPhotoUrl || "");
      setPhotoFile(null);
      setPhotoPreview(null);

      await refreshProfile();
      setProfileMessage("Profil berhasil diperbarui.");
    } catch (err: any) {
      console.error(err);
      setProfileError(`Gagal memperbarui profil: ${err.message || "unknown error"}`);
    } finally {
      setSavingProfile(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !user.email) return;
    if (!currentPassword.trim()) {
      setPasswordError("Sandi saat ini wajib diisi.");
      return;
    }
    if (newPassword.trim().length < 6) {
      setPasswordError("Sandi baru minimal 6 karakter.");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError("Konfirmasi sandi baru tidak sama.");
      return;
    }

    setSavingPassword(true);
    setPasswordError(null);
    setPasswordMessage(null);
    try {
      const credential = EmailAuthProvider.credential(user.email, currentPassword);
      await reauthenticateWithCredential(user, credential);
      await updatePassword(user, newPassword);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      setPasswordMessage("Kata sandi berhasil diubah.");
    } catch (err: any) {
      console.error(err);
      if (err?.code === "auth/wrong-password" || err?.code === "auth/invalid-credential") {
        setPasswordError("Sandi saat ini tidak cocok.");
      } else {
        setPasswordError(`Gagal mengganti kata sandi: ${err.message || "unknown error"}`);
      }
    } finally {
      setSavingPassword(false);
    }
  };

  return (
    <>
      <PageMeta title="Profil Admin | TahfidzMU Admin" description="Kelola nama, foto, dan kata sandi akun admin." />
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-bold text-gray-800 dark:text-white md:text-2xl">Profil Admin</h2>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Ubah nama yang tampil di pojok atas, foto profil, dan kata sandi akun login admin.</p>
        </div>

        <div className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
          <form onSubmit={handleSaveProfile} className="rounded-2xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-white/[0.03]">
            <h3 className="text-lg font-bold text-gray-800 dark:text-white">Informasi Profil</h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Perubahan di sini akan dipakai untuk nama dan avatar pada header web admin.</p>

            {profileError && <div className="mt-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{profileError}</div>}
            {profileMessage && <div className="mt-4 rounded-xl border border-emerald-100 bg-emerald-50 p-3 text-xs text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400">{profileMessage}</div>}

            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <Field label="Nama Tampilan *"><input required value={name} onChange={(e) => setName(e.target.value)} className={inputCls} /></Field>
              <Field label="Email Login"><input disabled value={profile?.email || ""} className={disabledInputCls} /></Field>
            </div>

            <div className="mt-4">
              <label className={labelCls}>Foto Profil</label>
              <div className="flex items-center gap-4">
                <div className="relative group">
                  <img
                    src={photoPreview || existingPhotoPath || defaultAvatar}
                    alt="Preview"
                    className="h-20 w-20 rounded-2xl border border-gray-200 object-cover dark:border-gray-700"
                  />
                  {(photoPreview || existingPhotoPath) && (
                    <button type="button" onClick={() => { setPhotoFile(null); setPhotoPreview(null); setExistingPhotoPath(""); }} className="absolute -right-2 -top-2 rounded-full bg-error-500 p-1 text-white shadow-lg">
                      <X size={14} />
                    </button>
                  )}
                </div>
                <div className="flex-1">
                  <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-brand-50 px-4 py-2.5 text-sm font-bold text-brand-600 transition hover:bg-brand-100 dark:bg-brand-500/10 dark:text-brand-400">
                    <Camera size={18} /> Pilih Foto Baru
                    <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                  </label>
                  <p className="mt-2 text-[10px] text-gray-500">Maksimal 2MB. Format: JPG, PNG.</p>
                </div>
              </div>
            </div>

            <div className="mt-6 flex justify-end border-t border-gray-100 pt-4 dark:border-gray-800">
              <button type="submit" disabled={savingProfile} className="rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white hover:bg-brand-600 disabled:opacity-50">{savingProfile ? "Menyimpan..." : "Simpan Profil"}</button>
            </div>
          </form>

          <form onSubmit={handleChangePassword} className="rounded-2xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-white/[0.03]">
            <h3 className="text-lg font-bold text-gray-800 dark:text-white">Ganti Kata Sandi</h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Gunakan sandi login admin saat ini untuk mengesahkan perubahan sandi baru.</p>

            {passwordError && <div className="mt-4 rounded-xl border border-error-100 bg-error-50 p-3 text-xs text-error-700 dark:bg-error-500/10 dark:text-error-400">{passwordError}</div>}
            {passwordMessage && <div className="mt-4 rounded-xl border border-emerald-100 bg-emerald-50 p-3 text-xs text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400">{passwordMessage}</div>}

            <div className="mt-5 space-y-4">
              <Field label="Sandi Saat Ini *"><input required type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} className={inputCls} /></Field>
              <Field label="Sandi Baru *"><input required type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className={inputCls} /></Field>
              <Field label="Konfirmasi Sandi Baru *"><input required type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} className={inputCls} /></Field>
            </div>

            <div className="mt-6 flex justify-end border-t border-gray-100 pt-4 dark:border-gray-800">
              <button type="submit" disabled={savingPassword} className="rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white hover:bg-brand-600 disabled:opacity-50">{savingPassword ? "Mengubah..." : "Ubah Kata Sandi"}</button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}

const inputCls = "w-full rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-gray-700 dark:bg-gray-800 dark:text-white";
const disabledInputCls = "w-full rounded-xl border border-gray-200 bg-gray-100 px-3 py-2 text-sm text-gray-500 dark:border-gray-700 dark:bg-gray-800/70 dark:text-gray-400";
const labelCls = "mb-1 block text-xs font-bold uppercase text-gray-700 dark:text-gray-300";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><label className={labelCls}>{label}</label>{children}</div>;
}