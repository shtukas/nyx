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
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

# Projects::fGeneralUpgrade()

# Projects::folderpaths(itemsfolderpath)
# Projects::getuuidOrNull(folderpath)
# Projects::makeCatalystObjectOrNull(folderpath)
# Projects::issueNewItemWithDescription(description)
# Projects::generalUpgrade()

class Projects

    def self.agentuuid()
        "30ff0f4d-7420-432d-b75b-826a2a8bc7cf"
    end

    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end

    def self.getuuidOrNull(folderpath)
        return nil if !File.exist?(folderpath)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        IO.read("#{folderpath}/.uuid").strip
    end

    def self.performObjectClosing(object)
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath targetFolder
        puts "source: #{object["item-data"]['folderpath']}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        LucilleCore::copyFileSystemLocation(object["item-data"]['folderpath'], targetFolder)
        LucilleCore::removeFileSystemLocation(object["item-data"]['folderpath'])
    end

    def self.agentMetric()
        0.8 - 0.6*( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_PROJECTS_AGENT_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/3
    end

    def self.objectMetric(uuid)
        Math.exp(-GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600).to_f/100
    end

    def self.makeCatalystObjectOrNull(folderpath)
        uuid = Projects::getuuidOrNull(folderpath)
        return nil if uuid.nil?
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        announce = "project: " + folderProbeMetadata["announce"]
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        object = {
            "uuid" => uuid,
            "agent-uid" => self.agentuuid(),
            "metric" => isRunning ? 2 - CommonsUtils::traceToMetricShift(uuid) : self.agentMetric() + self.objectMetric(uuid) + CommonsUtils::traceToMetricShift(uuid),
            "announce" => announce,
            "commands" => ( isRunning ? ["stop"] : ["start"] ) + ["completed", "file", "folder"],
            "default-expression" => isRunning ? "stop" : "start"
        }
        object["item-data"] = {}
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["timings"] = GenericTimeTracking::timings(uuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.issueNewItemWithDescription(description)
        folderpath = "#{CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        folderpath
    end

    def self.interface()
        puts "Agent: Projects"
        Projects::folderpaths(CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER)
            .each{|folderpath|
                folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
                announce = "project: " + folderProbeMetadata["announce"]
                puts "    #{announce}"
            }
        LucilleCore::pressEnterToContinue()
    end    

    def self.generalUpgrade()
        objects = Projects::folderpaths(CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER)
            .map{|folderpath| Projects::makeCatalystObjectOrNull(folderpath) }
            .compact
        FlockTransformations::removeObjectsFromAgent(self.agentuuid())
        FlockTransformations::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommand(object, command)
        if command=='file' then
            folderpath = object["item-data"]["folderpath"]
            filepath = "#{folderpath}/file-#{object["uuid"]}.txt"
            if !File.exists?(filepath) then
                FileUtils.touch(filepath)
            end
            system("open '#{filepath}'")
        end
        if command=='start' then
            metadata = object["item-data"]["folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(object["uuid"])
            GenericTimeTracking::start(CATALYST_COMMON_PROJECTS_AGENT_METRIC_GENERIC_TIME_TRACKING_KEY)
        end
        if command=='stop' then
            GenericTimeTracking::stop(object["uuid"])
            GenericTimeTracking::stop(CATALYST_COMMON_PROJECTS_AGENT_METRIC_GENERIC_TIME_TRACKING_KEY)
        end
        if command=="completed" then
            GenericTimeTracking::stop(object["uuid"])
            GenericTimeTracking::stop(CATALYST_COMMON_PROJECTS_AGENT_METRIC_GENERIC_TIME_TRACKING_KEY)
            time = Time.new
            targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
            FileUtils.mkpath targetFolder
            puts "source: #{object["item-data"]["folderpath"]}"
            puts "target: #{targetFolder}"
            FileUtils.mkpath(targetFolder)
            LucilleCore::copyFileSystemLocation(object["item-data"]['folderpath'], targetFolder)
            LucilleCore::removeFileSystemLocation(object["item-data"]['folderpath'])
        end
        if command=="folder" then
            system("open '#{object["item-data"]["folderpath"]}'")
        end
    end
end
