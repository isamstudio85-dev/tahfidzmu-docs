import { useCallback, useMemo } from "react";
import { Link, useLocation } from "react-router";

import {
  GridIcon,
  ListIcon,
  PageIcon,
  TableIcon,
  UserCircleIcon,
} from "../icons";
import { useSidebar } from "../context/SidebarContext";
import { useAuth } from "../context/AuthContext";

type NavItem = {
  name: string;
  icon: React.ReactNode;
  path?: string;
};

const adminNavItems: NavItem[] = [
  {
    icon: <GridIcon />,
    name: "Dashboard",
    path: "/",
  },
  {
    icon: <UserCircleIcon />,
    name: "Data Santri",
    path: "/santri",
  },
  {
    icon: <ListIcon />,
    name: "Data Asatidz & Staf",
    path: "/asatidz",
  },
  {
    icon: <TableIcon />,
    name: "Data Kelas & Asrama",
    path: "/kelas",
  },
  {
    icon: <PageIcon />,
    name: "Manajemen Institusi",
    path: "/institusi",
  },
];

const superAdminNavItems: NavItem[] = [
  {
    icon: <GridIcon />,
    name: "Dashboard",
    path: "/",
  },
  {
    icon: <UserCircleIcon />,
    name: "Manajemen Pengguna",
    path: "/pengguna",
  },
  {
    icon: <TableIcon />,
    name: "Keuangan Global",
    path: "/keuangan",
  },
];

const AppSidebar: React.FC = () => {
  const { isExpanded, isMobileOpen, isHovered, setIsHovered } = useSidebar();
  const { profile } = useAuth();
  const location = useLocation();

  const navItems = useMemo(() => {
    if (profile?.role === "superAdmin") return superAdminNavItems;

    // If Admin or Musyrif Coordinator, show Admin Menu
    if (profile?.role === "admin") {
      return adminNavItems;
    }

    if (profile?.isKoordinator) {
      const forbiddenPaths = ["/pesantren-info", "/tagihan", "/musyrif", "/pengawas", "/voucher"];
      return adminNavItems.filter((item) => !item.path || !forbiddenPaths.includes(item.path));
    }

    return adminNavItems;
  }, [profile]);

  const isActive = useCallback(
    (path: string) => location.pathname === path,
    [location.pathname]
  );
  const renderMenuItems = (items: NavItem[]) => (
    <ul className="flex flex-col gap-1">
      {items.map((nav) => (
        <li key={nav.name}>
          {nav.path && (
            <Link
              to={nav.path}
              className={`menu-item group ${
                isActive(nav.path) ? "menu-item-active" : "menu-item-inactive"
              }`}
            >
              <span
                className={`menu-item-icon-size ${
                  isActive(nav.path)
                    ? "menu-item-icon-active"
                    : "menu-item-icon-inactive"
                }`}
              >
                {nav.icon}
              </span>
              {(isExpanded || isHovered || isMobileOpen) && (
                <span className="menu-item-text">{nav.name}</span>
              )}
            </Link>
          )}
        </li>
      ))}
    </ul>
  );

  return (
    <aside
      className={`fixed mt-[76px] flex flex-col lg:mt-0 top-0 px-5 left-0 bg-white dark:bg-gray-900 dark:border-gray-800 text-gray-900 h-screen transition-all duration-300 ease-in-out z-50 border-r border-gray-200
        ${
          isExpanded || isMobileOpen
            ? "w-[290px]"
            : isHovered
            ? "w-[290px]"
            : "w-[90px]"
        }
        ${isMobileOpen ? "translate-x-0" : "-translate-x-full"}
        lg:translate-x-0`}
      onMouseEnter={() => !isExpanded && setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div
        className="flex h-[76px] items-center justify-center border-b border-gray-200 dark:border-gray-800 mb-6"
      >
        <Link to="/" className="flex items-center justify-center">
          {isExpanded || isHovered || isMobileOpen ? (
            <div className="flex items-center gap-3">
              <img src="/pesantrenmu.png" alt="Logo PesantrenMu" className="w-8 h-8 object-contain drop-shadow-sm" />
              <div 
                className="text-[22px] font-black tracking-wide"
                style={{
                  background: 'linear-gradient(to bottom, #72C6EF, #7BE4B5)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  color: 'transparent'
                }}
              >
                PesantrenMu
              </div>
            </div>
          ) : (
            <img src="/pesantrenmu.png" alt="Logo PesantrenMu" className="w-10 h-10 object-contain drop-shadow-sm" />
          )}
        </Link>
      </div>
      <div className="flex flex-col overflow-y-auto duration-300 ease-linear custom-scrollbar">
        <nav className="mb-6">
          {renderMenuItems(navItems)}
        </nav>
      </div>
    </aside>
  );
};

export default AppSidebar;
