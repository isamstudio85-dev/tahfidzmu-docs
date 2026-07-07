import { createContext, useCallback, useContext, useEffect, useState, ReactNode } from "react";
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../firebase";

// Profile mirrors the Flutter app's /users/{uid} document.
export interface AdminProfile {
  uid: string;
  name: string;
  role: string; // 'superAdmin' | 'admin' | 'musyrif' | 'pengawas' | 'pimpinan' | 'orangTua'
  pesantrenId: string | null;
  email: string | null;
  photoPath: string | null;
}

interface AuthContextValue {
  user: User | null;
  profile: AdminProfile | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const SUPER_ADMIN_EMAIL = "dasamsamsudin87@gmail.com";

function getEmailFallbackName(email: string | null | undefined) {
  if (!email) return "Admin";
  return email.split("@")[0] || "Admin";
}

function getProfileName(data: Record<string, unknown>, currentUser: User) {
  const candidates = [
    data.nama,
    data.name,
    data.username,
    data.fullName,
    data.displayName,
    currentUser.displayName,
    getEmailFallbackName(currentUser.email),
  ];

  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }

  return "Admin";
}

function getProfilePhoto(data: Record<string, unknown>, currentUser: User) {
  const candidates = [
    data.photoPath,
    data.photoUrl,
    data.avatar,
    data.avatarUrl,
    currentUser.photoURL,
  ];

  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }

  return null;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

async function loadAdminProfile(currentUser: User) {
  const snap = await getDoc(doc(db, "users", currentUser.uid));
  const data = (snap.exists() ? snap.data() : {}) as Record<string, unknown>;

  return {
    uid: currentUser.uid,
    name: getProfileName(data, currentUser),
    role:
      (data.role as string) ||
      (currentUser.email === SUPER_ADMIN_EMAIL ? "superAdmin" : "admin"),
    pesantrenId: (data.pesantrenId as string) ?? (data.pid as string) ?? null,
    email: currentUser.email,
    photoPath: getProfilePhoto(data, currentUser),
  } satisfies AdminProfile;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshProfile = useCallback(async () => {
    if (!auth.currentUser) {
      setProfile(null);
      return;
    }

    try {
      const nextProfile = await loadAdminProfile(auth.currentUser);
      setProfile(nextProfile);
    } catch (err) {
      console.error("Failed to refresh profile:", err);
      setProfile({
        uid: auth.currentUser.uid,
        name: getEmailFallbackName(auth.currentUser.email),
        role: auth.currentUser.email === SUPER_ADMIN_EMAIL ? "superAdmin" : "admin",
        pesantrenId: null,
        email: auth.currentUser.email,
        photoPath: auth.currentUser.photoURL,
      });
    }
  }, []);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        try {
          setProfile(await loadAdminProfile(currentUser));
        } catch (err) {
          console.error("Failed to load profile:", err);
          setProfile({
            uid: currentUser.uid,
            name: getEmailFallbackName(currentUser.email),
            role: currentUser.email === SUPER_ADMIN_EMAIL ? "superAdmin" : "admin",
            pesantrenId: null,
            email: currentUser.email,
            photoPath: currentUser.photoURL,
          });
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const login = async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email.trim(), password);
  };

  const logout = async () => {
    await signOut(auth);
  };

  return (
    <AuthContext.Provider value={{ user, profile, loading, login, logout, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
