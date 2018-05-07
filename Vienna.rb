#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

# -------------------------------------------------------------------------------------

VIENNA_PATH_TO_DATA = "/Users/pascal/Library/Application Support/Vienna/messages.db"

# select link from messages where read_flag=0;
# update messages set read_flag=1 where link="https://www.schneier.com/blog/archives/2018/04/security_vulner_14.html"

# Vienna::getUnreadLinks()

class Vienna

    def self.getUnreadLinks()
        query = "select link from messages where read_flag=0;"
        `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
    end

    def self.getUnreadLinkOrNull()
        Vienna::getUnreadLinks().first
    end

    def self.getUnreadLinks()
        query = "select link from messages where read_flag=0;"
        `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
    end

    def self.setLinkAsRead(link)
        query = "update messages set read_flag=1 where link=\"#{link}\""
        system("sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'")
    end

    def self.getCatalystObjects()
        FIFOQueue::takeWhile(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        link = Vienna::getUnreadLinkOrNull()
        return [] if link.nil?
        uuid = Digest::SHA1.hexdigest("cc8c96fe-efa3-4f8a-9f81-5c61f12d6872:#{link}")[0,8]
        metric = 0.2 + 0.6*Math.exp(-FIFOQueue::size(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0").to_f/20)
        [
            {
                "uuid" => uuid,
                "metric" => metric,
                "announce" => "vienna: #{link}",
                "commands" => ['open', 'done'],
                "default-expression" => "open done",
                "command-interpreter" => lambda{|object, command|
                    if command=='open' then
                        system("open '#{object["link"]}'")
                    end
                    if command=='done' then
                        Vienna::setLinkAsRead(object["link"])
                        FIFOQueue::push(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", Time.new.to_i)
                    end
                },
                "link" => link
            }
        ]
    end

end
