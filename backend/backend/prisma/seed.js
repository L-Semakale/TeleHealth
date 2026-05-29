import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function main() {
  const password = await bcrypt.hash("password123", 12);

  const admin = await prisma.user.upsert({
    where: { phoneNumber: "+26650000099" },
    update: {},
    create: {
      fullName: "System Admin",
      phoneNumber: "+26650000099",
      hashedPassword: password,
      role: "admin",
      anonymousId: "anon-admin01"
    }
  });

  const provider = await prisma.user.upsert({
    where: { phoneNumber: "+26650000088" },
    update: {},
    create: {
      fullName: "Dr. Thabo Molefe",
      phoneNumber: "+26650000088",
      hashedPassword: password,
      role: "provider",
      anonymousId: "anon-prov0001"
    }
  });

  const patient = await prisma.user.upsert({
    where: { phoneNumber: "+26657712345" },
    update: {},
    create: {
      fullName: "Lineo Mokoena",
      phoneNumber: "+26657712345",
      hashedPassword: password,
      role: "patient",
      anonymousId: "anon-pat0001"
    }
  });

  const facilities = [
    {
      name: "Queen Mamohato Memorial Hospital",
      address: "Likotsi, Maseru",
      phone: "+26622315555",
      latitude: -29.3167,
      longitude: 27.4833
    },
    {
      name: "Maseru Private Hospital",
      address: "Kingsway Road, Maseru",
      phone: "+26622312345",
      latitude: -29.3167,
      longitude: 27.4833
    },
    {
      name: "City Health Center",
      address: "12 Main Road, Maseru",
      phone: "+266500001",
      latitude: -29.31,
      longitude: 27.48
    }
  ];

  for (const f of facilities) {
    const existing = await prisma.facility.findFirst({ where: { name: f.name } });
    if (!existing) {
      await prisma.facility.create({ data: f });
    }
  }

  console.log("Seed complete:");
  console.log(`  Admin:    ${admin.phoneNumber} / password123`);
  console.log(`  Provider: ${provider.phoneNumber} / password123`);
  console.log(`  Patient:  ${patient.phoneNumber} / password123`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
