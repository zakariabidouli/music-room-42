// Prisma wiring: prod uses Postgres transactions; dev/test fall back to in-memory store.
// Never throws when DATABASE_URL is missing (keeps `npm test` green without a DB).
let client: any = null;
let attempted = false;

export async function getPrisma(): Promise<any | null> {
  if (attempted) return client;
  attempted = true;
  if (!process.env.DATABASE_URL) return null;
  try {
    const mod = await import('@prisma/client').catch(() => null);
    if (!mod) return null;
    client = new (mod as any).PrismaClient();
    await client.$connect().catch(() => {
      client = null;
    });
    return client;
  } catch {
    return null;
  }
}

export function getPrismaSync(): any | null {
  return client;
}
