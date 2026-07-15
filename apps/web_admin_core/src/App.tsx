import { BrowserRouter as Router, Navigate, Routes, Route } from "react-router";
import SignIn from "./pages/AuthPages/SignIn";
import NotFound from "./pages/OtherPage/NotFound";
import AppLayout from "./layout/AppLayout";
import { ScrollToTop } from "./components/common/ScrollToTop";
import ProtectedRoute from "./components/common/ProtectedRoute";
import Home from "./pages/Dashboard/Home";
import SantriManagement from "./pages/SantriManagement";
import AsatidzManagement from "./pages/AsatidzManagement";
import KelasManagement from "./pages/KelasManagement";
import PesantrenInfoManagement from "./pages/PesantrenInfoManagement";
import ProfileSettings from "./pages/ProfileSettings";
import SuperAdminPesantrenPage from "./pages/SuperAdminPesantrenPage";
import SuperAdminStaffPage from "./pages/SuperAdminStaffPage";
import SuperAdminFinancePage from "./pages/SuperAdminFinancePage";
import SuperAdminDashboard from "./pages/SuperAdminDashboard";
import { useAuth } from "./context/AuthContext";

function DashboardEntry() {
  const { profile } = useAuth();

  if (profile?.role === "superAdmin") {
    return <SuperAdminDashboard />;
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
            
            {/* Super Admin Routes */}
            <Route path="/pengguna" element={<SuperAdminStaffPage />} />
            <Route path="/keuangan" element={<SuperAdminFinancePage />} />
            
            {/* Core Master Data Routes */}
            <Route path="/santri" element={<SantriManagement />} />
             <Route path="/asatidz" element={<AsatidzManagement />} />
            <Route path="/kelas" element={<KelasManagement />} />
            <Route path="/institusi" element={<PesantrenInfoManagement />} />
            
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
