# Redis Job Queue

Small Job Queue implemented using Redis PubSub

## Description

* Server creates 10 'sleep' commands of random duration
* Worker evaluates and executes the command
* On a failed job, the job is added to a retry queue and a new thread is created on the next message
