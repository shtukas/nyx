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
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"

# -------------------------------------------------------------------------------------

OPEN_PROJECTS_PATH_TO_REPOSITORY = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Open-Projects"

# OpenProjects::getCatalystObjects()

# OpenProjects::folderpaths(itemsfolderpath)
# OpenProjects::getuuidOrNull(folderpath)
# OpenProjects::folderpath2CatalystObjectOrNull(folderpath)
# OpenProjects::getCatalystObjects()


class OpenProjects

    def self.agentuuid()
        "30ff0f4d-7420-432d-b75b-826a2a8bc7cf"
    end

    def self.processObject(object, command)
        if command=='start' then
            metadata = object["item-folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(object["uuid"])
            object["metric"] = 2 - Saturn::traceToMetricShift(uuid)
            object["commands"] = ["stop", "completed", "folder"]
            object["default-expression"] = ""
            return object
        end
        if command=='stop' then
            GenericTimeTracking::stop(object["uuid"])
            status = GenericTimeTracking::status(uuid)
            object["metric"] = GenericTimeTracking::metric2(uuid, 0.2, 0.8, 1) + Saturn::traceToMetricShift(uuid)
            object["commands"] = ["start", "completed", "folder"]
            object["default-expression"] = "start"
            return object
        end
        if command=="completed" then
            GenericTimeTracking::stop(object["uuid"])
            time = Time.new
            targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
            FileUtils.mkpath targetFolder
            puts "source: #{object['item-folderpath']}"
            puts "target: #{targetFolder}"
            FileUtils.mkpath(targetFolder)
            LucilleCore::copyFileSystemLocation(object['item-folderpath'], targetFolder)
            LucilleCore::removeFileSystemLocation(object['item-folderpath'])
            return Saturn::deathObject(object["uuid"])
        end
        if command=="folder" then
            system("open '#{object["item-folderpath"]}'")
            return nil
        end
        nil
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
        puts "source: #{object['item-folderpath']}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        LucilleCore::copyFileSystemLocation(object['item-folderpath'], targetFolder)
        LucilleCore::removeFileSystemLocation(object['item-folderpath'])
    end

    def self.folderpath2CatalystObjectOrNull(folderpath)
        uuid = OpenProjects::getuuidOrNull(folderpath)
        return nil if uuid.nil?
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        announce = "(open) project: " + folderProbeMetadata["announce"]
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        {
            "uuid" => uuid,
            "metric" => isRunning ? 2 - Saturn::traceToMetricShift(uuid) : GenericTimeTracking::metric2(uuid, 0.2, 0.8, 1) + Saturn::traceToMetricShift(uuid),
            "announce" => announce,
            "commands" => ( isRunning ? ["stop"] : ["start"] ) + ["completed", "folder"],
            "default-expression" => isRunning ? "" : "start",
            "item-folder-probe-metadata" => folderProbeMetadata,
            "item-folderpath" => folderpath,
            "agent-uid" => self.agentuuid()
        }
    end

    def self.getCatalystObjects()
        OpenProjects::folderpaths(OPEN_PROJECTS_PATH_TO_REPOSITORY)
            .map{|folderpath| OpenProjects::folderpath2CatalystObjectOrNull(folderpath) }
            .compact
    end
end
