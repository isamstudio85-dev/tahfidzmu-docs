import { useState } from "react";
import { useNavigate } from "react-router";
import { useAuth } from "../../context/AuthContext";
import tahfidzLogo from "../../../../assets/icons/logo-tahfidzmu.png";

export default function SignInFirebase() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email, password);
      navigate("/");
    } catch (err: unknown) {
      const code = (err as { code?: string })?.code || "";
      if (code.includes("invalid-credential") || code.includes("wrong-password") || code.includes("user-not-found")) {
        setError("Email atau kata sandi salah.");
      } else if (code.includes("too-many-requests")) {
        setError("Terlalu banyak percobaan. Coba lagi nanti.");
      } else {
        setError("Gagal masuk. Periksa koneksi dan coba lagi.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1">
      <div className="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
        <div>
          <div className="mb-5 sm:mb-8">
            <div className="mb-6 flex items-center gap-3 lg:hidden">
              <img src={tahfidzLogo} alt="TahfidzMU" className="h-12 w-12 rounded-2xl object-contain" />
              <div>
                <p className="text-lg font-bold tracking-[0.08em] text-gray-900 dark:text-white">TahfidzMU</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">Panel administrasi pesantren</p>
              </div>
            </div>
            <h1 className="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md">
              Masuk Admin
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Masuk dengan email dan kata sandi administrator untuk mengelola data pesantren secara terpusat.
            </p>
          </div>

          {error && (
            <div className="p-3 mb-4 text-sm text-error-700 bg-error-50 border border-error-100 rounded-lg dark:bg-error-500/10 dark:text-error-400">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-5">
              <div>
                <label className="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-400">
                  Email <span className="text-error-500">*</span>
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@pesantren.com"
                  className="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-none focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
                />
              </div>
              <div>
                <label className="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-400">
                  Kata Sandi <span className="text-error-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Masukkan kata sandi"
                    className="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 pr-11 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-none focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute -translate-y-1/2 cursor-pointer right-4 top-1/2 text-sm text-gray-500 dark:text-gray-400"
                  >
                    {showPassword ? "Sembunyikan" : "Lihat"}
                  </button>
                </div>
              </div>
              <button
                type="submit"
                disabled={loading}
                className="flex items-center justify-center w-full px-4 py-3 text-sm font-medium text-white transition rounded-lg bg-brand-500 hover:bg-brand-600 disabled:opacity-50"
              >
                {loading ? "Memproses..." : "Masuk"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
