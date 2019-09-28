#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

class NSXContentUtils

    # NSXContentUtils::itemToAnnounce(item)
    def self.itemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
    end

    # NSXContentUtils::itemToBody(item)
    def self.itemToBody(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["body"]
        end
        "[09bab884] I don't know how to body: #{JSON.generate(item)}"
    end
end