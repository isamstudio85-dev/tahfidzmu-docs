import { useState } from "react";
import { useNavigate } from "react-router";
import { useAuth } from "../../context/AuthContext";
import tahfidzLogo from "../../assets/images/TahfidzMU-logo.png";

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
    <div className="w-full max-w-md mx-auto">
      <div className="mb-8">
        <div className="mb-6 flex items-center gap-3 lg:hidden">
          <img src={tahfidzLogo} alt="TahfidzMU" className="h-14 w-14 rounded-2xl object-contain" />
          <div>
            <p className="text-xl font-bold tracking-tight text-gray-900 dark:text-white">TahfidzMU</p>
            <p className="text-xs text-gray-500 dark:text-gray-400">Web Admin Pesantren</p>
          </div>
        </div>
        <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white mb-2">
          Selamat Datang
        </h1>
        <p className="text-gray-500 dark:text-gray-400">
          Silakan masuk ke akun administrator Anda untuk mengelola data santri dan hafalan.
        </p>
      </div>

      {error && (
        <div className="p-4 mb-6 text-sm font-medium text-red-700 bg-red-50 border border-red-100 rounded-2xl dark:bg-red-500/10 dark:text-red-400 dark:border-red-500/20">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="space-y-6">
          <div>
            <label className="block mb-2 text-sm font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider">
              Alamat Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@pesantren.com"
              className="w-full px-5 py-4 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-2xl text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all shadow-sm"
            />
          </div>
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="block text-sm font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                Kata Sandi
              </label>
            </div>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-5 py-4 bg-gray-50 border border-gray-200 dark:bg-gray-800 dark:border-gray-700 rounded-2xl text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all shadow-sm"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 pr-5 flex items-center text-sm font-semibold text-brand-600 dark:text-brand-400 hover:text-brand-700"
              >
                {showPassword ? "Sembunyikan" : "Lihat"}
              </button>
            </div>
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 px-6 bg-brand-500 hover:bg-brand-600 text-white font-bold rounded-2xl shadow-lg shadow-brand-500/20 transition-all active:scale-[0.98] disabled:opacity-50"
          >
            {loading ? (
              <div className="flex items-center justify-center gap-2">
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                <span>Memproses...</span>
              </div>
            ) : (
              "Masuk ke Dashboard"
            )}
          </button>
        </div>
      </form>

      <div className="mt-8 pt-8 border-t border-gray-100 dark:border-gray-800 text-center">
        <p className="text-xs text-gray-400 dark:text-gray-500">
          &copy; {new Date().getFullYear()} TahfidzMU. Hak cipta dilindungi.
        </p>
      </div>
    </div>
  );
}

