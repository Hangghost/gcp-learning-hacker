# GSP096 - Pub/Sub: Qwik Start - Console

## Overview
Pub/Sub is a messaging service for exchanging event data among applications and services. A producer of data publishes messages to a Pub/Sub topic. A consumer creates a subscription to that topic. Subscribers either pull messages from a subscription or are configured as webhooks for push subscriptions. Every subscriber must acknowledge each message within a configurable window of time.

## Prerequisites
- Google Cloud Platform account
- Basic GCP knowledge
- Familiarity with Cloud Console

## Objectives
By the end of this lab, you will be able to:
- Set up a topic to hold data
- Subscribe to a topic to access the data
- Publish and then consume messages with a pull subscriber

## Estimated Time
30 minutes

## Lab Steps

### Task 1: Setting up Pub/Sub

To use Pub/Sub, you create a topic to hold data and a subscription to access data published to the topic.

1. From the **Navigation menu** () click **View All Products**. Go to **Analytics** section, click **Pub/Sub** > **Topics**.

2. Click **Create topic**.

3. The topic must have a unique name. For this lab, name your topic `MyTopic`. In the **Create a topic** dialog:
   - For **Topic ID**, type `MyTopic`.
   - Leave other fields at their default value.
   - Click **Create**.

You've created a topic.

### Task 2: Add a subscription

Now you'll make a subscription to access the topic.

1. Click **Topics** in the left panel to return to the **Topics** page. For the topic you just made click the three dot icon > **Create subscription**.

2. In the **Add subscription to topic** dialog:
   - Type a name for the subscription, such as `MySub`
   - Set the Delivery Type to **Pull**.
   - Leave all other options at the default values.

3. Click **Create**.

Your subscription is listed in the Subscription list.

### Task 3: Test your understanding

Below are multiple choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

A publisher application creates and sends messages to a ____. Subscriber applications create a ____ to a topic to receive messages from it.

Cloud Pub/Sub is an asynchronous messaging service designed to be highly reliable and scalable.

### Task 4: Publish a message to the topic

1. Navigate back to **pub/sub** > **Topics** and open **MyTopics** page.
2. In the Topics details page, click **Messages** tab and then click **Publish Message**.
3. Enter `Hello World` in the **Message** field and click **Publish**.

### Task 5: View the message

To view the message, use the subscription (`MySub`) to pull the message (`Hello World`) from the topic (`MyTopic`).

- Enter the following command in Cloud Shell:

```bash
gcloud pubsub subscriptions pull --auto-ack MySub
```

The message appears in the DATA field of the command output.

You created a Pub/Sub topic, published to the topic, created a subscription, then used the subscription to pull data from the topic.

## Verification

To verify that the lab was completed successfully:

1. Topic `MyTopic` is created in Pub/Sub
2. Subscription `MySub` is created and attached to the topic
3. Message "Hello World" was successfully published and consumed

## Troubleshooting

Common issues and their solutions:

- **Topic creation fails**: Ensure you have proper permissions and the topic name is unique
- **Subscription creation fails**: Verify the topic exists and you have access to create subscriptions
- **Message not received**: Check that the subscription is properly attached to the topic and try republishing the message

## Cleanup

To clean up resources and avoid charges:

1. In the Cloud Console, go to **Pub/Sub**
2. Delete the subscription `MySub`
3. Delete the topic `MyTopic`

## Additional Resources

- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Pub/Sub Quickstart](https://cloud.google.com/pubsub/docs/quickstart-console)
- Related labs: GSP096 (current lab)

## Notes

- Pub/Sub is a fully-managed real-time messaging service
- Topics hold messages, subscriptions allow consumers to access those messages
- Pull subscriptions require consumers to actively retrieve messages
- Push subscriptions automatically deliver messages to webhooks
