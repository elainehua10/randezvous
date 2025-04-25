import { createClient, RedisClientType } from "redis";

export const createRedisConnection: () => RedisClientType = () => {
  const client = createClient({
    username: "default",
    password: process.env.REDIS_PASSWORD,
    socket: {
      host: process.env.REDIS_HOST,
      port: 14406,
    },
  });

  (async () => {
    client.on("error", (err) => console.log("Redis Client Error", err));
    await client.connect();
    console.log("Connected to Redis");
  })();

  return client as RedisClientType;
};
