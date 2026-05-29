import Redis from "ioredis";

export const redis = new Redis(process.env.REDIS_URL);

export const invalidateByPrefix = async (prefix) => {
  const keys = await redis.keys(`${prefix}*`);
  if (keys.length > 0) {
    await redis.del(keys);
  }
};
