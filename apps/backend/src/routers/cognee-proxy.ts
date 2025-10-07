import { randomUUID } from "node:crypto";

import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import express from "express";

import {
  ApiKeyAuthenticatedRequest,
  authenticateApiKey,
} from "@/middleware/api-key-oauth.middleware";
import { lookupEndpoint } from "@/middleware/lookup-endpoint-middleware";

import { metaMcpServerPool } from "../lib/metamcp/metamcp-server-pool";

const cogneeProxyRouter = express.Router();

const transports: Record<string, StreamableHTTPServerTransport> = {}; // Cognee transports by sessionId

// Cleanup function for a specific Cognee session
const cleanupCogneeSession = async (sessionId: string) => {
  console.log(`[Cognee] Cleaning up session ${sessionId}`);

  try {
    // Clean up transport
    const transport = transports[sessionId];
    if (transport) {
      console.log(`[Cognee] Closing transport for session ${sessionId}`);
      await transport.close();
      delete transports[sessionId];
      console.log(`[Cognee] Transport cleaned up for session ${sessionId}`);
    } else {
      console.log(`[Cognee] No transport found for session ${sessionId}`);
    }

    // Clean up MetaMCP server pool session
    await metaMcpServerPool.cleanupSession(sessionId);

    console.log(`[Cognee] Session ${sessionId} cleanup completed`);
  } catch (error) {
    console.error(`[Cognee] Error during cleanup of session ${sessionId}:`, error);
    // Remove orphaned transport to prevent memory leaks
    if (transports[sessionId]) {
      delete transports[sessionId];
      console.log(
        `[Cognee] Removed orphaned transport for session ${sessionId} due to cleanup error`,
      );
    }
    throw error;
  }
};

// Health check endpoint to monitor Cognee sessions
cogneeProxyRouter.get("/health/sessions", (req, res) => {
  const sessionIds = Object.keys(transports);
  const poolStatus = metaMcpServerPool.getPoolStatus();

  res.json({
    service: "cognee-mcp",
    timestamp: new Date().toISOString(),
    cogneeSessions: {
      count: sessionIds.length,
      sessionIds: sessionIds,
    },
    metaMcpPoolStatus: poolStatus,
    totalActiveSessions: sessionIds.length + poolStatus.active,
  });
});

// GET endpoint - retrieve existing session
cogneeProxyRouter.get(
  "/:endpoint_name/mcp",
  lookupEndpoint,
  authenticateApiKey,
  async (req, res) => {
    const sessionId = req.headers["mcp-session-id"] as string;

    try {
      console.log(`[Cognee] Looking up existing session: ${sessionId}`);
      console.log(`[Cognee] Available sessions:`, Object.keys(transports));

      const transport = transports[sessionId];
      if (!transport) {
        console.log(`[Cognee] Session ${sessionId} not found in transports`);
        res.status(404).json({
          error: "Session not found",
          message: `Cognee session ${sessionId} does not exist`,
          available_sessions: Object.keys(transports),
        });
        return;
      }

      console.log(`[Cognee] Found session ${sessionId}, handling request`);
      await transport.handleRequest(req, res);
    } catch (error) {
      console.error("[Cognee] Error in GET /mcp route:", error);
      res.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
        service: "cognee-mcp",
      });
    }
  },
);

// POST endpoint - create new session or reuse existing
cogneeProxyRouter.post(
  "/:endpoint_name/mcp",
  lookupEndpoint,
  authenticateApiKey,
  async (req, res) => {
    const authReq = req as ApiKeyAuthenticatedRequest;
    const { namespaceUuid, endpointName } = authReq;
    const sessionId = req.headers["mcp-session-id"] as string | undefined;

    console.log(`[Cognee] POST /mcp request for endpoint: ${endpointName}`);
    console.log(`[Cognee] Authentication method: ${authReq.authMethod || "none"}`);
    console.log(`[Cognee] Session ID: ${sessionId || "new session"}`);

    if (!sessionId) {
      try {
        console.log(
          `[Cognee] New StreamableHttp connection request for ${endpointName} -> namespace ${namespaceUuid}`,
        );

        // Generate session ID upfront
        const newSessionId = randomUUID();
        console.log(
          `[Cognee] Generated new session ID: ${newSessionId} for endpoint: ${endpointName}`,
        );

        // Get or create MetaMCP server instance from the pool
        // NOTE: This will need to be configured to point to Cognee container
        const mcpServerInstance = await metaMcpServerPool.getServer(
          newSessionId,
          namespaceUuid,
          {
            serverName: "cognee-mcp", // Custom server identifier
            serverUrl: "http://cognee-mcp:8000/mcp", // Internal Docker network URL
          },
        );

        if (!mcpServerInstance) {
          throw new Error("Failed to get Cognee MCP server instance from pool");
        }

        console.log(
          `[Cognee] Using MCP server instance for session ${newSessionId} (endpoint: ${endpointName})`,
        );

        // Create transport with the predetermined session ID
        const transport = new StreamableHTTPServerTransport({
          sessionIdGenerator: () => newSessionId,
          onsessioninitialized: async (sessionId) => {
            try {
              console.log(`[Cognee] Session initialized for sessionId: ${sessionId}`);
            } catch (error) {
              console.error(
                `[Cognee] Error initializing session ${sessionId}:`,
                error,
              );
            }
          },
        });

        console.log("[Cognee] Created StreamableHttp transport");
        console.log(
          `[Cognee] Session ${newSessionId} will be cleaned up via DELETE request`,
        );

        // Store transport reference
        transports[newSessionId] = transport;

        console.log(
          `[Cognee] Client <-> Proxy sessionId: ${newSessionId} for endpoint ${endpointName} -> namespace ${namespaceUuid}`,
        );
        console.log(`[Cognee] Stored transport for sessionId: ${newSessionId}`);
        console.log(`[Cognee] Total active sessions: ${Object.keys(transports).length}`);

        // Connect the server to the transport before handling the request
        await mcpServerInstance.server.connect(transport);

        // Handle the request - server is ready
        await transport.handleRequest(req, res);
      } catch (error) {
        console.error("[Cognee] Error in POST /mcp route:", error);

        const errorMessage =
          error instanceof Error ? error.message : "Unknown error";
        res.status(500).json({
          error: "Internal server error",
          message: errorMessage,
          endpoint: endpointName,
          service: "cognee-mcp",
          timestamp: new Date().toISOString(),
        });
      }
    } else {
      // Reuse existing session
      console.log(`[Cognee] Available session IDs:`, Object.keys(transports));
      console.log(`[Cognee] Looking for sessionId: ${sessionId}`);

      try {
        const transport = transports[sessionId];
        if (!transport) {
          console.error(
            `[Cognee] Transport not found for sessionId ${sessionId}. Available:`,
            Object.keys(transports),
          );
          res.status(404).json({
            error: "Session not found",
            message: `Transport not found for sessionId ${sessionId}`,
            available_sessions: Object.keys(transports),
            service: "cognee-mcp",
            timestamp: new Date().toISOString(),
          });
        } else {
          console.log(`[Cognee] Found session ${sessionId}, handling request`);
          await transport.handleRequest(req, res);
        }
      } catch (error) {
        console.error("[Cognee] Error in POST /mcp route:", error);

        const errorMessage =
          error instanceof Error ? error.message : "Unknown error";
        res.status(500).json({
          error: "Internal server error",
          message: errorMessage,
          session_id: sessionId,
          endpoint: endpointName,
          service: "cognee-mcp",
          timestamp: new Date().toISOString(),
        });
      }
    }
  },
);

// DELETE endpoint - cleanup session
cogneeProxyRouter.delete(
  "/:endpoint_name/mcp",
  lookupEndpoint,
  authenticateApiKey,
  async (req, res) => {
    const authReq = req as ApiKeyAuthenticatedRequest;
    const { namespaceUuid, endpointName } = authReq;
    const sessionId = req.headers["mcp-session-id"] as string | undefined;

    console.log(
      `[Cognee] Received DELETE message for endpoint ${endpointName} -> namespace ${namespaceUuid} sessionId ${sessionId}`,
    );

    if (sessionId) {
      try {
        console.log(`[Cognee] Starting cleanup for session ${sessionId}`);
        console.log(
          `[Cognee] Available sessions before cleanup:`,
          Object.keys(transports),
        );

        await cleanupCogneeSession(sessionId);

        console.log(`[Cognee] Session ${sessionId} cleaned up successfully`);
        console.log(
          `[Cognee] Available sessions after cleanup:`,
          Object.keys(transports),
        );

        res.status(200).json({
          message: "Cognee session cleaned up successfully",
          sessionId: sessionId,
          remainingSessions: Object.keys(transports),
          service: "cognee-mcp",
        });
      } catch (error) {
        console.error("[Cognee] Error in DELETE /mcp route:", error);
        res.status(500).json({
          error: "Cleanup failed",
          message: error instanceof Error ? error.message : "Unknown error",
          sessionId: sessionId,
          service: "cognee-mcp",
        });
      }
    } else {
      res.status(400).json({
        error: "Missing sessionId",
        message: "sessionId header is required for cleanup",
        service: "cognee-mcp",
      });
    }
  },
);

export default cogneeProxyRouter;
