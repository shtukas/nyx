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

    # --------------------------------------------------------------
    # Catalyst Objects

    # NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid, indx)
    def self.folderUUIDToCatalystObjects(folderuuid, indx)
        foldername = NSXTodoFolders::folderUUIDToFoldernameOrNull(folderuuid)

        itemsInFolder = Dir.entries("/Users/pascal/Galaxy/2020-Todo/#{foldername}")
            .select{|filename| filename[0,1] != "." }
            .select{|filename| !filename.start_with?("Icon") }
            .sort

        counter = 0

        objects = itemsInFolder.map{|filename|
            counter = counter + 1
            objectuuid = Digest::SHA1.hexdigest("#{folderuuid}/#{filename}")
            {
                "uuid"           => objectuuid,
                "agentuid"       => "09cc9943-1fa0-45a4-8d22-a37e0c4ddf0c",
                "contentItem"    => {
                    "type" => "line",
                    "line" => "[2020-Todo] #{foldername} / #{filename}"
                },
                "metric"         => 0.70 + Math.exp(-indx).to_f/100 + Math.exp(-counter).to_f/1000,
                "commands"       => ["reviewed", "inject"],
                "defaultCommand" => "reviewed",
                "isDone"         => false
            }
        }

        if objects.size == 0 then
            objectuuid = folderuuid
            objects << {
                "uuid"           => objectuuid,
                "agentuid"       => "09cc9943-1fa0-45a4-8d22-a37e0c4ddf0c",
                "contentItem"    => {
                    "type" => "line",
                    "line" => "[2020-Todo] #{foldername} [folder]"
                },
                "metric"         => 0.70 + Math.exp(-indx).to_f/100,
                "commands"       => ["reviewed", "inject"],
                "defaultCommand" => "reviewed",
                "isDone"         => false
            }
        end

        objects
    end

    # NSXTodoFolders::catalystObjects()
    def self.catalystObjects()
        counter = 0
        NSXTodoFolders::getFolderuuids().map{|folderuuid|
            counter = counter + 1
            NSXTodoFolders::folderUUIDToCatalystObjects(folderuuid, counter)
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
