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

require_relative "Stream.rb"

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
# StreamKiller::getTargetUUIDOrNull()
# StreamKiller::getObjectForTargetUUIDOrNull(targetuuid)

class StreamKiller
    def self.getTargetUUIDOrNull()
        targetuuid = FIFOQueue::getFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613")
        if targetuuid.nil? then
            Stream::getUUIDs().shuffle.each{|uuid|
                FIFOQueue::push(nil, "6e724d6b-8273-49cb-8115-c7de81125613", uuid)
            }
        end
        FIFOQueue::getFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613")
    end

    def self.getObjectForTargetUUIDOrNull(targetuuid)
        Stream::getCatalystObjects()
            .select{|object| object["uuid"]==targetuuid }
            .first
    end

    def self.getCatalystObjects()
        currentCount1 = Dir.entries("/Galaxy/DataBank/Catalyst/Stream/strm1").size
        KillersCurvesManagement::shiftCurveIfOpportunity("/Galaxy/DataBank/Catalyst/Killers-Curves/Stream", currentCount1)
        curve1 = KillersCurvesManagement::getCurve("/Galaxy/DataBank/Catalyst/Killers-Curves/Stream")
        idealCount1 = KillersCurvesManagement::computeIdealCountFromCurve(curve1)
        metric1 = KillersCurvesManagement::computeMetric(currentCount1, idealCount1)
        targetobject = Stream::getCatalystObjects().sample
        if targetobject then
            targetobject["metric"] = metric1
            targetobject["announce"] = "(stream killer) #{targetobject["announce"]}"
            [ targetobject ]
        else
            [
                {
                    "uuid" => SecureRandom.hex(4),
                    "metric" => metric1,
                    "announce" => "-> stream killer could not retrieve a targetuuid",
                    "commands" => [],
                    "command-interpreter" => lambda{|object, command| }
                }
            ]
        end
    end
end
