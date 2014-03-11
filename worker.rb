#!/usr/bin/env ruby

require 'json'
require 'redis'

require 'thread'

redis = Redis.new

# Translate the JSON into some method of work
def work(msg, count)

    res = true

    job = JSON.parse(msg)

    # Flatten out the task and arguments into an evaluable command
    task =[job['task'], job['arguments'].values.join].flatten.join(" ")

    begin

        # Artificially create an error for job 5
        if count == 5
            raise ArgumentError
        end

        eval(task)
    rescue ArgumentError
        res = false
    end

    status = res ? 'Finished' : 'Failed'
    
    puts "#{count}: #{status} #{task}"
    res
end

# Retry jobs that failed
#   Adds to queue if it fails again, should have a limit
#
# Arguments:
#   retry_queue: The queue to try
#   threads: The pool of threads to add to
#   The current job count, will be modified
def retry_jobs(retry_queue, threads, job_c)
    until retry_queue.empty?
        job = retry_queue.pop
        puts "Trying #{job[1]} again"
        job_c += 1
        threads << Thread.new { retry_queue << [job[0], job_c] unless work(job[0], job_c) }
    end
end

job_c = 0

# Synchronous queue object
retry_queue = Queue.new

# Subscribe and work
redis.subscribe 'working' do |on|

    @threads = []

    on.message do |channel, message|
        unless message == 'exit'

            job_c += 1

            # Create a new thread to execute the job
            @threads << Thread.new do
                # If a job fails, add the message into the retry queue
                retry_queue << [message, job_c] unless work(message, job_c) 
            end

            retry_jobs(retry_queue, @threads, job_c)
        else
            redis.unsubscribe 
        end

    end

    on.unsubscribe do |channel, sub|
        # Finish jobs
        @threads.each { |t| t.join }

        # Give one last try to failed jobs
        retry_jobs(retry_queue, @threads, job_c)

        # Wait for failed jobs to finish
        @threads.each { |t| t.join }

        puts 'Unsubbed'
    end
end

