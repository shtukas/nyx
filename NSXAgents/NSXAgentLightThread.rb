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

# -------------------------------------------------------------------------------------

class NSXAgentLightThread

    # NSXAgentLightThread::agentuuid()
    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    # NSXAgentLightThread::getLightThreadObjects(lightThread)
    def self.getLightThreadObjects(lightThread)
        if NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "0142daee-356a-4f62-b87d-df69397d3738", 600) then
            $LightThreadTheBigUglyMemoryCache = {}
        end
        if $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]].nil? then
            $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]] = {
                "ObjectsUUID"                 => nil,
                "ProcessObjectAndCommandUUID" => nil,
                "CachedObjects"               => nil
            }
        end
        if ( $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["ObjectsUUID"] == $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["ProcessObjectAndCommandUUID"] ) and ( !$LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["CachedObjects"].nil? ) then
            return $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["CachedObjects"].clone
        end
        objects = 
            (
                [ NSXLightThreadUtils::lightThreadToCatalystObject(lightThread) ] +
                  NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread) +
                [ NSXLightThreadsTargetFolderInterface::lightThreadToItsFolderCatalystObjectOrNull(lightThread) ]
            ).compact
        objects = 
            if NSXLightThreadUtils::trueIfLightThreadIsRunningOrActive(lightThread) then
                objects
            else
                objects.select{|object| object["isRunning"] }
            end
        $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["CachedObjects"] = objects
        $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["ObjectsUUID"] = $LightThreadTheBigUglyMemoryCache[lightThread["uuid"]]["ProcessObjectAndCommandUUID"]
        objects
    end

    # NSXAgentLightThread::getObjects()
    def self.getObjects()
        NSXLightThreadUtils::lightThreads()
            .reject{|lightThread| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]) }
            .map{|lightThread|
                NSXAgentLightThread::getLightThreadObjects(lightThread)
            }.flatten
    end

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
        if command.start_with?("time:") then
            timeInHours = command[5,99].to_f
            NSXLightThreadUtils::addTimeToLightThread(lightThread["uuid"], timeInHours*3600)
        end
        if command=='dive' then
            NSXLightThreadUtils::lightThreadDive(lightThread)
        end
        $LightThreadTheBigUglyMemoryCache[object["item-data"]["lightThread"]["uuid"]]["ProcessObjectAndCommandUUID"] = SecureRandom.hex
    end

    # NSXAgentLightThread::interface()
    def self.interface()
    end

end
