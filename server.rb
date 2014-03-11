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

redis.publish('working', job.to_json)

puts('Done')

