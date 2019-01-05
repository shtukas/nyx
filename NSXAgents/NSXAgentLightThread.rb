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

    # NSXAgentLightThread::thetaTrafficControl()
    def self.thetaTrafficControl()
        return if NSXLightThreadUtils::lightThreads().any?{|lightThread| NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) }
        NSXLightThreadUtils::lightThreads()
            .select{|lightThread| lightThread["theta00e769"] } 
            .select{|lightThread| (NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, 1) || 0) >= 100 }
            .each{|lightThread|
                lightThread["theta00e769"] = false
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
                puts lightThread
            }
        return if NSXLightThreadUtils::lightThreads()
            .select{|lightThread| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]).nil? }
            .select{|lightThread| lightThread["activationWeekDays"].nil? or lightThread["activationWeekDays"].include?(NSXMiscUtils::currentWeekDay())  }
            .any?{|lightThread| lightThread["theta00e769"] }            
        NSXLightThreadUtils::lightThreads()
            .select{|lightThread| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]).nil? }
            .select{|lightThread| lightThread["activationWeekDays"].nil? or lightThread["activationWeekDays"].include?(NSXMiscUtils::currentWeekDay())  }
            .sort{|l1, l2| NSXLightThreadMetrics::lightThread2Metric(l1)<=>NSXLightThreadMetrics::lightThread2Metric(l2) }
            .reverse
            .first(1)
            .each{|lightThread|
                lightThread["theta00e769"] = true
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            }
    end

    # NSXAgentLightThread::getObjects()
    def self.getObjects()
        NSXAgentLightThread::thetaTrafficControl()
        # This agent emits stream objects
        NSXLightThreadUtils::lightThreads()
        .select{|lightThread| lightThread["theta00e769"] or NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) }
        .map{|lightThread|
            objects = [ NSXLightThreadUtils::lightThreadToCatalystObject(lightThread) ] + NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread) + [ NSXLightThreadsTargetFolderInterface::lightThreadToItsFolderCatalystObjectOrNull(lightThread) ]
            objects = objects.compact
            if NSXLightThreadUtils::trueIfLightThreadIsRunningOrActive(lightThread) then
                objects
            else
                objects.select{|object| object["isRunning"] }
            end
        }
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
            NSXLightThreadUtils::lightThreadAddTime(lightThread["uuid"], timeInHours)
        end
        if command=='dive' then
            NSXLightThreadUtils::lightThreadDive(lightThread)
        end
    end

    # NSXAgentLightThread::interface()
    def self.interface()
    end

end
