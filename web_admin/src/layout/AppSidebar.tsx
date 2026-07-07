import { useCallback } from "react";
import { Link, useLocation } from "react-router";
import tahfidzLogoIcon from "../../../assets/icons/logo-tahfidzmu.png";

import {
  GridIcon,
  ListIcon,
  PageIcon,
  TableIcon,
  UserCircleIcon,
} from "../icons";
import { useSidebar } from "../context/SidebarContext";

type NavItem = {
  name: string;
  icon: React.ReactNode;
  path?: string;
};

const navItems: NavItem[] = [
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
    name: "Data Musyrif",
    path: "/musyrif",
  },
  {
    icon: <UserCircleIcon />,
    name: "Data Pengawas",
    path: "/pengawas",
  },
  {
    icon: <TableIcon />,
    name: "Data Kelas",
    path: "/kelas",
  },
  {
    icon: <PageIcon />,
    name: "Data Halaqah",
    path: "/halaqah",
  },
  {
    icon: <ListIcon />,
    name: "Manajemen Wisuda",
    path: "/wisuda",
  },
  {
    icon: <PageIcon />,
    name: "Info Pesantren",
    path: "/pesantren-info",
  },
];

const AppSidebar: React.FC = () => {
  const { isExpanded, isMobileOpen, isHovered, setIsHovered } = useSidebar();
  const location = useLocation();
  const isActive = useCallback(
    (path: string) => location.pathname === path,
    [location.pathname]
  );
  const renderMenuItems = (items: NavItem[]) => (
    <ul className="flex flex-col gap-4">
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
      className={`fixed mt-16 flex flex-col lg:mt-0 top-0 px-5 left-0 bg-white dark:bg-gray-900 dark:border-gray-800 text-gray-900 h-screen transition-all duration-300 ease-in-out z-50 border-r border-gray-200 
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
        className={`flex py-8 ${
          !isExpanded && !isHovered ? "lg:justify-center" : "justify-start"
        }`}
      >
        <Link to="/" className="flex items-center gap-3">
          {isExpanded || isHovered || isMobileOpen ? (
            <div className="flex items-center gap-3">
              <img
                src={tahfidzLogoIcon}
                alt="TahfidzMU"
                className="h-11 w-11 rounded-2xl object-contain"
              />
              <div className="min-w-0">
                <p className="text-base font-bold tracking-[0.1em] text-gray-900 dark:text-white">TahfidzMU</p>
              </div>
            </div>
          ) : (
            <img
              src={tahfidzLogoIcon}
              alt="TahfidzMU"
              className="h-9 w-9 rounded-xl object-contain"
            />
          )}
        </Link>
      </div>
      <div className="flex flex-col overflow-y-auto duration-300 ease-linear no-scrollbar">
        <nav className="mb-6">
          <h2
            className={`mb-4 flex text-xs uppercase leading-[20px] text-gray-400 ${
              !isExpanded && !isHovered ? "lg:justify-center" : "justify-start"
            }`}
          >
            Menu Admin
          </h2>
          {renderMenuItems(navItems)}
        </nav>
      </div>
    </aside>
  );
};

export default AppSidebar;
