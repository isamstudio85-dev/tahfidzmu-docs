import { BrowserRouter as Router, Navigate, Routes, Route } from "react-router";
import SignIn from "./pages/AuthPages/SignIn";
import NotFound from "./pages/OtherPage/NotFound";
import AppLayout from "./layout/AppLayout";
import { ScrollToTop } from "./components/common/ScrollToTop";
import ProtectedRoute from "./components/common/ProtectedRoute";
import Home from "./pages/Dashboard/Home";
import SantriManagement from "./pages/SantriManagement";
import MusyrifManagement from "./pages/MusyrifManagement";
import KelasManagement from "./pages/KelasManagement";
import HalaqahManagement from "./pages/HalaqahManagement";
import PengawasManagement from "./pages/PengawasManagement";
import WisudaManagement from "./pages/WisudaManagement";
import PesantrenInfoManagement from "./pages/PesantrenInfoManagement";
import MonitoringProgres from "./pages/MonitoringProgres";
import InputHafalan from "./pages/InputHafalan";
import ProfileSettings from "./pages/ProfileSettings";
import SuperAdminPesantrenPage from "./pages/SuperAdminPesantrenPage";
import { useAuth } from "./context/AuthContext";

function DashboardEntry() {
  const { profile } = useAuth();

  if (profile?.role === "superAdmin") {
    return <Navigate to="/pesantren" replace />;
  }

  return <Home />;
}

export default function App() {
  return (
    <>
      <Router>
        <ScrollToTop />
        <Routes>
          {/* Protected Dashboard Layout */}
          <Route
            element={
              <ProtectedRoute>
                <AppLayout />
              </ProtectedRoute>
            }
          >
            <Route index path="/" element={<DashboardEntry />} />
            <Route path="/pesantren" element={<SuperAdminPesantrenPage />} />
            <Route path="/santri" element={<SantriManagement />} />
            <Route path="/musyrif" element={<MusyrifManagement />} />
            <Route path="/pengawas" element={<PengawasManagement />} />
            <Route path="/kelas" element={<KelasManagement />} />
            <Route path="/halaqah" element={<HalaqahManagement />} />
            <Route path="/wisuda" element={<WisudaManagement />} />
            <Route path="/pesantren-info" element={<PesantrenInfoManagement />} />
            <Route path="/monitoring" element={<MonitoringProgres />} />
            <Route path="/input-hafalan" element={<InputHafalan />} />
            <Route path="/profil" element={<ProfileSettings />} />
          </Route>

          {/* Auth Layout */}
          <Route path="/signin" element={<SignIn />} />

          {/* Fallback Route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Router>
    </>
  );
}
