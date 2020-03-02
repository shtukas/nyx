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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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
        folderpath = "/Users/pascal/Galaxy/Todo/#{foldername}"
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
        Dir.entries("/Users/pascal/Galaxy/Todo")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .select{|filename| filename != "Z-Todo-HowTo.txt" }
            .sort
    end

    # NSXTodoFolders::getFolderuuids()
    def self.getFolderuuids()
        NSXTodoFolders::getFoldernames().map{|foldername| NSXTodoFolders::foldernameToFolderuuid(foldername) }
    end

    # NSXTodoFolders::getTodoRootFileContents(foldername)
    def self.getTodoRootFileContents(foldername)
        folderpath = "/Users/pascal/Galaxy/Todo/#{foldername}"
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

    # NSXTodoFolders::getNextFileIndexInFolder(foldername)
    def self.getNextFileIndexInFolder(foldername)
        i1 = Dir.entries("/Users/pascal/Galaxy/Todo/#{foldername}")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .map{|filename| filename[0,3].to_i }
        [(i1 + [0]).max, 100].max
    end

    # --------------------------------------------------------------
    # Ordinal Base

    # NSXTodoFolders::foldernameToOrdinalBase(foldername)
    def self.foldernameToOrdinalBase(foldername)
        folderpath = "/Users/pascal/Galaxy/Todo/#{foldername}"
        filepath = "#{folderpath}/.ordinal-base-8c9268ed"
        if !File.exists?(filepath) then
            File.open(filepath, "w"){|f| f.puts("0") }
        end
        IO.read(filepath).strip.to_i
    end

    # NSXTodoFolders::increaseFolderOrdinalBase(foldername)
    def self.increaseFolderOrdinalBase(foldername)
        ordinalBase = NSXTodoFolders::foldernameToOrdinalBase(foldername)
        folderpath = "/Users/pascal/Galaxy/Todo/#{foldername}"
        filepath = "#{folderpath}/.ordinal-base-8c9268ed"
        File.open(filepath, "w"){|f| f.puts(ordinalBase+1) }
    end

    # --------------------------------------------------------------
    # Catalyst Objects

    # NSXTodoFolders::runningTimeAsString(objectuuid)
    def self.runningTimeAsString(objectuuid)
        runningTime = NSXRunner::runningTimeOrNull(objectuuid)
        return "" if runningTime.nil?
        "running for #{(runningTime.to_f/60).to_i} minutes"
    end

    # NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid)
    def self.folderUUIDToCatalystObjects(folderuuid)
        foldername = NSXTodoFolders::folderUUIDToFoldernameOrNull(folderuuid)

        ordinalBase = NSXTodoFolders::foldernameToOrdinalBase(foldername)

        itemsInFolder = Dir.entries("/Users/pascal/Galaxy/Todo/#{foldername}")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .sort

        itemCounter = 0

        itemsInFolder
        .map{|filename|
            typeProfile = NSXTodoItemsTypes::determineTypeProfile(foldername, filename)
            itemCounter = itemCounter + 1
            objectuuid = Digest::SHA1.hexdigest("#{folderuuid}/#{filename}")
            isRunning = NSXRunner::isRunning?(objectuuid)
            runningAsTimeStringOrNull = isRunning ? NSXTodoFolders::runningTimeAsString(objectuuid) : nil
            contentItem = NSXTodoItemsTypes::typeProfileToContentItem(typeProfile, runningAsTimeStringOrNull)
            {
                "uuid"           => objectuuid,
                "agentuid"       => "09cc9943-1fa0-45a4-8d22-a37e0c4ddf0c",
                "contentItem"    => contentItem,
                "metric"         => NSXStreamTodoFoldersCommon::metric1(ordinalBase+itemCounter, nil, NSXRunTimes::getPoints(folderuuid), isRunning),
                "commands"       => NSXTodoItemsTypes::typeProfileToCommands(typeProfile, isRunning),
                "defaultCommand" => isRunning ? "stop" : "start",
                "isRunning"      => isRunning,
                "x-folderuuid"   => folderuuid,
                "x-typeProfile"  => typeProfile
            }
        }
    end

    # NSXTodoFolders::catalystObjects()
    def self.catalystObjects()
        NSXTodoFolders::getFolderuuids()
            .map{|folderuuid| NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid) }
            .flatten
    end

    # NSXTodoFolders::catalystObjectsForListing()
    def self.catalystObjectsForListing()
        NSXTodoFolders::getFolderuuids()
            .map{|folderuuid| 
                NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid) 
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
                    .select{|object|
                        b1 = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil?
                        b2 = object["isRunning"]
                        b1 or b2
                    }
            }
            .flatten
    end

    # NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXTodoFolders::catalystObjects().select{|object| object["uuid"] == objectuuid }.first
    end

end
