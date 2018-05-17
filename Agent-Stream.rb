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
require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'colorize'
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

# Stream::agentuuid()
# Stream::upgradeFlockUsingObjectAndCommand(flock, object, command)

# Stream::folderpaths(itemsfolderpath)
# Stream::getuuid(folderpath)
# Stream::getUUIDs()
# Stream::folderpathToCatalystObjectOrNull(folderpath, indx, size)
# Stream::performObjectClosing(object)
# Stream::objectCommandHandler(object, command)
# Stream::issueNewItemFromDescription(description)
# Stream::flockGeneralUpgrade(flock)

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

    def self.getuuid(folderpath)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        IO.read("#{folderpath}/.uuid").strip
    end

    def self.getUUIDs()
        Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .map{|folderpath| Stream::getuuid(folderpath) }
    end

    def self.folderpathToCatalystObjectOrNull(folderpath, indx, size)
        return nil if !File.exist?(folderpath)
        uuid = Stream::getuuid(folderpath)
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        commands = ( isRunning ? ["stop"] : ["start"] ) + ["folder", "completed", "rotate", ">lib"]
        defaultExpression = ( isRunning ? "" : "start" )
        metric = 0.195 + 0.5*Jupiter::realNumbersToZeroOne(size, 100, 50)*Math.exp(-indx.to_f/100)*GenericTimeTracking::metric2("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17", 0, 1, 8) + Jupiter::traceToMetricShift(uuid)
        metric = isRunning ? 2 - Jupiter::traceToMetricShift(uuid) : metric
        announce = "stream: #{Jupiter::simplifyURLCarryingString(folderProbeMetadata["announce"])}"
        object = {
            "uuid" => uuid,
            "agent-uid" => self.agentuuid(),
            "metric" => metric,
            "announce" => announce,
            "commands" => commands,
            "default-expression" => defaultExpression,
            "is-running" => isRunning
        }
        object["item-data"] = {}
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object["item-data"]["status"] = status
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
        return if !File.exists?(object["item-data"]["folderpath"])
        LucilleCore::copyFileSystemLocation(object["item-data"]["folderpath"], targetFolder)
        LucilleCore::removeFileSystemLocation(object["item-data"]["folderpath"])
    end

    def self.issueNewItemFromDescription(description)
        folderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        folderpath
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        return [flock, []]
        folderpaths = Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
        size = folderpaths.size
        objects = folderpaths.zip((1..size))
            .map{|folderpath, indx| Stream::folderpathToCatalystObjectOrNull(folderpath, indx, size)}
            .compact
        flock["objects"] = flock["objects"] + objects
        [
            flock,
            objects.map{|o|  
                {
                    "event-type" => "Catalyst:Catalyst-Object:1",
                    "object"     => o
                }                
            }   
        ]
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        return [flock, []]
        uuid = object['uuid']
        if command=='folder' then
            system("open '#{object["item-data"]["folderpath"]}'")
            return []
        end
        if command=='start' then
            metadata = object["item-data"]["folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(uuid)
            GenericTimeTracking::start("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17")
        end
        if command=='stop' then
            GenericTimeTracking::stop(uuid)
            GenericTimeTracking::stop("stream-common-time:4259DED9-7C9D-4F91-96ED-A8A63FD3AE17")
        end
        if command=="completed" then
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
        end
    end
end

# -------------------------------------------------------------------------------------