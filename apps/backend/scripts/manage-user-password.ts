#!/usr/bin/env tsx

/**
 * MetaMCP User Password Management Script
 * 
 * Usage:
 *   tsx scripts/manage-user-password.ts <email> <new-password>
 *   tsx scripts/manage-user-password.ts --list-users
 */

import { drizzle } from 'drizzle-orm/postgres-js';
import { eq } from 'drizzle-orm';
import postgres from 'postgres';
import bcrypt from 'bcryptjs';
import * as schema from '../src/db/schema';

// Load environment variables
import dotenv from 'dotenv';
dotenv.config({ path: '../../.env' });

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('❌ DATABASE_URL environment variable is required');
  process.exit(1);
}

// Initialize database connection
const sql = postgres(DATABASE_URL);
const db = drizzle(sql, { schema });

async function listUsers() {
  try {
    const users = await db.select({
      id: schema.usersTable.id,
      email: schema.usersTable.email,
      name: schema.usersTable.name,
      createdAt: schema.usersTable.createdAt,
      emailVerified: schema.usersTable.emailVerified
    }).from(schema.usersTable);

    console.log('\n📋 MetaMCP Users:');
    console.log('================');
    
    if (users.length === 0) {
      console.log('No users found in the database.');
      return;
    }

    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name} (${user.email})`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Created: ${user.createdAt}`);
      console.log(`   Email Verified: ${user.emailVerified ? '✅' : '❌'}`);
      console.log('');
    });
  } catch (error) {
    console.error('❌ Error listing users:', (error as Error).message);
    process.exit(1);
  }
}

async function updateUserPassword(email: string, newPassword: string) {
  try {
    // Check if user exists
    const existingUser = await db.select()
      .from(schema.usersTable)
      .where(eq(schema.usersTable.email, email))
      .limit(1);

    if (existingUser.length === 0) {
      console.error(`❌ User with email '${email}' not found`);
      process.exit(1);
    }

    const user = existingUser[0];
    console.log(`👤 Found user: ${user.name} (${user.email})`);

    // Hash the new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update the password
    await db.update(schema.usersTable)
      .set({ 
        password: hashedPassword,
        updatedAt: new Date()
      })
      .where(eq(schema.usersTable.email, email));

    console.log(`✅ Password updated successfully for ${user.name} (${email})`);
    console.log('🔐 The user can now log in with their new password');

  } catch (error) {
    console.error('❌ Error updating password:', (error as Error).message);
    process.exit(1);
  }
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    console.log(`
🔐 MetaMCP User Password Management

Usage:
  mise run list-users
  mise run set-user-password -- <email> <new-password>
  mise run reset-user-password

Examples:
  # List all users
  mise run list-users

  # Update password for a user
  mise run set-user-password -- jaradd@gmail.com newpassword123

  # Interactive password reset
  mise run reset-user-password
`);
    process.exit(0);
  }

  if (args[0] === '--list-users' || args[0] === '--list') {
    await listUsers();
  } else if (args.length === 2) {
    const [email, newPassword] = args;
    
    if (newPassword.length < 8) {
      console.error('❌ Password must be at least 8 characters long');
      process.exit(1);
    }

    await updateUserPassword(email, newPassword);
  } else {
    console.error('❌ Invalid arguments. Use --help for usage information.');
    process.exit(1);
  }

  // Close database connection
  await sql.end();
}

main().catch((error) => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
