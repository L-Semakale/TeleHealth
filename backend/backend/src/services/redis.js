import Redis from "ioredis";

class MemoryRedis {
  constructor() {
    this.store = new Map();
    this.ttls = new Map();
  }

  async get(key) {
    this._expire(key);
    return this.store.get(key) ?? null;
  }

  async set(key, value, ...args) {
    this.store.set(key, value);
    if (args[0] === "EX" && args[1]) {
      this.ttls.set(key, Date.now() + args[1] * 1000);
    }
    return "OK";
  }

  async ping() {
    return "PONG";
  }

  async keys(pattern) {
    const prefix = pattern.replace("*", "");
    return [...this.store.keys()].filter((k) => k.startsWith(prefix));
  }

  async del(...keys) {
    keys.forEach((k) => {
      this.store.delete(k);
      this.ttls.delete(k);
    });
    return keys.length;
  }

  _expire(key) {
    const expires = this.ttls.get(key);
    if (expires && Date.now() > expires) {
      this.store.delete(key);
      this.ttls.delete(key);
    }
  }
}

const useMemory = process.env.REDIS_URL === "memory" || !process.env.REDIS_URL;

export const redis =
  useMemory
    ? new MemoryRedis()
    : new Redis(process.env.REDIS_URL, {
        maxRetriesPerRequest: 1,
        lazyConnect: true
      });

export const invalidateByPrefix = async (prefix) => {
  try {
    const keys = await redis.keys(`${prefix}*`);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  } catch {
    // ignore cache invalidation errors in local dev
  }
};
