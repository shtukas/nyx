#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
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

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/SectionsType0141.rb"
# SectionsType0141::contentToSections(reminaingLines: Array[String])

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# -------------------------------------------------------------------------------------

LUCILLE_DATA_FILE_PATH = "/Users/pascal/Desktop/#{NSXMiscUtils::instanceName()}.txt"
LUCILLE_FILE_AGENT_DATA_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/DesktopLucilleFile"
LUCILLE_FILE_MARKER = "@marker-539d469a-8521-4460-9bc4-5fb65da3cd4b"

$SECTION_UUID_TO_CATALYST_UUIDS = nil

class LucilleFileHelper

    # LucilleFileHelper::sectionToSectionUUID(section)
    def self.sectionToSectionUUID(section)
        Digest::SHA1.hexdigest(section)[0, 8]
    end

    # LucilleFileHelper::fileContentsToStruct1(content) : [Part, Part]
    def self.fileContentsToStruct1(content)
        content.split(LUCILLE_FILE_MARKER)
    end

    # LucilleFileHelper::fileContentsToStruct2(content) : [Array[Section], Array[Section]]
    def self.fileContentsToStruct2(content)
        LucilleFileHelper::fileContentsToStruct1(content).map{|part|
            SectionsType0141::contentToSections(part.lines.to_a)
        }
    end

    # LucilleFileHelper::struct2ToFileContent(struct2)
    def self.struct2ToFileContent(struct2)
        [
            struct2[0].join().strip,
            "\n\n",
            LUCILLE_FILE_MARKER,
            "\n\n",
            struct2[1].join().strip
        ].join()
    end

    # LucilleFileHelper::commitStruct2ToDisk(struct2)
    def self.commitStruct2ToDisk(struct2)
        File.open(LUCILLE_DATA_FILE_PATH, "w") { |io| io.puts(LucilleFileHelper::struct2ToFileContent(struct2)) }
    end

    # LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(uuid)
    def self.reWriteLucilleFileWithoutThisSectionUUID(uuid)
        NSXMiscUtils::copyLocationToCatalystBin(LUCILLE_DATA_FILE_PATH)
        content = IO.read(LUCILLE_DATA_FILE_PATH)
        struct2 = LucilleFileHelper::fileContentsToStruct2(content)
        struct2 = struct2.map{|sections|
            sections.reject{|section|
                LucilleFileHelper::sectionToSectionUUID(section) == uuid
            }
        }
        LucilleFileHelper::commitStruct2ToDisk(struct2)
    end

    # LucilleFileHelper::applyNextTransformationToContent(content)
    def self.applyNextTransformationToContent(content)
        lines = content.strip.lines.to_a
        return content if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if selectedLineWithIndex.first.index("[]") and cursorLineWithIndex.first.index("[]") and (selectedLineWithIndex.first.index("[]") < cursorLineWithIndex.first.index("[]")) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end

    # LucilleFileHelper::applyNextTransformationToStruct2(struct2)
    def self.applyNextTransformationToStruct2(struct2)
        return struct2 if struct2[0].empty?
        struct2[0][0] = LucilleFileHelper::applyNextTransformationToContent(struct2[0][0])
        struct2
    end

    # LucilleFileHelper::applyNextTransformationToLucilleFile()
    def self.applyNextTransformationToLucilleFile()
        NSXMiscUtils::copyLocationToCatalystBin(LUCILLE_DATA_FILE_PATH)
        struct2 = LucilleFileHelper::fileContentsToStruct2(IO.read(LUCILLE_DATA_FILE_PATH))
        struct2 = LucilleFileHelper::applyNextTransformationToStruct2(struct2)
        LucilleFileHelper::commitStruct2ToDisk(struct2)
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
        integers = LucilleCore::integerEnumerator()
        struct2 = LucilleFileHelper::fileContentsToStruct2(IO.read(LUCILLE_DATA_FILE_PATH))
        objects = (struct2[0]+struct2[1])
                    .map{|section|
                        uuid = LucilleFileHelper::sectionToSectionUUID(section)
                        if NSXRunner::isRunning?(uuid) and NSXRunner::runningTimeOrNull(uuid)>=1200 then
                        end
                        contentStoreItem = {
                            "type" => "line-and-body",
                            "line" => "Lucille: #{section.strip.lines.first}",
                            "body" => "Lucille:\n#{section.strip}"
                        }
                        NSXContentStore::setItem(uuid, contentStoreItem)
                        scheduleStoreItem = {
                            "type" => "todo-and-inform-agent-11b30518",
                            "metric" => NSXRunner::isRunning?(uuid) ? 2 : (0.84 - integers.next().to_f/1000),
                        }
                        NSXScheduleStore::setItem(uuid, scheduleStoreItem)
                        {
                            "uuid"                => uuid,
                            "agentuid"            => NSXAgentDesktopLucilleFile::agentuid(),
                            "contentStoreItemId"  => uuid,
                            "scheduleStoreItemId" => uuid,
                            "section"             => section
                        }
                    }
        objects
    end

    def self.getCommands()
        [">stream"]
    end

    # NSXAgentDesktopLucilleFile::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "done" then
            LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
        if command == ">stream" then
            object = NSXAgentDesktopLucilleFile::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            genericContentsItem = NSXGenericContents::issueItemText(object["section"])
            streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
            streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
            ordinal = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
            streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, ordinal)
            LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(objectuuid)
            return
        end
    end
end
