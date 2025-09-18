export interface MetaMcpLogEntry {
  id: string;
  timestamp: Date;
  serverName: string;
  level: "error" | "info" | "warn";
  message: string;
  error?: string;
}

class MetaMcpLogStore {
  private logs: MetaMcpLogEntry[] = [];
  private readonly maxLogs = 200; // Reduced from 1000 to prevent memory buildup
  private readonly listeners: Set<(log: MetaMcpLogEntry) => void> = new Set();
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    // Start cleanup interval to prevent memory leaks
    this.cleanupInterval = setInterval(() => {
      this.performCleanup();
    }, 60000); // Clean up every minute
  }

  private performCleanup() {
    // More aggressive cleanup - keep only half the max logs
    if (this.logs.length > this.maxLogs / 2) {
      this.logs = this.logs.slice(-(this.maxLogs / 2));
    }
  }

  addLog(
    serverName: string,
    level: MetaMcpLogEntry["level"],
    message: string,
    error?: unknown,
  ) {
    // Skip repetitive error messages to prevent spam
    if (level === "error" && this.isRepetitiveError(message)) {
      return;
    }

    const logEntry: MetaMcpLogEntry = {
      id: crypto.randomUUID(),
      timestamp: new Date(),
      serverName,
      level,
      message,
      error: error
        ? error instanceof Error
          ? error.message
          : String(error)
        : undefined,
    };

    // Add to logs array
    this.logs.push(logEntry);

    // Keep only the last maxLogs entries
    if (this.logs.length > this.maxLogs) {
      this.logs = this.logs.slice(-this.maxLogs);
    }

    // Only log errors and warnings to console to reduce noise
    const fullMessage = `[MetaMCP][${serverName}] ${message}`;
    switch (level) {
      case "error":
        console.error(fullMessage, error || "");
        break;
      case "warn":
        console.warn(fullMessage, error || "");
        break;
      case "info":
        // Skip info logs to reduce console spam
        break;
    }

    // Notify listeners
    this.listeners.forEach((listener) => {
      try {
        listener(logEntry);
      } catch (err) {
        console.error("Error notifying log listener:", err);
      }
    });
  }

  private isRepetitiveError(message: string): boolean {
    // Check if we've seen this error message recently
    const recentLogs = this.logs.slice(-10);
    const similarCount = recentLogs.filter(log =>
      log.level === "error" && log.message === message
    ).length;
    return similarCount >= 3; // Skip if we've seen this error 3+ times recently
  }

  getLogs(limit?: number): MetaMcpLogEntry[] {
    const logsToReturn = limit ? this.logs.slice(-limit) : this.logs;
    return [...logsToReturn].reverse(); // Return newest first
  }

  clearLogs(): void {
    this.logs = [];
  }

  addListener(listener: (log: MetaMcpLogEntry) => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  getLogCount(): number {
    return this.logs.length;
  }

  destroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    this.logs = [];
    this.listeners.clear();
  }
}

// Singleton instance
export const metamcpLogStore = new MetaMcpLogStore();
