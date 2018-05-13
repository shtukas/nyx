#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
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
require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
require_relative "Commons.rb"
require_relative "Agent-Vienna.rb"
# -------------------------------------------------------------------------------------

# ViennaKiller::getCatalystObjects()

class ViennaKiller

    def self.agentuuid()
        "7cbbde0d-e5d6-4be9-b00d-8b8011f7173f"
    end

    def self.processObject(object, command)
        Vienna::processObject(object, command)
        [ self.agentuuid(), "2ba71d5b-f674-4daf-8106-ce213be2fb0e" ] # self and Vienna
    end

    def self.metric()
        currentCount1 = Vienna::getUnreadLinks().size
        KillersCurvesManagement::shiftCurveIfOpportunity("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Killers-Curves/Vienna", currentCount1)
        curve1 = KillersCurvesManagement::getCurve("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Killers-Curves/Vienna")
        idealCount1 = KillersCurvesManagement::computeIdealCountFromCurve(curve1)
        metric1 = KillersCurvesManagement::computeMetric(currentCount1, idealCount1)
        metric1
    end

    def self.getCatalystObjects()
        targetobject = Vienna::getCatalystObjects().first
        if targetobject then
            targetobject = targetobject.clone
            targetobject["agent-uid"] = self.agentuuid()
            targetobject["metric"] = [self.metric(), 0.99].min - Saturn::traceToMetricShift("ecfa02cd-ac2c-4a1f-9e6a-78ee55dc61d2")
            targetobject["announce"] = "(vienna killer) #{targetobject["announce"]}"
            [ targetobject ]
        else
            [
                {
                    "uuid" => SecureRandom.hex(4),
                    "metric" => 0.5,
                    "announce" => "-> vienna killer could not retrieve a targetuuid",
                    "commands" => [],
                    "agent-uid" => self.agentuuid()
                }
            ]
        end
    end
end

