import ConnectedUser from "./ConnectedUser";

class PubSubBroker {
  private topics: Map<string, Set<ConnectedUser>> = new Map();

  subscribe(topic: string, user: ConnectedUser) {
    if (!this.topics.has(topic)) {
      this.topics.set(topic, new Set());
    }
    this.topics.get(topic)!.add(user);
  }

  unsubscribe(topic: string, user: ConnectedUser) {
    if (this.topics.has(topic)) {
      this.topics.get(topic)!.delete(user);
    }
  }

  publish(topic: string, data: any) {
    const subscribers = this.topics.get(topic);
    if (subscribers) {
      subscribers.forEach((subscriber) => subscriber.receiveUpdate(data));
    }
  }
}

export default PubSubBroker;
