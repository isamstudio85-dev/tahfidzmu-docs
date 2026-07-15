import { createContext, useCallback, useContext, useEffect, useMemo, useState, ReactNode } from "react";
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
  isKoordinator?: boolean;
  managedHalaqahIds?: string[];
}

interface AuthContextValue {
  user: User | null;
  profile: AdminProfile | null;
  loading: boolean;
  isImpersonating: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  switchToTenantAdmin: (pesantrenId: string) => void;
  switchBackToSuperAdmin: () => void;
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

  const role = (data.role as string) || (currentUser.email === SUPER_ADMIN_EMAIL ? "superAdmin" : "admin");
  const pesantrenId = (data.pesantrenId as string) ?? (data.pid as string) ?? null;
  const linkedId = data.linkedId as string | undefined;

  let isKoordinator = false;
  let managedHalaqahIds: string[] = [];

  if (role === "musyrif" && pesantrenId && linkedId) {
    try {
      const musyrifSnap = await getDoc(doc(db, "pesantren", pesantrenId, "musyrif", linkedId));
      if (musyrifSnap.exists()) {
        const mData = musyrifSnap.data();
        isKoordinator = Boolean(mData.isKoordinator);
        managedHalaqahIds = Array.isArray(mData.managedHalaqahIds) ? mData.managedHalaqahIds : [];
      }
    } catch (err) {
      console.error("Failed to load linked musyrif data:", err);
    }
  }

  return {
    uid: currentUser.uid,
    name: getProfileName(data, currentUser),
    role,
    pesantrenId,
    email: currentUser.email,
    photoPath: getProfilePhoto(data, currentUser),
    isKoordinator,
    managedHalaqahIds,
  } satisfies AdminProfile;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [baseProfile, setBaseProfile] = useState<AdminProfile | null>(null);
  const [impersonatedProfile, setImpersonatedProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const profile = impersonatedProfile ?? baseProfile;
  const isImpersonating = Boolean(impersonatedProfile);

  const refreshProfile = useCallback(async () => {
    if (!auth.currentUser) {
      setBaseProfile(null);
      setImpersonatedProfile(null);
      return;
    }

    try {
      const nextProfile = await loadAdminProfile(auth.currentUser);
      setBaseProfile(nextProfile);
    } catch (err) {
      console.error("Failed to refresh profile:", err);
      setBaseProfile({
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
      setImpersonatedProfile(null);
      if (currentUser) {
        try {
          setBaseProfile(await loadAdminProfile(currentUser));
        } catch (err) {
          console.error("Failed to load profile:", err);
          setBaseProfile({
            uid: currentUser.uid,
            name: getEmailFallbackName(currentUser.email),
            role: currentUser.email === SUPER_ADMIN_EMAIL ? "superAdmin" : "admin",
            pesantrenId: null,
            email: currentUser.email,
            photoPath: currentUser.photoURL,
          });
        }
      } else {
        setBaseProfile(null);
      }
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const login = async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email.trim(), password);
  };

  const logout = async () => {
    setImpersonatedProfile(null);
    await signOut(auth);
  };

  const switchToTenantAdmin = useCallback((pesantrenId: string) => {
    setImpersonatedProfile((current) => {
      const source = baseProfile ?? current;
      if (!source || source.role !== "superAdmin") return current;

      return {
        ...source,
        role: "admin",
        pesantrenId,
      };
    });
  }, [baseProfile]);

  const switchBackToSuperAdmin = useCallback(() => {
    setImpersonatedProfile(null);
  }, []);

  const contextValue = useMemo(
    () => ({
      user,
      profile,
      loading,
      isImpersonating,
      login,
      logout,
      refreshProfile,
      switchToTenantAdmin,
      switchBackToSuperAdmin,
    }),
    [user, profile, loading, isImpersonating, refreshProfile, switchToTenantAdmin, switchBackToSuperAdmin]
  );

  return (
    <AuthContext.Provider value={contextValue}>
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
