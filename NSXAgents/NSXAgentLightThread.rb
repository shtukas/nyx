#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'json'
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
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -------------------------------------------------------------------------------------

class NSXAgentLightThread

    # NSXAgentLightThread::agentuuid()
    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    # NSXAgentLightThread::getLightThreadObjects(lightThread)
    def self.getLightThreadObjects(lightThread)
        lightThreadCatalystObject = NSXLightThreadUtils::lightThreadToCatalystObject(lightThread)
        ( (lightThreadCatalystObject["prioritization"] == "running") ? [ lightThreadCatalystObject ] : []) + NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
    end

    # NSXAgentLightThread::getCachedObjects()
    def self.getCachedObjects()
        JSON.parse(
            KeyValueStore::getOrDefaultValue("/Galaxy/DataBank/Catalyst/Wave-KVStoreRepository", "764f1774-7fd3-411e-b507-f968ec770c0f:#{NSXMiscUtils::currentDay()}", "[]")
        )
    end

    # NSXAgentLightThread::setCachedOjects(objects)
    def self.setCachedOjects(objects)
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/Wave-KVStoreRepository", "764f1774-7fd3-411e-b507-f968ec770c0f:#{NSXMiscUtils::currentDay()}", JSON.generate(objects))
    end

    # NSXAgentLightThread::getObjects()
    def self.getObjects()
        objects = NSXAgentLightThread::getCachedObjects()
        return objects if objects.size>0

        objects = NSXLightThreadUtils::lightThreads()
            .reject{|lightThread| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]) }
            .map{|lightThread| NSXAgentLightThread::getLightThreadObjects(lightThread) }.flatten
            .first(3)

        NSXAgentLightThread::setCachedOjects(objects)
        objects
    end

    # NSXAgentLightThread::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        return if object["item-data"].nil?
        return if object["item-data"]["lightThread"].nil?
        lightThread = object["item-data"]["lightThread"]
        filepath = object["item-data"]["filepath"]
        if command=='start' then
            NSXRunner::start(lightThread["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
        end
        if command=='stop' then
            NSXLightThreadUtils::stopLightThread(lightThread["uuid"])
        end
        if command=='dive' then
            NSXLightThreadUtils::lightThreadDive(lightThread)
        end
        KeyValueStore::destroy("/Galaxy/DataBank/Catalyst/Wave-KVStoreRepository", "764f1774-7fd3-411e-b507-f968ec770c0f:#{NSXMiscUtils::currentDay()}")
    end

    # NSXAgentLightThread::interface()
    def self.interface()
    end
end
