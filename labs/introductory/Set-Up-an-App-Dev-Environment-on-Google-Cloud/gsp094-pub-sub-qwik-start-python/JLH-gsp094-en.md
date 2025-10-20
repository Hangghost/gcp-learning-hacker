# GSP094 - Pub/Sub: Qwik Start - Python

## Lab Overview

The Pub/Sub service allows applications to exchange messages reliably, quickly, and asynchronously. To accomplish this, a data producer publishes messages to a Cloud Pub/Sub topic. A subscriber client then creates a subscription to that topic and consumes messages from the subscription. Cloud Pub/Sub persists messages that could not be delivered reliably for up to seven days.

In this lab, you will learn how to get started publishing messages with Pub/Sub using the Python client library.

## Learning Objectives

By the end of this lab, you will be able to:
- Learn the basics of Pub/Sub
- Create, delete, and list Pub/Sub topics and subscriptions using Python
- Publish messages to a topic
- Use a pull subscriber to output individual topic messages

## Estimated Time

45 minutes

## Prerequisites

- Google Cloud Platform account
- Basic command line knowledge
- Python fundamentals

## Lab Steps

### Task 1: Create a virtual environment

Python virtual environments are used to isolate package installation from the system.

1. Install the `virtualenv` environment:

```bash
sudo apt-get install -y virtualenv
```

2. Build the virtual environment:

```bash
python3 -m venv venv
```

3. Activate the virtual environment:

```bash
source venv/bin/activate
```

### Task 2: Install the client library

1. Run the following to install the client library:

```bash
pip install --upgrade google-cloud-pubsub
```

2. Get the sample code by cloning a GitHub repository:

```bash
git clone https://github.com/googleapis/python-pubsub.git
```

3. Navigate to the directory:

```bash
cd python-pubsub/samples/snippets
```

### Task 3: Pub/Sub - the Basics

Pub/Sub is an asynchronous global messaging service. There are three terms in Pub/Sub that appear often: *topics*, *publishing*, and *subscribing*.

A topic is a shared string that allows applications to connect with one another through a common thread.

Publishers push (or publish) a message to a Pub/Sub topic. Subscribers will then make a *subscription* to that thread, where they will either pull messages from the topic or configure webhooks for push subscriptions. Every subscriber must acknowledge each message within a configurable window of time.

In sum, a publisher creates and sends messages to a topic and a subscriber creates a subscription to a topic to receive messages from it.

### Pub/Sub in Google Cloud

Pub/Sub comes preinstalled in Cloud Shell, so there are no installations or configurations required to get started with this service. In this lab you use Python to create the topic, subscriber, and then view the message. You use a gcloud command to publish the message to the topic.

### Task 4: Create a topic

To publish data to Pub/Sub you create a topic and then configure a publisher to the topic.

1. In Cloud Shell, your Project ID should automatically be stored in the environment variable `GOOGLE_CLOUD_PROJECT`:

```bash
echo $GOOGLE_CLOUD_PROJECT
```

The output should be the same as the Project ID in your CONNECTION DETAILS.

2. View the content of publisher script:

```bash
cat publisher.py
```

**Note:** Alternatively, you can use the shell editors that are installed on Cloud Shell, such as nano or vim or use the Cloud Shell code editor to view `python-pubsub/samples/snippets/publisher.py`.

3. For information about the publisher script:

```bash
python publisher.py -h
```

4. Run the publisher script to create Pub/Sub Topic:

```bash
python publisher.py $GOOGLE_CLOUD_PROJECT create MyTopic
```

**Expected output:**

```
Topic created: name: "projects/qwiklabs-gcp-fe27729bc161fb22/topics/MyTopic"
```

**Check my progress**

Click **Check my progress** to verify your performed task. If you have successfully created a Cloud Pub/Sub topic, you will see an assessment score.

Create a topic.

5. This command returns a list of all Pub/Sub topics in a given project:

```bash
python publisher.py $GOOGLE_CLOUD_PROJECT list
```

**Expected output:**

```
name: "projects/qwiklabs-gcp-fe27729bc161fb22/topics/MyTopic"
```

You can also view the topic you just made in the Cloud Console.

6. Navigate to **Navigation menu** > **Pub/Sub** > **Topics**.

You should see `MyTopic`.

### Task 5: Create a subscription

1. Create a Pub/Sub subscription for topic with `subscriber.py` script:

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT create MyTopic MySub
```

**Check my progress**

Click **Check my progress** to verify your performed task. If you have successfully created a Cloud Pub/Sub subscription, you will see an assessment score.

Create a subscription.

2. This command returns a list of subscribers in given project:

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT list-in-project
```

You'll see only one subscription because you've made only one subscription.

**Expected output:**

```
projects/qwiklabs-gcp-7877af129f04d8b3/subscriptions/MySub
```

3. Check out the subscription you just made in the console. In the left pane, click **Subscriptions**. You should see the subscription name and other details.

4. For information about the `subscriber` script:

```bash
python subscriber.py -h
```

### Task 6: Publish messages

Now that you've set up `MyTopic` (the topic) and a subscription to `MyTopic` (`MySub`), use `gcloud` commands to publish a message to `MyTopic`.

1. Publish the message "Hello" to `MyTopic`:

```bash
gcloud pubsub topics publish MyTopic --message "Hello"
```

2. Publish a few more messages to `MyTopic`—run the following commands (replacing <YOUR NAME> with your name and <FOOD> with a food you like to eat):

```bash
gcloud pubsub topics publish MyTopic --message "Publisher's name is <YOUR NAME>"
gcloud pubsub topics publish MyTopic --message "Publisher likes to eat <FOOD>"
gcloud pubsub topics publish MyTopic --message "Publisher thinks Pub/Sub is awesome"
```

### Task 7: View messages

Now that you've published messages to MyTopic, pull and view the messages using MySub.

1. Use MySub to pull the message from MyTopic:

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT receive MySub
```

**Expected output:**

```
Listening for messages on projects/qwiklabs-gcp-7877af129f04d8b3/subscriptions/MySub
Received message: Message {
  data: 'Publisher thinks Pub/Sub is awesome'
  attributes: {}
}
Received message: Message {
  data: 'Hello'
  attributes: {}
}
Received message: Message {
  data: "Publisher's name is Harry"
  attributes: {}
}
Received message: Message {
  data: 'Publisher likes to eat cheese'
  attributes: {}
}
```

2. Click **Ctrl**+**c** to stop listening.

### Task 8: Test your understanding

Below are multiple-choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

Google Cloud Pub/Sub service allows applications to exchange messages reliably, quickly, and asynchronously.

- [x] True
- [ ] False

A _____ is a shared string that allows applications to connect with one another through a common thread.

- [ ] subscription
- [x] topic
- [ ] message

## Verification

To verify that the lab was completed successfully:

1. Confirm you have successfully created topic `MyTopic`
2. Confirm you have successfully created subscription `MySub`
3. Confirm you can publish messages to the topic
4. Confirm you can receive messages from the subscription

## Troubleshooting

### Common Issues

- **Virtual environment activation failed**: Ensure using `python3 -m venv venv` instead of `virtualenv venv`
- **Pip install failed**: Ensure virtual environment is activated (prompt should show `(venv)`)
- **Topic creation failed**: Check that project ID is set correctly
- **Message publish failed**: Ensure topic name is spelled correctly
- **Cannot receive messages**: Ensure subscription is properly connected to topic

### Error Messages and Solutions

- **"Topic already exists"**: Use a different topic name or delete existing topic first
- **"Subscription already exists"**: Use a different subscription name or delete existing subscription first
- **"Permission denied"**: Ensure you have sufficient IAM permissions

## Cleanup

To avoid incurring charges, clean up the resources using these steps:

1. Delete the subscription:
```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT delete MyTopic MySub
```

2. Delete the topic:
```bash
python publisher.py $GOOGLE_CLOUD_PROJECT delete MyTopic
```

3. Exit the virtual environment:
```bash
deactivate
```

4. Remove the virtual environment (optional):
```bash
rm -rf venv
```

## Additional Resources

- [Pub/Sub Official Documentation](https://cloud.google.com/pubsub/docs)
- [Pub/Sub Python Client Library](https://googleapis.dev/python/pubsub/latest/index.html)
- [Pub/Sub Lite: Alternative messaging service](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-lite)

## Next Steps

Congratulations! You used Python to create a Pub/Sub topic, published to the topic, created a subscription, then used the subscription to pull data from the topic.

Complementing Pub/Sub, [Pub/Sub Lite](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-lite) is a zonal service for messaging systems with predictable traffic patterns. If you publish 1 MiB-1 GiB of messages per second, Pub/Sub Lite is a low cost option for high-volume event ingestion.

## Personal Notes

- Pub/Sub is a fully managed messaging service in Google Cloud
- Supports global distribution and automatic scaling
- Message retention up to 7 days maximum
- Supports both push and pull subscription modes
- Python client library provides comprehensive feature support
