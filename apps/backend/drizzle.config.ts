import { defineConfig } from "drizzle-kit";

// Remove any http:// from the URL and ensure proper format
function getDatabaseUrl() {
  const url = process.env.POSTGRES_URL?.replace('http://', '') || '';
  return `${url}/metamcp`;
}

export default defineConfig({
  out: "./drizzle",
  schema: "./src/db/schema.ts",
  dialect: "postgresql",
  dbCredentials: {
    url: getDatabaseUrl(),
  },
});
