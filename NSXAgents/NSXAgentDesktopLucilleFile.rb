#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/SectionsType2102.rb"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------------------------------

LUCILLE_DATA_FILE_PATH = "/Users/pascal/Desktop/#{NSXMiscUtils::instanceName()}.txt"
LUCILLE_FILE_AGENT_DATA_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/DesktopLucilleFile"

$SECTION_UUID_TO_CATALYST_UUIDS = nil

class LucilleFileHelper

    # LucilleFileHelper::getSectionsFromDisk()
    def self.getSectionsFromDisk()
        filecontents = IO.read(LUCILLE_DATA_FILE_PATH)
        SectionsType2102::contents_to_sections(filecontents.lines.to_a,[])
    end

    # LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(uuid)
    def self.reWriteLucilleFileWithoutThisSectionUUID(uuid)
        NSXMiscUtils::copyLocationToCatalystBin(LUCILLE_DATA_FILE_PATH)
        filecontents = IO.read(LUCILLE_DATA_FILE_PATH)
        sections1 = SectionsType2102::contents_to_sections(filecontents.lines.to_a,[])
        sections2 = sections1.reject{|section| SectionsType2102::section_to_uuid(section)==uuid }
        filecontents = sections2.map{|section| section.join() }.join()
        File.open(LUCILLE_DATA_FILE_PATH, "w") { |io| io.puts(filecontents) }
    end

end

class NSXAgentDesktopLucilleFile

    # NSXAgentDesktopLucilleFile::sectionUUIDToCatalystUUID(sectionuuid)
    def self.sectionUUIDToCatalystUUID(sectionuuid)
        if $SECTION_UUID_TO_CATALYST_UUIDS.nil? then
            $SECTION_UUID_TO_CATALYST_UUIDS = JSON.parse(IO.read("#{LUCILLE_FILE_AGENT_DATA_FOLDERPATH}/uuids.json"))
        end
        if $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid] then
            $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid]
        else
            catalystuuid = SecureRandom.hex(4)
            $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid] = catalystuuid
            File.open("#{LUCILLE_FILE_AGENT_DATA_FOLDERPATH}/uuids.json", 'w'){|f| f.puts(JSON.pretty_generate($SECTION_UUID_TO_CATALYST_UUIDS)) }
            catalystuuid
        end
    end

    # NSXAgentDesktopLucilleFile::processSectionUUIDs(currentSectionuuids)
    def self.processSectionUUIDs(currentSectionuuids)
        $SECTION_UUID_TO_CATALYST_UUIDS.keys.each{|sectionuuid|
            if !currentSectionuuids.include?(sectionuuid) then
                # This section uuid in the dataset but not in the current sectionuuids
                $SECTION_UUID_TO_CATALYST_UUIDS.delete(sectionuuid)
                File.open("#{LUCILLE_FILE_AGENT_DATA_FOLDERPATH}/uuids.json", 'w'){|f| f.puts(JSON.pretty_generate($SECTION_UUID_TO_CATALYST_UUIDS)) }
            end
        }
    end

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

    # NSXAgentDesktopLucilleFile::processStringForAnnounce(str)
    def self.processStringForAnnounce(str)
        str = str.strip
        if str.start_with?("[]") then
            str = str[2,str.size]
            return NSXAgentDesktopLucilleFile::processStringForAnnounce(str)
        end
        str
    end

    # NSXAgentDesktopLucilleFile::getAllObjects()
    def self.getAllObjects()
        sectionuuids = []
        integers = LucilleCore::integerEnumerator()
        sections = LucilleFileHelper::getSectionsFromDisk()
        objects = sections
            .map{|section|
                sectionuuid = SectionsType2102::section_to_uuid(section)
                sectionuuids << sectionuuid
                uuid = NSXAgentDesktopLucilleFile::sectionUUIDToCatalystUUID(sectionuuid)
                if NSXRunner::isRunning?(uuid) and NSXRunner::runningTimeOrNull(uuid)>=1200 then
                end
                runningMarker = ""
                if NSXRunner::isRunning?(uuid) then
                    runningMarker = " (running for #{(NSXRunner::runningTimeOrNull(uuid).to_f/60).round(2)} minutes)"
                end
                sectionAsString = SectionsType2102::section_to_string(section)
                if sectionAsString.lines.size == 1 then
                    sectionAsString = NSXAgentDesktopLucilleFile::removeStartingMarker(sectionAsString)
                else
                    sectionAsString = "\n" + sectionAsString
                end
                announce = "Today: #{NSXAgentDesktopLucilleFile::processStringForAnnounce(sectionAsString).lines.first}#{runningMarker}"
                body = "Today: #{NSXAgentDesktopLucilleFile::processStringForAnnounce(sectionAsString)}#{runningMarker}"
                contentStoreItem = {
                    "type" => "line-and-body",
                    "line" => announce,
                    "body" => body
                }
                NSXContentStore::setItem(uuid, contentStoreItem)
                scheduleStoreItem = {
                    "type" => "todo-and-inform-agent-11b30518"
                }
                NSXScheduleStore::setItem(uuid, scheduleStoreItem)
                {
                    "uuid"               => uuid,
                    "agentuid"           => NSXAgentDesktopLucilleFile::agentuid(),
                    "metric"             => NSXRunner::isRunning?(uuid) ? 2 : (0.84 - integers.next().to_f/1000),
                    "contentStoreItemId"  => uuid,
                    "scheduleStoreItemId" => uuid,
                    "defaultCommand"     => "done",
                    "section-uuid"       => SectionsType2102::section_to_uuid(section),
                    "section"            => section
                }
            }
        NSXAgentDesktopLucilleFile::processSectionUUIDs(sectionuuids)
        objects
    end

    def self.getCommands()
        [">stream"]
    end

    # NSXAgentDesktopLucilleFile::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "done" then
            object = NSXAgentDesktopLucilleFile::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(object["section-uuid"])
            if isLocalCommand then
                NSXMultiInstancesWrite::issueEventCommand(objectuuid, NSXAgentDesktopLucilleFile::agentuid(), "done")
            end
            return
        end
        if command == ">stream" then
            object = NSXAgentDesktopLucilleFile::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            text = object["section"].join()
            genericContentsItem = NSXGenericContents::issueItemText(text)
            streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
            streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
            ordinal = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
            streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, ordinal)
            LucilleFileHelper::reWriteLucilleFileWithoutThisSectionUUID(object["section-uuid"])
            return
        end
    end
end
