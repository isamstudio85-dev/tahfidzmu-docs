import * as XLSX from "xlsx";

export type ParsedMusyrifImportRow = {
  rowNumber: number;
  name: string;
  nip: string;
  email: string;
  gender: string;
  jabatan: string;
  noHp: string;
  catatan: string;
  status: string;
  error: string | null;
};

type RawRow = Record<string, unknown>;

const headerAliases: Record<string, string[]> = {
  name: ["nama", "name", "nama lengkap", "nama_lengkap"],
  nip: ["nip", "no induk pegawai", "nomor induk pegawai"],
  email: ["email", "e-mail", "mail"],
  gender: ["jenis kelamin", "gender", "jk", "l/p"],
  jabatan: ["jabatan", "posisi"],
  noHp: ["no hp", "nomor hp", "hp", "wa", "whatsapp"],
  catatan: ["catatan", "keterangan", "note"],
  status: ["status"],
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

function validateRow(row: Omit<ParsedMusyrifImportRow, "error">) {
  if (!row.name) return "Nama wajib diisi";
  if (!row.nip) return "NIP wajib diisi";
  if (!row.nip.replace(/\D/g, "")) return "NIP harus mengandung angka";
  if (row.email && !/\S+@\S+\.\S+/.test(row.email)) return "Format email tidak valid";
  return null;
}

export async function parseMusyrifExcelFile(file: File) {
  const buffer = await file.arrayBuffer();
  const workbook = XLSX.read(buffer, { type: "array" });
  const firstSheetName = workbook.SheetNames[0];

  if (!firstSheetName) return [] as ParsedMusyrifImportRow[];

  const sheet = workbook.Sheets[firstSheetName];
  const rows = XLSX.utils.sheet_to_json<RawRow>(sheet, {
    raw: false,
    defval: "",
  });

  return rows.map((source, index) => {
    const normalizedRow = {
      rowNumber: index + 2,
      name: toText(getCellValue(source, "name")),
      nip: toText(getCellValue(source, "nip")),
      email: toText(getCellValue(source, "email")),
      gender: normalizeGender(toText(getCellValue(source, "gender"))),
      jabatan: toText(getCellValue(source, "jabatan")),
      noHp: toText(getCellValue(source, "noHp")),
      catatan: toText(getCellValue(source, "catatan")),
      status: normalizeStatus(toText(getCellValue(source, "status"))),
    };

    return {
      ...normalizedRow,
      error: validateRow(normalizedRow),
    };
  });
}

export function downloadMusyrifExcelTemplate() {
  const workbook = XLSX.utils.book_new();
  const rows = [
    ["Nama", "NIP", "Email", "Jenis Kelamin", "Jabatan", "No HP", "Catatan", "Status"],
    ["Musyrif Ahmad", "1987001", "ahmad@example.com", "L", "Musyrif", "081234567890", "Pembimbing halaqah 1", "aktif"],
  ];
  const notes = [
    ["Aturan Import Musyrif"],
    ["Field wajib: Nama dan NIP"],
    ["Email, jabatan, no HP, dan catatan boleh dikosongkan"],
    ["Sandi login otomatis akan mengikuti NIP jika tidak pernah diubah manual"],
  ];

  XLSX.utils.book_append_sheet(workbook, XLSX.utils.aoa_to_sheet(rows), "Musyrif");
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.aoa_to_sheet(notes), "Petunjuk");
  XLSX.writeFile(workbook, "template-import-musyrif.xlsx");
}