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

job_c = 0

# Synchronous queue object
job_queue = Queue.new

# Subscribe and work
redis.subscribe 'working' do |on|

    @threads = []

    on.message do |channel, message|
        unless message == 'exit'

            job_c += 1

            # Create a new thread to execute the job
            @threads << Thread.new do
                # If a job fails, add the message into the retry queue
                job_queue << [message, job_c] unless work(message, job_c) 
            end
        else
            redis.unsubscribe 
        end

        # Retry jobs that failed
        # Adds to queue if it fails again, should have a limit
        until job_queue.empty?
            job = job_queue.pop
            puts "Trying #{job[1]} again"
            job_c += 1
            @threads << Thread.new { job_queue << [job[0], job_c] unless work(job[0], job_c) }
        end
    end

    on.unsubscribe do |channel, sub|

        # Wait for all threads to complete
        @threads.each { |t| t.join }
        puts 'Unsubbed'
    end
end

