#!/usr/bin/env ruby

require 'json'
require 'redis'

redis = Redis.new

def work(msg)
    job = JSON.parse(msg)

    # Flatten out the task and arguments into an evaluable command
    task =[job['task'], job['arguments'].values.join].flatten.join(" ")
    eval(task)

    puts "Finished #{job['task']}"

end

# Subscribe and work
redis.subscribe 'working' do |on|

    @threads = []

    on.message do |channel, message|
        redis.unsubscribe if message == 'exit'

        @threads << Thread.new { work(message) }
    end

    on.unsubscribe do |channel, sub|
        # Wait for all threads to complete
        @threads.each { |t| t.join }
        puts 'Unsubbed'
    end
end

