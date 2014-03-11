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
    dur = (rand(i)+1).to_i

    job[:arguments][:duration] = dur
    redis.publish('working', job.to_json)
end

redis.publish('working', 'exit')

puts('Done')

