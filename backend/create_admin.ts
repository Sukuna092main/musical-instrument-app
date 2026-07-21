import { prisma } from './src/config/prisma';
import bcrypt from 'bcryptjs';

async function main() {
  try {
    const email = "jurgenslot2005@gmail.com";
    const password = "Admin@123456";
    const name = "Admin User";

    const existingAdmin = await prisma.users.findUnique({
      where: { email },
    });

    if (existingAdmin) {
      console.log(`Admin account ${email} already exists!`);
      return;
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const admin = await prisma.users.create({
      data: {
        email,
        password_hash: passwordHash,
        full_name: name,
        role: "admin",
        status: "active",
      },
    });

    console.log(`✅ Admin account created successfully!`);
    console.log(`Email: ${admin.email}`);
    console.log(`Password: ${password}`);
  } catch (err) {
    console.error("❌ Error creating admin:", err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
