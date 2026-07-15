import * as XLSX from "xlsx";

export type ParsedSantriImportRow = {
  rowNumber: number;
  name: string;
  nisn: string;
  nis_lokal: string;
  nik: string;
  email: string;
  gender: string;
  unit_sekolah: string;
  kelas: string;
  hpWali: string;
  tempatLahir: string;
  tanggalLahir: string;
  status: string;
  password?: string;
  error: string | null;
};

type RawRow = Record<string, unknown>;

const headerAliases: Record<string, string[]> = {
  name: ["nama", "name", "nama lengkap", "nama_lengkap"],
  nisn: ["nisn", "nomor induk siswa nasional"],
  nis_lokal: ["nis", "no induk santri", "nomor induk santri", "nis lokal"],
  nik: ["nik", "nomor induk kependudukan"],
  email: ["email", "e-mail", "mail"],
  gender: ["jenis kelamin", "gender", "jk", "l/p"],
  unit_sekolah: ["unit", "unit sekolah", "sekolah", "tingkat"],
  kelas: ["kelas", "rombel", "rombongan belajar"],
  hpWali: ["hp wali", "nomor hp wali", "no hp wali", "wa wali", "nomor hp orang tua"],
  tempatLahir: ["tempat lahir", "tempat_lahir", "kota lahir"],
  tanggalLahir: ["tanggal lahir", "tgl lahir", "tanggal_lahir"],
  status: ["status", "keaktifan"],
  password: ["password", "kata sandi", "sandi", "pass"],
};

function normalizeHeader(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ");
}

function getCellValue(row: RawRow, key: keyof typeof headerAliases) {
  const normalizedEntries = Object.entries(row).map(([header, value]) => [normalizeHeader(header), value] as const);
  const aliasSet = new Set(headerAliases[key].map(normalizeHeader));
  const hit = normalizedEntries.find(([header]) => aliasSet.has(header));
  return hit?.[1] ?? "";
}

function toText(value: unknown) {
  if (value == null) return "";
  return String(value).trim();
}

function normalizeGender(value: string) {
  const normalized = value.toLowerCase();
  if (["p", "perempuan", "wanita"].includes(normalized)) return "P";
  return "L";
}

function normalizeStatus(value: string) {
  const normalized = value.toLowerCase();
  if (["nonaktif", "non-active", "inactive"].includes(normalized)) return "nonaktif";
  return "aktif";
}

function normalizeDate(value: unknown) {
  const text = toText(value);
  if (!text) return "";

  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) return "";

  return parsed.toISOString().slice(0, 10);
}

function validateRow(row: Omit<ParsedSantriImportRow, "error">) {
  if (!row.name) return "Nama wajib diisi";
  if (!row.nisn && !row.nis_lokal && !row.nik) return "Minimal isi salah satu (NISN/NIS Lokal/NIK)";
  if (row.email && !/\S+@\S+\.\S+/.test(row.email)) return "Format email tidak valid";
  if (row.password && row.password.length < 6) return "Password minimal 6 karakter";
  return null;
}

export async function parseSantriExcelFile(file: File) {
  const buffer = await file.arrayBuffer();
  const workbook = XLSX.read(buffer, { type: "array" });
  const firstSheetName = workbook.SheetNames[0];

  if (!firstSheetName) return [] as ParsedSantriImportRow[];

  const sheet = workbook.Sheets[firstSheetName];
  const rows = XLSX.utils.sheet_to_json<RawRow>(sheet, {
    raw: false,
    defval: "",
  });

  return rows.map((source, index) => {
    const normalizedRow = {
      rowNumber: index + 2,
      name: toText(getCellValue(source, "name")),
      nisn: toText(getCellValue(source, "nisn")),
      nis_lokal: toText(getCellValue(source, "nis_lokal")),
      nik: toText(getCellValue(source, "nik")),
      email: toText(getCellValue(source, "email")),
      gender: normalizeGender(toText(getCellValue(source, "gender"))),
      unit_sekolah: toText(getCellValue(source, "unit_sekolah")),
      kelas: toText(getCellValue(source, "kelas")),
      hpWali: toText(getCellValue(source, "hpWali")),
      tempatLahir: toText(getCellValue(source, "tempatLahir")),
      tanggalLahir: normalizeDate(getCellValue(source, "tanggalLahir")),
      status: normalizeStatus(toText(getCellValue(source, "status"))),
      password: toText(getCellValue(source, "password")),
    };

    return {
      ...normalizedRow,
      error: validateRow(normalizedRow),
    };
  });
}

export function downloadSantriExcelTemplate() {
  const workbook = XLSX.utils.book_new();

  const sheetRows = [
    [
      "Nama Lengkap",
      "NISN",
      "NIS Lokal",
      "NIK",
      "Jenis Kelamin",
      "Tempat Lahir",
      "Tanggal Lahir",
      "Unit Sekolah",
      "Kelas",
      "No HP Wali",
      "Email",
      "Status",
      "Password",
    ],
    [
      "Ahmad Fauzi",
      "0123456789",
      "24001",
      "3201234567890001",
      "L",
      "Jakarta",
      "2012-05-10",
      "SMP",
      "7A",
      "081234567890",
      "wali.ahmad@example.com",
      "aktif",
      "SandiKuat123",
    ],
  ];

  const instructionRows = [
    ["Aturan Import Master Data Santri (Dapodik Base)"],
    ["Field wajib: Nama, dan minimal satu identitas (NISN / NIS Lokal / NIK)"],
    ["Kolom lain boleh dikosongkan (bisa dilengkapi mandiri oleh wali santri nantinya)"],
    ["Format tanggal lahir yang disarankan: YYYY-MM-DD"],
    ["Jenis Kelamin diisi L (Laki-laki) atau P (Perempuan)"],
    ["Password minimal 6 karakter. Jika kosong, sandi akan mengikuti NISN/NIK."],
  ];

  const dataSheet = XLSX.utils.aoa_to_sheet(sheetRows);
  const instructionSheet = XLSX.utils.aoa_to_sheet(instructionRows);

  XLSX.utils.book_append_sheet(workbook, dataSheet, "Santri");
  XLSX.utils.book_append_sheet(workbook, instructionSheet, "Petunjuk");

  XLSX.writeFile(workbook, "template-import-santri-dapodik.xlsx");
}