import express from "express";

import { auth } from "./auth";
import { initializeIdleServers } from "./lib/startup";
import mcpProxyRouter from "./routers/mcp-proxy";
import publicEndpointsRouter from "./routers/public-metamcp";
import trpcRouter from "./routers/trpc";

const app = express();

// Global JSON middleware for non-proxy routes
app.use((req, res, next) => {
  if (req.path.startsWith("/mcp-proxy/") || req.path.startsWith("/metamcp/")) {
    // Skip JSON parsing for all MCP proxy routes and public endpoints to allow raw stream access
    next();
  } else {
    express.json()(req, res, next);
  }
});

// Mount better-auth routes by calling auth API directly
app.use("/api/auth", express.json(), async (req, res) => {
  try {
    // Create a web Request object from Express request
    // Need to reconstruct the full URL including /api/auth prefix
    const fullPath = `/api/auth${req.url}`;
    const url = new URL(fullPath, `http://${req.headers.host}`);
    
    const headers = new Headers();

    // Copy headers from Express request
    Object.entries(req.headers).forEach(([key, value]) => {
      if (value) {
        headers.set(key, Array.isArray(value) ? value[0] : value);
      }
    });

    // Create Request object with proper body handling
    let body: string | undefined = undefined;
    if (req.method !== "GET" && req.method !== "HEAD") {
      if (req.body && typeof req.body === 'object') {
        body = JSON.stringify(req.body);
      } else if (typeof req.body === 'string') {
        body = req.body;
      }
    }

    const request = new Request(url.toString(), {
      method: req.method,
      headers,
      body,
    });

    // Call better-auth directly
    const response = await auth.handler(request);

    // Convert Response back to Express response
    res.status(response.status);

    // Copy headers
    response.headers.forEach((value, key) => {
      res.setHeader(key, value);
    });

    // Send body
    const responseBody = await response.text();
    res.send(responseBody);
  } catch (error) {
    console.error("Auth route error:", error);
    res.status(500).json({
      error: "Internal server error",
      details: error instanceof Error ? error.message : String(error),
    });
  }
});

// Mount public endpoints routes (must be before JSON middleware to handle raw streams)
app.use("/metamcp", publicEndpointsRouter);

// Mount MCP proxy routes
app.use("/mcp-proxy", mcpProxyRouter);

// Mount tRPC routes
app.use("/trpc", trpcRouter);

app.listen(12009, async () => {
  console.log(`Server is running on port 12009`);
  console.log(`Auth routes available at: http://localhost:12009/api/auth`);
  console.log(
    `Public MetaMCP endpoints available at: http://localhost:12009/metamcp`,
  );
  console.log(
    `MCP Proxy routes available at: http://localhost:12009/mcp-proxy`,
  );
  console.log(`tRPC routes available at: http://localhost:12009/trpc`);

  // Initialize idle servers after server starts
  await initializeIdleServers();
});

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
  });
});
