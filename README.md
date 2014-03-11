# Redis Job Queue

Small Job Queue implemented using Redis PubSub.

## Description

* Server creates 10 'sleep' commands of random, increasing, duration
* Worker evaluates and executes the command
* On a failed job, the job is added to a retry queue and a new thread is created on the next message

## Running

A Redis Server running on localhost is required to run the program. There is no
config file.
