import { BrowserRouter as Router, Routes, Route } from "react-router";
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
import ProfileSettings from "./pages/ProfileSettings";

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
            <Route index path="/" element={<Home />} />
            <Route path="/santri" element={<SantriManagement />} />
            <Route path="/musyrif" element={<MusyrifManagement />} />
            <Route path="/pengawas" element={<PengawasManagement />} />
            <Route path="/kelas" element={<KelasManagement />} />
            <Route path="/halaqah" element={<HalaqahManagement />} />
            <Route path="/wisuda" element={<WisudaManagement />} />
            <Route path="/pesantren-info" element={<PesantrenInfoManagement />} />
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
