#!/bin/bash

# GSP095 - Pub/Sub: Qwik Start - Command Line
# This script automates the Pub/Sub lab steps

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check command success
check_command() {
    if [ $? -eq 0 ]; then
        print_success "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Variables (customize as needed)
MAIN_TOPIC="myTopic"
MAIN_SUBSCRIPTION="mySubscription"
TEST_TOPIC1="Test1"
TEST_TOPIC2="Test2"
TEST_SUB1="Test1"
TEST_SUB2="Test2"

# User input variables
YOUR_NAME=""
FOOD=""

print_status "Starting GSP095 - Pub/Sub: Qwik Start - Command Line"
echo

# Prompt for user input
read -p "Enter your name for the message: " YOUR_NAME
read -p "Enter your favorite food: " FOOD

if [ -z "$YOUR_NAME" ] || [ -z "$FOOD" ]; then
    print_error "Name and food are required. Exiting."
    exit 1
fi

echo
print_status "=== Task 1: Pub/Sub Topics ==="
echo

# Task 1.1: Create main topic
print_status "Creating main topic: $MAIN_TOPIC"
gcloud pubsub topics create $MAIN_TOPIC
check_command "Topic creation ($MAIN_TOPIC)"

# Task 1.2: Create test topics
print_status "Creating test topics: $TEST_TOPIC1 and $TEST_TOPIC2"
gcloud pubsub topics create $TEST_TOPIC1
check_command "Topic creation ($TEST_TOPIC1)"

gcloud pubsub topics create $TEST_TOPIC2
check_command "Topic creation ($TEST_TOPIC2)"

# Task 1.3: List topics
print_status "Listing all topics"
gcloud pubsub topics list
echo

# Task 1.4: Delete test topics
print_status "Deleting test topics"
gcloud pubsub topics delete $TEST_TOPIC1
check_command "Topic deletion ($TEST_TOPIC1)"

gcloud pubsub topics delete $TEST_TOPIC2
check_command "Topic deletion ($TEST_TOPIC2)"

# Task 1.5: Verify deletion
print_status "Verifying topic deletion"
gcloud pubsub topics list
echo

echo
print_status "=== Task 2: Pub/Sub Subscriptions ==="
echo

# Task 2.1: Create main subscription
print_status "Creating main subscription: $MAIN_SUBSCRIPTION for topic: $MAIN_TOPIC"
gcloud pubsub subscriptions create --topic $MAIN_TOPIC $MAIN_SUBSCRIPTION
check_command "Subscription creation ($MAIN_SUBSCRIPTION)"

# Task 2.2: Create test subscriptions
print_status "Creating test subscriptions"
gcloud pubsub subscriptions create --topic $MAIN_TOPIC $TEST_SUB1
check_command "Subscription creation ($TEST_SUB1)"

gcloud pubsub subscriptions create --topic $MAIN_TOPIC $TEST_SUB2
check_command "Subscription creation ($TEST_SUB2)"

# Task 2.3: List subscriptions
print_status "Listing subscriptions for topic: $MAIN_TOPIC"
gcloud pubsub topics list-subscriptions $MAIN_TOPIC
echo

# Task 2.4: Delete test subscriptions
print_status "Deleting test subscriptions"
gcloud pubsub subscriptions delete $TEST_SUB1
check_command "Subscription deletion ($TEST_SUB1)"

gcloud pubsub subscriptions delete $TEST_SUB2
check_command "Subscription deletion ($TEST_SUB2)"

# Task 2.5: Verify subscription deletion
print_status "Verifying subscription deletion"
gcloud pubsub topics list-subscriptions $MAIN_TOPIC
echo

echo
print_status "=== Task 3: Pub/Sub Publishing and Pulling Single Messages ==="
echo

# Task 3.1: Publish messages
print_status "Publishing messages to topic: $MAIN_TOPIC"

gcloud pubsub topics publish $MAIN_TOPIC --message "Hello"
check_command "Message publish (Hello)"

gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher's name is $YOUR_NAME"
check_command "Message publish (name)"

gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher likes to eat $FOOD"
check_command "Message publish (food)"

gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher thinks Pub/Sub is awesome"
check_command "Message publish (awesome)"

# Task 3.2: Pull messages one by one (demonstrating single message pull)
print_status "Pulling messages one by one (--auto-ack)"

echo "Pull 1:"
gcloud pubsub subscriptions pull $MAIN_SUBSCRIPTION --auto-ack
echo

echo "Pull 2:"
gcloud pubsub subscriptions pull $MAIN_SUBSCRIPTION --auto-ack
echo

echo "Pull 3:"
gcloud pubsub subscriptions pull $MAIN_SUBSCRIPTION --auto-ack
echo

echo "Pull 4 (should be empty):"
gcloud pubsub subscriptions pull $MAIN_SUBSCRIPTION --auto-ack
echo

echo
print_status "=== Task 4: Pub/Sub Pulling All Messages from Subscriptions ==="
echo

# Task 4.1: Publish more messages
print_status "Publishing additional messages"
gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher is starting to get the hang of Pub/Sub"
check_command "Message publish (hang of Pub/Sub)"

gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher wonders if all messages will be pulled"
check_command "Message publish (wonders)"

gcloud pubsub topics publish $MAIN_TOPIC --message "Publisher will have to test to find out"
check_command "Message publish (test to find out)"

# Task 4.2: Pull all messages with limit
print_status "Pulling all messages with --limit=3 flag"
sleep 2  # Brief pause to ensure messages are available
gcloud pubsub subscriptions pull $MAIN_SUBSCRIPTION --limit=3
echo

echo
print_success "=== Lab GSP095 Completed Successfully! ==="
echo
print_status "Summary of what was accomplished:"
echo "✓ Created and managed Pub/Sub topics"
echo "✓ Created and managed Pub/Sub subscriptions"
echo "✓ Published messages to topics"
echo "✓ Pulled messages using different flags"
echo "✓ Demonstrated message consumption behavior"
echo
print_warning "Note: All messages have been consumed. In a real scenario,"
print_warning "you would typically process messages without --auto-ack"
echo
print_status "Cleanup: The script has left the main topic and subscription for manual cleanup"
print_status "To clean up: gcloud pubsub topics delete $MAIN_TOPIC"
echo
