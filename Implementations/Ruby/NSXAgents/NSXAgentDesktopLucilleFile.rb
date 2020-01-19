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

LUCILLE_FILE_AGENT_DATA_FOLDERPATH = "#{CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/DesktopLucilleFile"
LUCILLE_FILE_MARKER = "@marker-539d469a-8521-4460-9bc4-5fb65da3cd4b"

$SECTION_UUID_TO_CATALYST_UUIDS = nil

class LucilleLocationUtils

    # LucilleLocationUtils::getThisInstanceLucilleFilename()
    def self.getThisInstanceLucilleFilename()
        "#{NSXMiscUtils::thisInstanceName()}-20191104-183028-425057.txt"
    end

    # LucilleLocationUtils::getThisInstanceLucilleFilepath()
    def self.getThisInstanceLucilleFilepath()
        "/Users/pascal/Desktop/#{LucilleLocationUtils::getThisInstanceLucilleFilename()}"
    end

    # LucilleLocationUtils::makeNewInstanceLucilleFilename(instanceName)
    def self.makeNewInstanceLucilleFilename(instanceName)
        "#{instanceName}-#{NSXMiscUtils::timeStringL22()}.txt"
    end

    # LucilleLocationUtils::makeNewInstanceLucilleFilepath(instanceName)
    def self.makeNewInstanceLucilleFilepath(instanceName)
        "/Users/pascal/Desktop/#{LucilleLocationUtils::makeNewInstanceLucilleFilename(instanceName)}"
    end

    # LucilleLocationUtils::getInstanceLucilleFilenames(instanceName)
    def self.getInstanceLucilleFilenames(instanceName)
        Dir.entries("/Users/pascal/Desktop")
            .reject{|filename| filename[0, 1] == "." }
            .select{|filename| filename.start_with?(instanceName) }
            .select{|filename| filename.size==36 }
            .select{|filename| filename[-4, 4] == ".txt" }
            .sort
    end

    # LucilleLocationUtils::getLucilleFilenames()
    def self.getLucilleFilenames()
        Dir.entries("/Users/pascal/Desktop")
            .reject{|filename| filename[0, 1] == "." }
            .select{|filename| filename.size==36 }
            .select{|filename| filename[-4, 4] == ".txt" }
            .sort
    end

    # LucilleLocationUtils::getLucilleFilepaths()
    def self.getLucilleFilepaths()
        LucilleLocationUtils::getLucilleFilenames()
            .map{|filename| "/Users/pascal/Desktop/#{filename}" }
    end

    # LucilleLocationUtils::getInstanceLucilleFilepaths(instanceName)
    def self.getInstanceLucilleFilepaths(instanceName)
        LucilleLocationUtils::getInstanceLucilleFilenames(instanceName)
            .map{|filename| "/Users/pascal/Desktop/#{filename}" }
    end

    # LucilleLocationUtils::getLastInstanceLucilleFilepath(instanceName)
    def self.getLastInstanceLucilleFilepath(instanceName)
        LucilleLocationUtils::getInstanceLucilleFilepaths(instanceName).last
    end

end

class LucilleFileUtils

    # LucilleFileUtils::sectionToSectionUUID(section)
    def self.sectionToSectionUUID(section)
        Digest::SHA1.hexdigest(section.strip)[0, 8]
    end

    # LucilleFileUtils::fileContentsToStruct1(content) : [Part, Part]
    def self.fileContentsToStruct1(content)
        content.split(LUCILLE_FILE_MARKER)
    end

    # LucilleFileUtils::fileContentsToStruct2(content) : [Array[Section], Part]
    def self.fileContentsToStruct2(content)
        parts = LucilleFileUtils::fileContentsToStruct1(content)
        [
            SectionsType0141::contentToSections(parts[0].lines.to_a),
            parts[1]
        ]
    end

    # LucilleFileUtils::struct2ToFileContent(struct2)
    def self.struct2ToFileContent(struct2)
        [
            struct2[0].map{|str| str.strip}.join("\n").strip,
            "\n\n",
            LUCILLE_FILE_MARKER,
            struct2[1]
        ].join()
    end

    # LucilleFileUtils::commitStruct2ToDiskAtFilepath(struct2)
    def self.commitStruct2ToDiskAtFilepath(struct2)
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        File.open(filepath, "w") { |io| io.puts(LucilleFileUtils::struct2ToFileContent(struct2)) }
    end

    # LucilleFileUtils::writeANewLucilleFileWithoutThisSectionUUID(uuid)
    def self.writeANewLucilleFileWithoutThisSectionUUID(uuid)
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        NSXMiscUtils::copyLocationToCatalystBin(filepath)
        struct2 = LucilleFileUtils::getStruct()
        struct2[0] = struct2[0].reject{|section|
            LucilleFileUtils::sectionToSectionUUID(section) == uuid
        }
        LucilleFileUtils::commitStruct2ToDiskAtFilepath(struct2)
    end

    # LucilleFileUtils::applyNextTransformationToStruct2(struct2)
    def self.applyNextTransformationToStruct2(struct2)
        return struct2 if struct2[0].empty?
        struct2[0][0] = NSXMiscUtils::applyNextTransformationToContent(struct2[0][0])
        struct2
    end

    # LucilleFileUtils::applyNextTransformationToLucilleFile()
    def self.applyNextTransformationToLucilleFile()
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        NSXMiscUtils::copyLocationToCatalystBin(filepath)
        struct2 = LucilleFileUtils::fileContentsToStruct2(IO.read(filepath))
        struct2 = LucilleFileUtils::applyNextTransformationToStruct2(struct2)
        LucilleFileUtils::commitStruct2ToDiskAtFilepath(struct2)
    end

    # LucilleFileUtils::getStruct()
    def self.getStruct()
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        LucilleFileUtils::fileContentsToStruct2(IO.read(filepath))
    end

end

class NSXAgentDesktopLucilleFile

    # NSXAgentDesktopLucilleFile::agentuid()
    def self.agentuid()
        "f7b21eb4-c249-4f0a-a1b0-d5d584c03316"
    end

    # NSXAgentDesktopLucilleFile::removeStartingMarker(str)
    def self.removeStartingMarker(str)
        if str.start_with?("[]") then
            str = str[2, str.size].strip
        end
        str
    end

    # NSXAgentDesktopLucilleFile::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentDesktopLucilleFile::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentDesktopLucilleFile::getObjects()
    def self.getObjects()
        NSXAgentDesktopLucilleFile::getAllObjects()
    end

    # NSXAgentDesktopLucilleFile::getAllObjects()
    def self.getAllObjects()
        return []
            # We are no longer generating Catalyst objects from the Lucille file (currently the Calendar)
            # The top of the Calendar is used for nexting in Catalyst
            # We keep the code for reference
        integers = LucilleCore::integerEnumerator()
        struct2 = LucilleFileUtils::getStruct()
        objects = struct2[1]
                    .map{|section|
                        uuid = LucilleFileUtils::sectionToSectionUUID(section)
                        contentItem = {
                            "type" => "line-and-body",
                            "line" => "Lucille: #{section.strip.lines.first}",
                            "body" => "Lucille:\n#{section.strip}"
                        }
                        {
                            "uuid"           => uuid,
                            "agentuid"       => NSXAgentDesktopLucilleFile::agentuid(),
                            "contentItem"    => contentItem,
                            "metric"         => NSXRunner::isRunning?(uuid) ? 2 : (0.75 - integers.next().to_f/1000),
                            "commands"       => ["done", ">infinity"],
                            "defaultCommand" => "done",
                            "section"        => section
                        }
                    }
        objects
    end

    # NSXAgentDesktopLucilleFile::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "done" then
            # The objectuuid is the sectionuuid, so there is not need to look the object up
            # to extract the sectionuuids
            LucilleFileUtils::writeANewLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
        if command == ">infinity" then
            object = NSXAgentDesktopLucilleFile::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            genericContentsItem = {
                "uuid" => SecureRandom.hex,
                "type" => "text",
                "text" => object["section"]
            }
            ordinal = NSXStreamsUtils::getNewStreamOrdinal()
            streamItem = NSXStreamsUtils::issueNewStreamItem(nil, genericContentsItem, ordinal)
            LucilleFileUtils::writeANewLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentDesktopLucilleFile",
            "agentuid"    => NSXAgentDesktopLucilleFile::agentuid(),
        }
    )
rescue
end
