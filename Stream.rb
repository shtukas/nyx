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

$STREAM_GLOBAL_DATABASE = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "20ac3ba8-7c3b-4f39-9508-4535bf14d204", "{}"))

# $STREAM_GLOBAL_DATABASE["stream:times"] : Array[Unixtime, Timespan]
# $STREAM_GLOBAL_DATABASE["items:times"][uuid] : Array[Unixtime, Timespan] 
# $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] : Boolean
# $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["start-unixtime"]

# -------------------------------------------------------------------------------------

# StreamGlobalDataBaseInterface::storeDatabase()
# StreamGlobalDataBaseInterface::getItemTotalTimeInSecondsLastWeek(uuid)
# StreamGlobalDataBaseInterface::getStreamTotalTimeInSecondsLastWeek()
# StreamGlobalDataBaseInterface::trueIfItemIsRunning(uuid)
# StreamGlobalDataBaseInterface::addStreamTimespan(timespanInSeconds)
# StreamGlobalDataBaseInterface::startItem(uuid)
# StreamGlobalDataBaseInterface::stopItem(uuid)

class StreamGlobalDataBaseInterface

    def self.storeDatabase()
        KeyValueStore::set(nil, "20ac3ba8-7c3b-4f39-9508-4535bf14d204", JSON.generate($STREAM_GLOBAL_DATABASE))
    end

    def self.getItemTotalTimeInSecondsLastWeek(uuid)
        $STREAM_GLOBAL_DATABASE["items:times"] = {} if $STREAM_GLOBAL_DATABASE["items:times"].nil?
        $STREAM_GLOBAL_DATABASE["items:times"][uuid] = [] if $STREAM_GLOBAL_DATABASE["items:times"][uuid].nil?
        $STREAM_GLOBAL_DATABASE["items:times"][uuid]
            .select{|pair| (Time.new.to_i - pair[0]) < 86400*7 }
            .map{|pair| pair[1] }
            .inject(0, :+)
    end

    def self.getStreamTotalTimeInSecondsLastWeek()
        $STREAM_GLOBAL_DATABASE["stream:times"] = [] if $STREAM_GLOBAL_DATABASE["stream:times"].nil?
        $STREAM_GLOBAL_DATABASE["stream:times"]
            .select{|pair| (Time.new.to_i - pair[0]) < 86400*7 }
            .map{|pair| pair[1] }
            .inject(0, :+)
    end

    def self.trueIfItemIsRunning(uuid)
        $STREAM_GLOBAL_DATABASE["items:running-status"] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] = false if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"]
    end

    def self.addStreamTimespan(timespanInSeconds)
        $STREAM_GLOBAL_DATABASE["stream:times"] = [] if $STREAM_GLOBAL_DATABASE["stream:times"].nil?
        $STREAM_GLOBAL_DATABASE["stream:times"] << [Time.new.to_i, timespanInSeconds]
        StreamGlobalDataBaseInterface::storeDatabase()
    end

    def self.startItem(uuid)
        $STREAM_GLOBAL_DATABASE["items:running-status"] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] = false if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"].nil?
        return if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"]
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] = true
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["start-unixtime"] = Time.new.to_i
        StreamGlobalDataBaseInterface::storeDatabase()
    end

    def self.stopItem(uuid)
        $STREAM_GLOBAL_DATABASE["items:running-status"] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid] = {} if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid].nil?
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] = false if $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"].nil?
        return if !$STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"]
        $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["is-running"] = false
        timespan = Time.new.to_i - $STREAM_GLOBAL_DATABASE["items:running-status"][uuid]["start-unixtime"]
        $STREAM_GLOBAL_DATABASE["items:times"] = {} if $STREAM_GLOBAL_DATABASE["items:times"].nil?
        $STREAM_GLOBAL_DATABASE["items:times"][uuid] = [] if $STREAM_GLOBAL_DATABASE["items:times"][uuid].nil?
        $STREAM_GLOBAL_DATABASE["items:times"][uuid] << [Time.new.to_i, timespan]
        $STREAM_GLOBAL_DATABASE["stream:times"] = [] if $STREAM_GLOBAL_DATABASE["stream:times"].nil?
        $STREAM_GLOBAL_DATABASE["stream:times"] << [Time.new.to_i, timespan]
        StreamGlobalDataBaseInterface::storeDatabase()
    end    
end

# -------------------------------------------------------------------------------------

# Stream::folderpaths(itemsfolderpath)
# Stream::getuuid(folderpath)
# Stream::getUUIDs()
# Stream::folderpathToCatalystObject(folderpath, indx, streamName)
# Stream::performObjectClosing(object)
# Stream::objectCommandHandler(object, command)
# Stream::getCatalystObjectsFromDisk()
# Stream::getCatalystObjects()
# Stream::metric()

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
        ["strm1", "strm2"].map{|streamName|
            Stream::folderpaths("#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/#{streamName}")
            .map{|folderpath| Stream::getuuid(folderpath) }
        }.flatten
    end

    def self.metric(indx, itemTimeInSeconds, streamTimeInSeconds)
        multiplier1 = Math.exp(-indx.to_f/100)
        multiplier2 = Math.exp(-itemTimeInSeconds.to_f/(3600*4))
        multiplier3 = Math.exp(-streamTimeInSeconds.to_f/(3600*10)) 
        0.8*multiplier1*multiplier2*multiplier3
    end

    def self.folderpathToCatalystObject(folderpath, indx, streamName)
        uuid = Stream::getuuid(folderpath)
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath) 
        isRunning = StreamGlobalDataBaseInterface::trueIfItemIsRunning(uuid)
        metric = Stream::metric(indx, StreamGlobalDataBaseInterface::getItemTotalTimeInSecondsLastWeek(uuid), StreamGlobalDataBaseInterface::getStreamTotalTimeInSecondsLastWeek())
        metric = 2 if isRunning
        commands = ( isRunning ? ["stop"] : ["start"] ) + ["folder", "completed", "rotate", ">lib"]
        defaultExpression = ( isRunning ? "" : "start" )
        announce = "stream: #{folderProbeMetadata["announce"]} (#{"%.2f" % ( StreamGlobalDataBaseInterface::getItemTotalTimeInSecondsLastWeek(uuid).to_f/3600 )} hours past week)"
        {
            "uuid" => uuid,
            "metric" => metric,
            "announce" => announce,
            "commands" => commands,
            "default-expression" => defaultExpression,
            "command-interpreter" => lambda{|object, command| Stream::objectCommandHandler(object, command) },
            "is-running" => isRunning,
            "item-folderpath" => folderpath,
            "item-stream-name" => streamName,
            "item-indx" => indx,
            "item-not-on-day:eae1e24c" => KeyValueStore::getOrNull(nil, "796c6f6b-bc6b-4a55-b576-09c7494be23d:#{uuid}"), 
            "item-folder-probe-metadata" => folderProbeMetadata
        }
    end

    def self.performObjectClosing(object)
        uuid = object['uuid']
        StreamGlobalDataBaseInterface::addStreamTimespan(StreamGlobalDataBaseInterface::getItemTotalTimeInSecondsLastWeek(uuid))
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath targetFolder
        puts "source: #{object['item-folderpath']}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        LucilleCore::copyFileSystemLocation(object['item-folderpath'], targetFolder)
        LucilleCore::removeFileSystemLocation(object['item-folderpath'])
    end

    def self.objectCommandHandlerCore(object, command)
        uuid = object['uuid']
        if command=='folder' then
            system("open '#{object['item-folderpath']}'")
            Jupiter::interactiveDisplayObjectAndProcessCommand(folderpathToCatalystObject(object["item-folderpath"], object["item-indx"], object["item-stream-name"]))
        end
        if command=='start' then
            StreamGlobalDataBaseInterface::startItem(uuid)
            metadata = object["item-folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
        end
        if command=='stop' then
            StreamGlobalDataBaseInterface::stopItem(uuid)
        end
        if command=="completed" then
            Stream::performObjectClosing(object)
        end
        if command=='rotate' then
            sourcelocation = object["item-folderpath"]
            targetfolderpath  = "#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/strm2/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(sourcelocation, targetfolderpath)
        end
        if command=='>lib' then
            if StreamGlobalDataBaseInterface::trueIfItemIsRunning(uuid) then
                puts "The items is currently running..."
                if !LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to close it and carry on with the librarian archiving? ") then
                    return
                end
                StreamGlobalDataBaseInterface::stopItem(uuid)
            end
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

    def self.objectCommandHandler(object, command)
        status = Stream::objectCommandHandlerCore(object, command)
        KeyValueStore::set(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", JSON.generate(Stream::getCatalystObjectsFromDisk()))
        status
    end

    def self.getCatalystObjectsFromDisk()
        ["strm1", "strm2"]
            .map{|streamName|
                folderpaths = Stream::folderpaths("#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/#{streamName}")
                folderpaths.zip((0..folderpaths.size)).map{|folderpath, indx|
                    Stream::folderpathToCatalystObject(folderpath, indx, streamName)
                }
            }
            .flatten
    end

    def self.getCatalystObjects()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", "[]"))
            .map{|object| 
                object["command-interpreter"] = lambda{|object, command| Stream::objectCommandHandler(object, command) } # overriding this after deserialistion 
                object
            }
    end
end

# -------------------------------------------------------------------------------------

KeyValueStore::set(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", JSON.generate(Stream::getCatalystObjectsFromDisk()))

# -------------------------------------------------------------------------------------
