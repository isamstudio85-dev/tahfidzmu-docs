import * as XLSX from "xlsx";

export type ParsedSantriImportRow = {
  rowNumber: number;
  name: string;
  nis: string;
  email: string;
  gender: string;
  kelas: string;
  halaqah: string;
  wali: string;
  hpWali: string;
  targetHafalan: string;
  tanggalLahir: string;
  status: string;
  initialJuzList: number[];
  error: string | null;
};

type RawRow = Record<string, unknown>;

const headerAliases: Record<string, string[]> = {
  name: ["nama", "name", "nama lengkap", "nama_lengkap"],
  nis: ["nis", "no induk santri", "nomor induk santri"],
  email: ["email", "e-mail", "mail"],
  gender: ["jenis kelamin", "gender", "jk", "l/p"],
  kelas: ["kelas"],
  halaqah: ["halaqah", "halaqah id", "nama halaqah"],
  wali: ["wali", "nama wali", "nama orang tua", "nama orang tua / wali", "orang tua"],
  hpWali: ["hp wali", "nomor hp wali", "no hp wali", "wa wali", "nomor hp orang tua"],
  targetHafalan: ["target hafalan", "target hafalan (juz)", "target juz"],
  tanggalLahir: ["tanggal lahir", "tgl lahir", "tanggal_lahir"],
  status: ["status"],
  initialJuzList: ["hafalan awal", "juz awal", "initialmemorizedjuz", "initial juz"],
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

function parseInitialJuz(value: unknown) {
  const text = toText(value);
  if (!text) return [];

  return Array.from(
    new Set(
      text
        .split(/[^0-9]+/)
        .map((item) => Number(item))
        .filter((item) => Number.isInteger(item) && item >= 1 && item <= 30)
    )
  ).sort((a, b) => a - b);
}

function validateRow(row: Omit<ParsedSantriImportRow, "error">) {
  if (!row.name) return "Nama wajib diisi";
  if (!row.nis) return "NIS wajib diisi";
  if (!row.nis.replace(/\D/g, "")) return "NIS harus mengandung angka";
  if (row.email && !/\S+@\S+\.\S+/.test(row.email)) return "Format email tidak valid";
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
      nis: toText(getCellValue(source, "nis")),
      email: toText(getCellValue(source, "email")),
      gender: normalizeGender(toText(getCellValue(source, "gender"))),
      kelas: toText(getCellValue(source, "kelas")),
      halaqah: toText(getCellValue(source, "halaqah")),
      wali: toText(getCellValue(source, "wali")),
      hpWali: toText(getCellValue(source, "hpWali")),
      targetHafalan: toText(getCellValue(source, "targetHafalan")),
      tanggalLahir: normalizeDate(getCellValue(source, "tanggalLahir")),
      status: normalizeStatus(toText(getCellValue(source, "status"))),
      initialJuzList: parseInitialJuz(getCellValue(source, "initialJuzList")),
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
      "Nama",
      "NIS",
      "Email",
      "Jenis Kelamin",
      "Kelas",
      "Halaqah",
      "Nama Orang Tua / Wali",
      "No HP Wali",
      "Target Hafalan (Juz)",
      "Tanggal Lahir",
      "Status",
      "Hafalan Awal",
    ],
    [
      "Ahmad Fauzi",
      "TH-2026-001",
      "wali.ahmad@example.com",
      "L",
      "7A",
      "Halaqah Al-Ikhlas",
      "Bapak Fauzan",
      "081234567890",
      "30",
      "2012-05-10",
      "aktif",
      "1,2,3",
    ],
  ];

  const instructionRows = [
    ["Aturan Import Santri"],
    ["Field wajib: Nama, NIS"],
    ["Kolom lain boleh dikosongkan"],
    ["Jika nilai kelas/halaqah tidak cocok dengan data yang ada, sistem akan mengosongkannya"],
    ["Format tanggal lahir yang disarankan: YYYY-MM-DD"],
    ["Hafalan Awal diisi dengan angka juz, misal: 1,2,3"],
  ];

  const dataSheet = XLSX.utils.aoa_to_sheet(sheetRows);
  const instructionSheet = XLSX.utils.aoa_to_sheet(instructionRows);

  XLSX.utils.book_append_sheet(workbook, dataSheet, "Santri");
  XLSX.utils.book_append_sheet(workbook, instructionSheet, "Petunjuk");

  XLSX.writeFile(workbook, "template-import-santri.xlsx");
}