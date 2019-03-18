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
        lightThreadCatalystObject = NSXLightThreadUtils::lightThreadToCatalystObject(lightThread)
        objects = (lightThreadCatalystObject["isRunning"] ? [ lightThreadCatalystObject ] : [] ) + NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
        objects
    end

    # NSXAgentLightThread::getObjects()
    def self.getObjects()
        NSXLightThreadUtils::lightThreads()
            .reject{|lightThread| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]) }
            .map{|lightThread| NSXAgentLightThread::getLightThreadObjects(lightThread) }.flatten
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
        if command=='dive' then
            NSXLightThreadUtils::lightThreadDive(lightThread)
        end
    end

    # NSXAgentLightThread::interface()
    def self.interface()
    end

end
