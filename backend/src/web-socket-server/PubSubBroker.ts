import { RedisClientType } from "redis";
import ConnectedUser from "./ConnectedUser";
import { createRedisConnection } from "./redis";

class PubSubBroker {
  private topics: Map<string, Set<ConnectedUser>> = new Map();
  private publisher: RedisClientType;
  private subscriber: RedisClientType;

  private static instance: PubSubBroker;

  private constructor() {
    // TODO
    this.publisher = createRedisConnection();
    this.subscriber = createRedisConnection();
  }

  public static getInstance(): PubSubBroker {
    if (!PubSubBroker.instance) {
      PubSubBroker.instance = new PubSubBroker();
    }
    return PubSubBroker.instance;
  }

  subscribe(topic: string, user: ConnectedUser) {
    if (!this.topics.has(topic)) {
      this.topics.set(topic, new Set());

      console.log(`Subscribing to topic: ${topic}`);

      this.subscriber.subscribe(`${topic}`, (message) => {
        const data = JSON.parse(message);
        const subscribers = this.topics.get(topic);
        if (subscribers) {
          for (const subUser of subscribers) {
            subUser.receiveUpdate(data);
          }
        }
      });
    }
    const subscribers = this.topics.get(topic);
    if (subscribers) {
      subscribers.add(user);
    }
  }

  unsubscribe(topic: string, user: ConnectedUser) {
    const subscribers = this.topics.get(topic);
    if (subscribers) {
      subscribers.delete(user);
      if (subscribers.size === 0) {
        this.topics.delete(topic);
        this.subscriber.unsubscribe(`${topic}`);
      }
    }
  }

  publish(topic: string, data: any) {
    // console.log(FormDataEvent);
    this.publisher.publish(`${topic}`, JSON.stringify(data));
  }
}

export default PubSubBroker;
