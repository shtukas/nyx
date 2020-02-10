# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

# The map folderUUID -> foldername is by KeyValueStore::set(nil, "7107a379-ae13-468a-b158-1fb29250e1dc:#{uuid}",foldername)

class NSXTodoFolders

    # --------------------------------------------------------------
    # Basic FS Operations

    # NSXTodoFolders::foldernameToFolderuuid(foldername)
    def self.foldernameToFolderuuid(foldername)
        folderpath = "/Users/pascal/Galaxy/2020-Todo/#{foldername}"
        filepath = "#{folderpath}/.uuid-ae79f802"
        if !File.exists?(filepath) then
            File.open(filepath, "w"){|f| f.puts(SecureRandom.hex) }
        end
        uuid = IO.read(filepath).strip
        KeyValueStore::set(nil, "7107a379-ae13-468a-b158-1fb29250e1dc:#{uuid}",foldername)
        uuid
    end

    # NSXTodoFolders::folderUUIDToFoldernameOrNull(uuid)
    def self.folderUUIDToFoldernameOrNull(uuid)
        return KeyValueStore::getOrNull(nil, "7107a379-ae13-468a-b158-1fb29250e1dc:#{uuid}")
    end

    # NSXTodoFolders::getFoldernames()
    def self.getFoldernames()
        Dir.entries("/Users/pascal/Galaxy/2020-Todo")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .sort
    end

    # NSXTodoFolders::getFolderuuids()
    def self.getFolderuuids()
        NSXTodoFolders::getFoldernames().map{|foldername| NSXTodoFolders::foldernameToFolderuuid(foldername) }
    end

    # NSXTodoFolders::getTodoRootFileContents(foldername)
    def self.getTodoRootFileContents(foldername)
        folderpath = "/Users/pascal/Galaxy/2020-Todo/#{foldername}"
        filepaths = [
            "#{folderpath}/00-TODO-README.txt",
            "#{folderpath}/000-TODO-README.txt"
        ]
        filepaths.each{|filepath|
            if File.exists?(filepath) then
                return IO.read(filepath).strip
            end
        }
        raise "70DB9A665245"
    end

    # --------------------------------------------------------------
    # Catalyst Objects

    # NSXTodoFolders::folderItemMetric(objectuuid, folderCounter, itemCounter)
    def self.folderItemMetric(objectuuid, folderCounter, itemCounter)
        x1 = 0.50 
        x2 = Math.exp(-folderCounter).to_f/100
        x3 = Math.exp(-itemCounter).to_f/1000 
        x4 = NSXMiscUtils::runtimePointsToMetricShift(NSXRunTimes::getPoints(objectuuid), 86400, 12*3600)
        x1 + x2 + x3 + x4
    end

    # NSXTodoFolders::runningTimeAsString(objectuuid)
    def self.runningTimeAsString(objectuuid)
        runningTime = NSXRunner::runningTimeOrNull(objectuuid)
        return "" if runningTime.nil?
        "running for #{(runningTime.to_f/60).to_i} minutes"
    end

    # NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid, folderCounter)
    def self.folderUUIDToCatalystObjects(folderuuid, folderCounter)
        foldername = NSXTodoFolders::folderUUIDToFoldernameOrNull(folderuuid)

        itemsInFolder = Dir.entries("/Users/pascal/Galaxy/2020-Todo/#{foldername}")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .sort
            .first(1)

        itemCounter = 0

        itemsInFolder.map{|filename|
            itemCounter = itemCounter + 1
            objectuuid = Digest::SHA1.hexdigest("#{folderuuid}/#{filename}")
            line = "[todo folders] #{foldername}" + ( NSXRunner::isRunning?(objectuuid) ? " [#{NSXTodoFolders::runningTimeAsString(objectuuid)}]" : "" )
            body = line  + "\n" + NSXTodoFolders::getTodoRootFileContents(foldername)
            {
                "uuid"           => objectuuid,
                "agentuid"       => "09cc9943-1fa0-45a4-8d22-a37e0c4ddf0c",
                "contentItem"    => {
                    "type" => "line-and-body",
                    "line" => line,
                    "body" => body
                },
                "metric"         => NSXRunner::isRunning?(objectuuid) ? 1 : NSXTodoFolders::folderItemMetric(objectuuid, folderCounter, itemCounter),
                "commands"       => NSXRunner::isRunning?(objectuuid) ? ["stop"] : ["start"],
                "defaultCommand" => NSXRunner::isRunning?(objectuuid) ? "stop" : "start",
                "isRunning"      => NSXRunner::isRunning?(objectuuid),
                "metric-shift"   => NSXMiscUtils::runtimePointsToMetricShift(NSXRunTimes::getPoints(objectuuid), 86400, 12*3600)
            }
        }
    end

    # NSXTodoFolders::catalystObjects()
    def self.catalystObjects()
        folderCounter = 0
        NSXTodoFolders::getFolderuuids().map{|folderuuid|
            folderCounter = folderCounter + 1
            NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid, folderCounter)
        }.flatten
    end

    # NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXTodoFolders::catalystObjects().select{|object| object["uuid"] == objectuuid }.first
    end

    # --------------------------------------------------------------
    # Catalyst Objects Life Cycles

    # NSXTodoFolders::objectHasBeenReviewedToday(objectuuid)
    def self.objectHasBeenReviewedToday(objectuuid)
        KeyValueStore::flagIsTrue("/Users/pascal/Galaxy/2020-DataBank/Catalyst/Data/TodoFolders/KV-Store", "a9de7bc6-e328-4ac6-b44a-3e745c87052f:#{objectuuid}:#{NSXMiscUtils::currentDay()}")
    end

    # NSXTodoFolders::markObjectHasBeenReviewed(objectuuid)
    def self.markObjectHasBeenReviewed(objectuuid)
        KeyValueStore::setFlagTrue("/Users/pascal/Galaxy/2020-DataBank/Catalyst/Data/TodoFolders/KV-Store", "a9de7bc6-e328-4ac6-b44a-3e745c87052f:#{objectuuid}:#{NSXMiscUtils::currentDay()}")
    end

    # NSXTodoFolders::addObjectToCalendarFileTopHalf(objectuuid)
    def self.addObjectToCalendarFileTopHalf(objectuuid)
        object = NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
        return if object.nil?
        NSXLucilleCalendarFileUtils::injectNewLineInPart1OfTheFile("[] #{NSX1ContentsItemUtils::contentItemToBody(object["contentItem"])}")
    end

end
