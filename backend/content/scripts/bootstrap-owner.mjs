import { PrismaClient } from '@prisma/client';

import { hashPassword } from '../src/admin/collaboration.js';

const databaseUrl =
  process.env.SDA_HYMNAL_DATABASE_URL ??
  process.env.SDA_HYMNAL_MIGRATION_DATABASE_URL;
const email = String(process.env.CONTENT_BOOTSTRAP_OWNER_EMAIL ?? '')
  .trim()
  .toLowerCase();
const password = process.env.CONTENT_BOOTSTRAP_OWNER_PASSWORD;
const displayName = String(
  process.env.CONTENT_BOOTSTRAP_OWNER_NAME ?? 'Wudase Owner',
).trim();

if (!databaseUrl) {
  throw new Error(
    'SDA_HYMNAL_DATABASE_URL or SDA_HYMNAL_MIGRATION_DATABASE_URL is required.',
  );
}
if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
  throw new Error('CONTENT_BOOTSTRAP_OWNER_EMAIL must be a valid email.');
}
if (displayName.length < 2 || displayName.length > 120) {
  throw new Error('CONTENT_BOOTSTRAP_OWNER_NAME must be 2 to 120 characters.');
}

const prisma = new PrismaClient({
  datasources: { db: { url: databaseUrl } },
});

try {
  const existingOwners = await prisma.contentUser.count({
    where: { role: 'owner', isActive: true },
  });
  if (existingOwners > 0) {
    throw new Error(
      'An active content owner already exists. Create additional accounts from Content Studio.',
    );
  }
  await prisma.contentUser.create({
    data: {
      email,
      displayName,
      role: 'owner',
      passwordHash: await hashPassword(password),
    },
  });
  console.log(`Created initial content owner ${email}.`);
} finally {
  await prisma.$disconnect();
}
