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

require_relative "Agent-Stream.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

# -------------------------------------------------------------------------------------

# metric1 = f(idealCount1*0.9) = 0
#          f(idealCount1)     = 1
#          slope = 1.to_f/(0.1*idealCount1)
#          f(x) = x.to_f/(0.1*idealCount1) + something
#          something = f(x) - x.to_f/(0.1*idealCount1)
#          something = - (idealCount1*0.9).to_f/(0.1*idealCount1)
#          f(x) = x.to_f/(0.1*idealCount1) - (idealCount1*0.9).to_f/(0.1*idealCount1)
#          check: f(idealCount1*0.9) = (idealCount1*0.9).to_f/(0.1*idealCount1) - (idealCount1*0.9).to_f/(0.1*idealCount1) = 0
#          check: f(idealCount1)     = idealCount1.to_f/(0.1*idealCount1) - (idealCount1*0.9).to_f/(0.1*idealCount1)
#                                   = (idealCount1*0.9 + idealCount1*0.1).to_f/(0.1*idealCount1) - (idealCount1*0.9).to_f/(0.1*idealCount1)
#                                   = 1

# StreamKiller::getCatalystObjects()

class StreamKiller

    def self.agentuuid()
        "e16a03ac-ac2c-441a-912e-e18086addba1"
    end

    def self.processObject(object, command)
        Nil
    end

    def self.metric()
        currentCount1 = Dir.entries("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Stream").size
        KillersCurvesManagement::shiftCurveIfOpportunity("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Killers-Curves/Stream", currentCount1)
        curve1 = KillersCurvesManagement::getCurve("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Killers-Curves/Stream")
        idealCount1 = KillersCurvesManagement::computeIdealCountFromCurve(curve1)
        metric1 = KillersCurvesManagement::computeMetric(currentCount1, idealCount1)
        metric1
    end

    def self.getCatalystObjects()
        targetobject = Stream::getCatalystObjects().select{|object| object["metric"]==0 }.sample
        if targetobject then
            targetobject = targetobject.clone
            targetobject["metric"] = [self.metric(), 1].min - Saturn::traceToMetricShift("ec47ddf3-3040-4c7d-85ce-6c5db280f4a6")
            targetobject["announce"] = "(stream killer) #{targetobject["announce"]}"
            [ targetobject ]
        else
            [
                {
                    "uuid" => SecureRandom.hex(4),
                    "metric" => 0.5 + Saturn::traceToMetricShift("ec47ddf3-3040-4c7d-85ce-6c5db280f4a6"),
                    "announce" => "-> stream killer could not retrieve a targetuuid",
                    "commands" => [],
                    "agent-uid" => self.agentuuid()
                }
            ]
        end
    end
end

