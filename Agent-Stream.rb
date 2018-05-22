#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
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
require_relative "Commons.rb"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# -------------------------------------------------------------------------------------

# Stream::agentuuid()
# Stream::processObjectAndCommand(object, command)

# Stream::folderpaths(itemsfolderpath)
# Stream::folderpath2uuid(folderpath)
# Stream::getUUIDs()
# Stream::folderpathToCatalystObjectOrNull(folderpath)
# Stream::performObjectClosing(object)
# Stream::objectCommandHandler(object, command)
# Stream::issueNewItemFromDescription(description)
# Stream::generalUpgrade()

class Stream

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

    def self.uuid2metric(uuid, status)
        metric = 0.40 + 0.25*Math.sin( (Time.new.to_f/86400)+CommonsUtils::traceToRealInUnitInterval(Digest::SHA1.hexdigest(uuid)*3.14*2) )
        metric = metric * GenericTimeTracking::metric2("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17", 0, 1, 8)
        metric = status[0] ? 2 - CommonsUtils::traceToMetricShift(uuid) : metric
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

    def self.performObjectClosing(object)
        uuid = object['uuid']
        GenericTimeTracking::stop(uuid)
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath targetFolder
        puts "source: #{object["item-data"]["folderpath"]}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        if File.exists?(object["item-data"]["folderpath"]) then
            LucilleCore::copyFileSystemLocation(object["item-data"]["folderpath"], targetFolder)
            LucilleCore::removeFileSystemLocation(object["item-data"]["folderpath"])
        end
        EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
        FlockTransformations::removeObjectIdentifiedByUUID(uuid)
    end

    def self.issueNewItemFromDescription(description)
        folderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        folderpath
    end

    def self.interface()
        
    end

    def self.generalUpgrade()
        existingUUIDsFromFlock = $flock["objects"]
            .select{|object| object["agent-uid"]==self.agentuuid() }
            .map{|object| object["uuid"] }
        existingUUIDsFromDisk = Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER).map{|folderpath| Stream::folderpath2uuid(folderpath) }
        unregisteredUUIDs = existingUUIDsFromDisk - existingUUIDsFromFlock
        unregisteredUUIDs.each{|uuid|
            # We need to build the object, then make a Flock update and emit an event
            folderpath = Stream::uuid2folderpathOrNull(uuid)
            object = Stream::folderpathToCatalystObjectOrNull(folderpath)
            EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
            FlockTransformations::addOrUpdateObject(object)
        }
        objects = $flock["objects"].select{|object| object["agent-uid"]==self.agentuuid() }
        objects.each{|object|
            uuid = object["uuid"]
            status = GenericTimeTracking::status(uuid)
            object["metric"]              = Stream::uuid2metric(uuid, status)
            object["commands"]            = Stream::uuid2commands(uuid, status)
            object["default-expression"]  = Stream::uuid2defaultExpression(uuid, status)
            object["item-data"]["status"] = status
            object["is-running"]          = status[0]
            FlockTransformations::addOrUpdateObject(object)
        }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object['uuid']
        if command=='folder' then
            system("open '#{object["item-data"]["folderpath"]}'")
        end
        if command=='start' then
            metadata = object["item-data"]["folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(uuid)
            GenericTimeTracking::start("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17")
            folderpath = object["item-data"]["folderpath"]
            object = Stream::folderpathToCatalystObjectOrNull(folderpath)
            FlockTransformations::addOrUpdateObject(object)
        end
        if command=='stop' then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17")
            folderpath = object["item-data"]["folderpath"]
            object = Stream::folderpathToCatalystObjectOrNull(folderpath)
            FlockTransformations::addOrUpdateObject(object)
        end
        if command=="completed" then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17")
            Stream::performObjectClosing(object)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            FlockTransformations::removeObjectIdentifiedByUUID(uuid)
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
            Stream::performObjectClosing(object)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            FlockTransformations::removeObjectIdentifiedByUUID(uuid)
        end
    end
end

# -------------------------------------------------------------------------------------