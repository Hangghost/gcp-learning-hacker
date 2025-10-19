# GSP095 - Pub/Sub: Qwik Start - Command Line

## Lab Overview

Pub/Sub is a messaging service for exchanging event data among applications and services. By decoupling senders and receivers, it allows for secure and highly available communication between independently written applications. Pub/Sub delivers low-latency/durable messaging, and is commonly used by developers in implementing asynchronous workflows, distributing event notifications, and streaming data from various processes or devices.

## Learning Objectives

In this lab, you will learn how to:

- Create, delete, and list Pub/Sub topics and subscriptions
- Publish messages to a topic
- Use a pull subscriber

## Prerequisites

This is an **introductory** level lab. This assumes little or no prior experience with Pub/Sub, and it will teach you the basics of setting up and using this Google Cloud service.

## Estimated Time

Approximately 30 minutes

## Lab Steps

### Task 1: Pub/Sub topics

Pub/Sub comes preinstalled in Cloud Shell, so there are no installations or configurations required to get started with this service.

1. Run the following command to create a topic called `myTopic`:

```bash
gcloud pubsub topics create myTopic
```

**Test completed task**

Click **Check my progress** to verify your performed task. If you have completed the task successfully you will be granted an assessment score.

Create a Pub/Sub topic.

2. For good measure, create two more topics; one called `Test1` and the other called `Test2`:

```bash
gcloud pubsub topics create Test1
gcloud pubsub topics create Test2
```

3. To see the three topics you just created, run the following command:

```bash
gcloud pubsub topics list
```

Your output should resemble the following:

```
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/myTopic
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/Test1
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/Test2
```

4. Time to clean up. Delete `Test1` and `Test2` by running the following commands:

```bash
gcloud pubsub topics delete Test1
gcloud pubsub topics delete Test2
```

5. Run the `gcloud pubsub topics list` command one more time to verify the topics were deleted:

```bash
gcloud pubsub topics list
```

You should get the following output:

```
---
name: projects/qwiklabs-gcp-3450558d2b043890/topics/myTopic
```

### Task 2: Pub/Sub subscriptions

Now that you're comfortable creating, viewing, and deleting topics, time to work with subscriptions.

1. Run the following command to create a subscription called `mySubscription` to topic `myTopic`:

```bash
gcloud pubsub subscriptions create --topic myTopic mySubscription
```

**Test completed task**

Click **Check my progress** to verify your performed task. If you have completed the task successfully you will be granted an assessment score.

Create Pub/Sub Subscription.

2. Add another two subscriptions to `myTopic`. Run the following commands to make `Test1` and `Test2` subscriptions:

```bash
gcloud pubsub subscriptions create --topic myTopic Test1
gcloud pubsub subscriptions create --topic myTopic Test2
```

3. Run the following command to list the subscriptions to myTopic:

```bash
gcloud pubsub topics list-subscriptions myTopic
```

Your output should resemble the following:

```
-- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/Test2
--- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/Test1
--- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/mySubscription
```

**Test your understanding**

Below are multiple choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

To receive messages published to a topic, you must create a subscription to that topic. True/False

4. Now delete the `Test1` and `Test2` subscriptions. Run the following commands:

```bash
gcloud pubsub subscriptions delete Test1
gcloud pubsub subscriptions delete Test2
```

5. See if the `Test1` and `Test2` subscriptions were deleted. Run the `list-subscriptions` command one more time:

```bash
gcloud pubsub topics list-subscriptions myTopic
```

You should get the following output:

```
-- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/mySubscription
```

### Task 3: Pub/Sub publishing and pulling a single message

Next you'll learn how to publish a message to a Pub/Sub topic.

1. Run the following command to publish the message `"Hello"` to the topic you created previously (`myTopic`):

```bash
gcloud pubsub topics publish myTopic --message "Hello"
```

2. Publish a few more messages to `myTopic`. Run the following commands (replacing `<YOUR NAME>` with your name and `<FOOD>` with a food you like to eat):

```bash
gcloud pubsub topics publish myTopic --message "Publisher's name is <YOUR NAME>"
gcloud pubsub topics publish myTopic --message "Publisher likes to eat <FOOD>"
gcloud pubsub topics publish myTopic --message "Publisher thinks Pub/Sub is awesome"
```

Next, use the `pull` command to get the messages from your topic. The pull command is subscription based, meaning it should work because earlier you set up the subscription `mySubscription` to the topic `myTopic`.

3. Use the following command to pull the messages you just published from the Pub/Sub topic:

```bash
gcloud pubsub subscriptions pull mySubscription --auto-ack
```

Your output should resemble the following:

```
Data: Publisher likes to eat <FOOD>
Message ID: 123456789012345
Attributes:
```

What's going on here? You published 4 messages to your topic, but only 1 was outputted.

Now is an important time to mention a couple features of the `pull` command that often trip developers up:

- **Using the pull command without any flags will output only one message, even if you are subscribed to a topic that has more held in it.**
- **Once an individual message has been outputted from a particular subscription-based pull command, you cannot access that message again with the pull command.**

4. To see what the second bullet is talking about, run the last command three more times. You will see that it will output the other messages you published before.
5. Now, run the command a 4th time. You'll get the following output (since there were none left to return):

```bash
Listed 0 items.
```

In the last section, you will learn how to pull multiple messages from a topic with a `flag`.

### Task 4: Pub/Sub pulling all messages from subscriptions

Since you pulled all of the messages from your topic in the last example, populate `myTopic` with a few more messages.

1. Run the following commands:

```bash
gcloud pubsub topics publish myTopic --message "Publisher is starting to get the hang of Pub/Sub"
gcloud pubsub topics publish myTopic --message "Publisher wonders if all messages will be pulled"
gcloud pubsub topics publish myTopic --message "Publisher will have to test to find out"
```

2. Add a `flag` to your command so you can output all three messages in one request.

You may have not noticed, but you have actually been using a flag this entire time: the `--auto-ack` part of the `pull` command is a flag that has been formatting your messages into the neat boxes that you see your pulled messages in.

`limit` is another flag that sets an upper limit on the number of messages to pull.

3. Wait a minute to let the topics get created. Run the pull command with the `limit` flag:

```bash
gcloud pubsub subscriptions pull mySubscription --limit=3
```

Your output should match the following:

```
Data: Publisher is starting to get the hang of Pub/Sub
Message ID: 123456789012345
Attributes:
---
Data: Publisher wonders if all messages will be pulled
Message ID: 123456789012346
Attributes:
---
Data: Publisher will have to test to find out
Message ID: 123456789012347
Attributes:
```

Now you know how to add flags to a Pub/Sub command to output a larger pool of messages. You are well on your way to becoming a Pub/Sub master.

## Verification

To verify that the lab was completed successfully:

1. Ensure all topics and subscriptions were created and deleted correctly
2. Confirm that message publishing and pulling works properly
3. Verify that the `--limit` flag correctly pulls multiple messages

## Troubleshooting

Common issues and their solutions:

- **Permission errors**: Ensure you have sufficient Pub/Sub permissions
- **Topic doesn't exist**: Create the topic before creating subscriptions
- **Message pull fails**: Check that subscriptions are correctly bound to topics
- **Command syntax errors**: Double-check gcloud command parameters and flags

## Cleanup

To avoid charges, clean up resources:

1. Delete all test topics:

```bash
gcloud pubsub topics delete myTopic
```

2. Verify cleanup:

```bash
gcloud pubsub topics list
gcloud pubsub subscriptions list
```

## Additional Resources

- [Pub/Sub Official Documentation](https://cloud.google.com/pubsub/docs)
- [Pub/Sub Architecture](https://cloud.google.com/pubsub/docs/overview)
- [Pub/Sub Quickstart](https://cloud.google.com/pubsub/docs/quickstart)
- Related lab: GSP096 - Pub/Sub: Qwik Start - Console

## Notes

Pub/Sub is a powerful messaging service in Google Cloud, ideal for decoupling application components and handling event-driven architectures. Mastering the basics of topics, subscriptions, and message handling is the foundation for further learning.
