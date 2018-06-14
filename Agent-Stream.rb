#!/usr/bin/ruby

# encoding: UTF-8
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'drb/drb'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'colorize'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "ProjectsCore.rb"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"
require_relative "AgentsManager.rb"

# -------------------------------------------------------------------------------------

AgentsManager::registerAgent(
    {
        "agent-name"      => "Stream",
        "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
        "general-upgrade" => lambda { Stream::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| Stream::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ Stream::interface() }
    }
)

# Stream::agentuuid()
# Stream::processObjectAndCommandFromCli(object, command)

# Stream::folderpaths(itemsfolderpath)
# Stream::folderpath2uuid(folderpath)
# Stream::getUUIDs()
# Stream::folderpathToCatalystObjectOrNull(folderpath)
# Stream::sendObjectToBinTimeline(object)
# Stream::objectCommandHandler(object, command)
# Stream::issueNewItemWithDescription(description)
# Stream::generalFlockUpgrade()

class Stream

    @@firstRun = true

    def self.agentuuid()
        "73290154-191f-49de-ab6a-5e5a85c6af3a"
    end
    
    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end

    def self.folderpath2uuid(folderpath)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        IO.read("#{folderpath}/.uuid").strip
    end

    def self.getUUIDs()
        Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .map{|folderpath| Stream::folderpath2uuid(folderpath) }
    end

    def self.uuid2folderpathOrNull(uuid)
        Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .each{|folderpath|
                if Stream::folderpath2uuid(folderpath)==uuid then
                    return folderpath
                end
            }
        nil
    end

    def self.uuid2commands(uuid, status)
        ( status[0] ? ["stop"] : ["start"] ) + ["folder", "completed", "rotate", ">lib"]
    end

    def self.uuid2defaultExpression(uuid, status)
        ( status[0] ? "" : "start" )
    end

    def self.folderpathToCatalystObjectOrNull(folderpath)
        return nil if !File.exist?(folderpath)
        uuid = Stream::folderpath2uuid(folderpath)
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        announce = "stream: #{CommonsUtils::simplifyURLCarryingString(folderProbeMetadata["announce"])}"
        object = {}
        object["uuid"] = uuid
        object["agent-uid"] = self.agentuuid()
        object["metric"] = 1                 # overriden during general update
        object["announce"] = announce
        object["commands"] = []              # overriden during general update
        object["default-expression"] = ""    # overriden during general update
        object["is-running"] = false         # overriden during general update
        object["item-data"] = {}
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object["item-data"]["status"] = nil  # overriden during general update
        object
    end

    def self.sendObjectToBinTimeline(object)
        uuid = object['uuid']
        GenericTimeTracking::stop(uuid)
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        puts "source: #{object["item-data"]["folderpath"]}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        if File.exists?(object["item-data"]["folderpath"]) then
            LucilleCore::copyFileSystemLocation(object["item-data"]["folderpath"], targetFolder)
            LucilleCore::removeFileSystemLocation(object["item-data"]["folderpath"])
        end
        EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
        TheFlock::removeObjectIdentifiedByUUID(uuid)
    end

    def self.issueNewItemWithDescription(description)
        folderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        folderpath
    end

    def self.interface()
        
    end

    def self.agentMetric()
        0.8 - 0.6*( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/3
    end

    def self.generalFlockUpgrade()

        # Adding the next object if there isn't one
        if TheFlock::flockObjects().select{|object| object["agent-uid"]==self.agentuuid() }.empty? then
            Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
                .first(1)
                .each{|folderpath|
                    object = Stream::folderpathToCatalystObjectOrNull(folderpath)
                    EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
                    TheFlock::addOrUpdateObject(object)
                }
        end

        # Updating the objects
        TheFlock::flockObjects()
            .select{|object| object["agent-uid"]==self.agentuuid() }
            .each{|object|
                uuid = object["uuid"]
                status = GenericTimeTracking::status(uuid)
                object["metric"]              = status[0] ? 2 - CommonsUtils::traceToMetricShift(uuid) : self.agentMetric() + CommonsUtils::traceToMetricShift(uuid)
                object["commands"]            = Stream::uuid2commands(uuid, status)
                object["default-expression"]  = Stream::uuid2defaultExpression(uuid, status)
                object["item-data"]["status"] = status
                object["is-running"]          = status[0]
                TheFlock::addOrUpdateObject(object)
            }
    end

    def self.processObjectAndCommandFromCli(object, command)
        uuid = object['uuid']
        if command=='folder' then
            system("open '#{object["item-data"]["folderpath"]}'")
        end
        if command=='start' then
            metadata = object["item-data"]["folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(uuid)
            GenericTimeTracking::start(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY)
            folderpath = object["item-data"]["folderpath"]
            object = Stream::folderpathToCatalystObjectOrNull(folderpath)
            TheFlock::addOrUpdateObject(object)
            FKVStore::set("96df64b9-c17a-4490-a555-f49e77d4661a:#{uuid}", "started-once")
        end
        if command=='stop' then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY)
            folderpath = object["item-data"]["folderpath"]
            object = Stream::folderpathToCatalystObjectOrNull(folderpath)
            TheFlock::addOrUpdateObject(object)
        end
        if command=='rotate' then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY)
            folderpath  = object["item-data"]["folderpath"]
            folderpath2 = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(folderpath, folderpath2)
            File.open("#{folderpath2}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            TheFlock::removeObjectIdentifiedByUUID(uuid)
        end
        if command=="completed" then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY)
            MiniFIFOQ::push("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY}", [Time.new.to_i, 600]) # special circumstances
            Stream::sendObjectToBinTimeline(object)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            TheFlock::removeObjectIdentifiedByUUID(uuid)
        end
        if command=='>lib' then
            GenericTimeTracking::stop(uuid)
            sourcefolderpath = object["item-data"]["folderpath"]
            atlasreference = "atlas-#{SecureRandom.hex(8)}"
            staginglocation = "/Users/pascal/Desktop/#{atlasreference}"
            LucilleCore::copyFileSystemLocation(sourcefolderpath, staginglocation)
            puts "Stream folder moved to the staging folder (Desktop), edit and press [Enter]"
            LucilleCore::pressEnterToContinue()
            LibrarianExportedFunctions::librarianUserInterface_makeNewPermanodeInteractive(staginglocation, nil, nil, atlasreference, nil, nil)
            targetlocation = R136CoreUtils::getNewUniqueDataTimelineFolderpath()
            LucilleCore::copyFileSystemLocation(staginglocation, targetlocation)
            LucilleCore::removeFileSystemLocation(staginglocation)
            Stream::sendObjectToBinTimeline(object)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            TheFlock::removeObjectIdentifiedByUUID(uuid)
        end
    end
end

# -------------------------------------------------------------------------------------