#!/usr/bin/env ruby

require 'json'
require 'redis'

job={
    task: "sleep",
    arguments: {
        duration: 5
    }

}

redis = Redis.new

10.times do |i|

    # Pick a random duration, increases with the number of jobs
    dur = (rand(i)+1).to_i

    job[:arguments][:duration] = dur
    redis.publish('working', job.to_json)
end

# Send the exit command
redis.publish('working', 'exit')

puts('Done')

