import React from "react";
import GridShape from "../../components/common/GridShape";
import { Link } from "react-router";
import ThemeTogglerTwo from "../../components/common/ThemeTogglerTwo";
import tahfidzLogo from "../../assets/images/TahfidzMU-logo-white.png";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="relative p-6 bg-white z-1 dark:bg-gray-900 sm:p-0">
      <div className="relative flex flex-col justify-center w-full h-screen lg:flex-row dark:bg-gray-900 sm:p-0">
        <div className="w-full h-full lg:w-1/2 flex items-center justify-center p-6 sm:p-12">
          {children}
        </div>
        <div className="items-center hidden w-full h-full lg:w-1/2 bg-brand-600 dark:bg-brand-900 lg:grid">
          <div className="relative flex items-center justify-center z-1">
            {/* <!-- ===== Common Grid Shape Start ===== --> */}
            <GridShape />
            <div className="flex max-w-md flex-col items-center px-8 text-center">
              <Link to="/" className="mb-6 block">
                <img
                  width={200}
                  src={tahfidzLogo}
                  alt="TahfidzMU"
                  className="object-contain"
                />
              </Link>
              <h2 className="text-2xl font-bold text-white mb-2">Web Admin TahfidzMU</h2>
              <p className="text-white/100 text-sm">
                Membantu mengelola hafalan Al-Quran dan Kitab dengan cara yang mudah dan praktis.
              </p>
            </div>
          </div>
        </div>
        <div className="fixed z-50 hidden bottom-6 right-6 sm:block">
          <ThemeTogglerTwo />
        </div>
      </div>
    </div>
  );
}

