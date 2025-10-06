const slugify = (value: string): string => {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)+/g, "")
    .slice(0, 40);
};

export const generateHotelIdentifiers = (hotelName: string): { slug: string; code: string } => {
  const base = slugify(hotelName) || "hotel";
  const uniqueSuffix = Math.random().toString(36).slice(2, 6);
  const slug = `${base}-${uniqueSuffix}`;
  const code = slug.toUpperCase();
  return { slug, code };
};

export const codeToSlug = (code: string): string => {
  return code.trim().toLowerCase();
};
