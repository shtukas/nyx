#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

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

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/SectionsType0141.rb"
# SectionsType0141::contentToSections(reminaingLines: Array[String])

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# -------------------------------------------------------------------------------------

# Struct2: [Array[Section], Array[Section]]

# -------------------------------------------------------------------------------------

LUCILLE_FILE_MARKER = "@marker-539d469a-8521-4460-9bc4-5fb65da3cd4b"

class NSXAgentLucilleCalendarFile

    # NSXAgentLucilleCalendarFile::agentuid()
    def self.agentuid()
        "f7b21eb4-c249-4f0a-a1b0-d5d584c03316"
    end

    # NSXAgentLucilleCalendarFile::removeStartingMarker(str)
    def self.removeStartingMarker(str)
        if str.start_with?("[]") then
            str = str[2, str.size].strip
        end
        str
    end

    # NSXAgentLucilleCalendarFile::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentLucilleCalendarFile::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentLucilleCalendarFile::getObjects()
    def self.getObjects()
        NSXAgentLucilleCalendarFile::getAllObjects()
    end

    # NSXAgentLucilleCalendarFile::getAllObjects()
    def self.getAllObjects()
        return []
            # We are no longer generating Catalyst objects from the Lucille file (currently the Calendar)
            # The top of the Calendar is used for nexting in Catalyst
            # We keep the code for reference
        integers = LucilleCore::integerEnumerator()
        struct2 = NSXLucilleCalendarFileUtils::getStruct()
        objects = struct2[1]
                    .map{|section|
                        uuid = NSXLucilleCalendarFileUtils::sectionToSectionUUID(section)
                        contentItem = {
                            "type" => "line-and-body",
                            "line" => "Lucille: #{section.strip.lines.first}",
                            "body" => "Lucille:\n#{section.strip}"
                        }
                        {
                            "uuid"           => uuid,
                            "agentuid"       => NSXAgentLucilleCalendarFile::agentuid(),
                            "contentItem"    => contentItem,
                            "metric"         => NSXRunner::isRunning?(uuid) ? 2 : (1 - integers.next().to_f/1000),
                            "commands"       => ["done", ">infinity"],
                            "defaultCommand" => "done",
                            "section"        => section
                        }
                    }
        objects
    end

    # NSXAgentLucilleCalendarFile::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "done" then
            # The objectuuid is the sectionuuid, so there is not need to look the object up
            # to extract the sectionuuids
            NSXLucilleCalendarFileUtils::writeANewLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
        if command == ">infinity" then
            object = NSXAgentLucilleCalendarFile::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            genericContentsItem = {
                "uuid" => SecureRandom.hex,
                "type" => "text",
                "text" => object["section"]
            }
            ordinal = NSXStreamsUtils::getNewStreamOrdinal()
            streamItem = NSXStreamsUtils::issueNewStreamItem(nil, genericContentsItem, ordinal)
            NSXLucilleCalendarFileUtils::writeANewLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentLucilleCalendarFile",
            "agentuid"    => NSXAgentLucilleCalendarFile::agentuid(),
        }
    )
rescue
end
