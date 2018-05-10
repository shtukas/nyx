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
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "Commons.rb"

require 'colorize'

# -------------------------------------------------------------------------------------

# Stream::folderpaths(itemsfolderpath)
# Stream::getuuid(folderpath)
# Stream::getUUIDs()
# Stream::folderpathToCatalystObject(folderpath)
# Stream::performObjectClosing(object)
# Stream::objectCommandHandler(object, command)
# Stream::getCatalystObjectsFromDisk()
# Stream::getCatalystObjects()

class Stream

    @@naturalTargets = {}

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

    def self.folderpathToCatalystObject(folderpath)
        uuid = Stream::getuuid(folderpath)
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        commands = ( isRunning ? ["stop"] : ["start"] ) + ["folder", "completed", "rotate", ">lib"]
        defaultExpression = ( isRunning ? "" : "start" )
        announce = "stream: #{folderProbeMetadata["announce"]}"
        {
            "uuid" => uuid,
            "metric" => isRunning ? 2 : GenericTimeTracking::metric(uuid),
            "announce" => announce,
            "commands" => commands,
            "default-expression" => defaultExpression,
            "command-interpreter" => lambda{|object, command| Stream::objectCommandHandler(object, command) },
            "is-running" => isRunning,
            "item-folderpath" => folderpath,
            "item-folder-probe-metadata" => folderProbeMetadata
        }
    end

    def self.performObjectClosing(object)
        uuid = object['uuid']
        GenericTimeTracking::stop(uuid)
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath targetFolder
        puts "source: #{object['item-folderpath']}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        LucilleCore::copyFileSystemLocation(object['item-folderpath'], targetFolder)
        LucilleCore::removeFileSystemLocation(object['item-folderpath'])
    end

    def self.objectCommandHandler(object, command)
        uuid = object['uuid']
        if command=='folder' then
            system("open '#{object['item-folderpath']}'")
            Jupiter::interactiveDisplayObjectAndProcessCommand(folderpathToCatalystObject(object["item-folderpath"]))
        end
        if command=='start' then
            metadata = object["item-folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(uuid)
        end
        if command=='stop' then
            GenericTimeTracking::stop(uuid)
        end
        if command=="completed" then
            Stream::performObjectClosing(object)
        end
        if command=='rotate' then
            sourcelocation = object["item-folderpath"]
            targetfolderpath  = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(sourcelocation, targetfolderpath)
        end
        if command=='>lib' then
            GenericTimeTracking::stop(uuid)
            sourcefolderpath = object['item-folderpath']
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

    def self.getCatalystObjects()
        Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .map{|folderpath| Stream::folderpathToCatalystObject(folderpath)}
    end

    def self.getCatalystObjectsFirst6()
        Stream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .first(6)
            .map{|folderpath| Stream::folderpathToCatalystObject(folderpath)}
    end

end

# -------------------------------------------------------------------------------------
