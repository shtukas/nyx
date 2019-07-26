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

DAY_NOTES_DATA_FILE_PATH = "/Users/pascal/Desktop/Today.txt"

$SECTION_UUID_TO_CATALYST_UUIDS = nil

class NSXAgentTodayNotes

    # NSXAgentTodayNotes::sectionUUIDToCatalystUUID(sectionuuid)
    def self.sectionUUIDToCatalystUUID(sectionuuid)
        if $SECTION_UUID_TO_CATALYST_UUIDS.nil? then
            $SECTION_UUID_TO_CATALYST_UUIDS = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/TodayNotes/uuids.json"))
        end
        if $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid] then
            $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid]
        else
            catalystuuid = SecureRandom.hex(4)
            $SECTION_UUID_TO_CATALYST_UUIDS[sectionuuid] = catalystuuid
            File.open("/Galaxy/DataBank/Catalyst/Agents-Data/TodayNotes/uuids.json", 'w'){|f| f.puts(JSON.pretty_generate($SECTION_UUID_TO_CATALYST_UUIDS)) }
            catalystuuid
        end
    end

    # NSXAgentTodayNotes::processSectionUUIDs(currentSectionuuids)
    def self.processSectionUUIDs(currentSectionuuids)
        $SECTION_UUID_TO_CATALYST_UUIDS.keys.each{|sectionuuid|
            if !currentSectionuuids.include?(sectionuuid) then
                # This section uuid in the dataset but not in the current sectionuuids
                $SECTION_UUID_TO_CATALYST_UUIDS.delete(sectionuuid)
                File.open("/Galaxy/DataBank/Catalyst/Agents-Data/TodayNotes/uuids.json", 'w'){|f| f.puts(JSON.pretty_generate($SECTION_UUID_TO_CATALYST_UUIDS)) }
            end
        }
    end

    # NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(uuid)
    def self.reWriteTodayFileWithoutThisSectionUUID(uuid)
        NSXMiscUtils::copyLocationToCatalystBin(DAY_NOTES_DATA_FILE_PATH)
        filecontents1 = IO.read(DAY_NOTES_DATA_FILE_PATH)
        sections1 = SectionsType2102::contents_to_sections(filecontents1.lines.to_a,[])
        sections2 = sections1.reject{|section| SectionsType2102::section_to_uuid(section)==uuid }
        filecontents2 = sections2.map{|section| section.join() }.join()
        File.open(DAY_NOTES_DATA_FILE_PATH, "w") { |io| io.puts(filecontents2) }
    end

    # NSXAgentTodayNotes::agentuuid()
    def self.agentuuid()
        "f7b21eb4-c249-4f0a-a1b0-d5d584c03316"
    end

    # NSXAgentTodayNotes::removeStartingMarker(str)
    def self.removeStartingMarker(str)
        if str.start_with?("[]") then
            str = str[2, str.size].strip
        end
        str
    end

    # NSXAgentTodayNotes::getObjects()
    def self.getObjects()
        NSXAgentTodayNotes::getAllObjects()
    end

    # NSXAgentTodayNotes::processStringForAnnounce(str)
    def self.processStringForAnnounce(str)
        str = str.strip
        if str.start_with?("[]") then
            str = str[2,str.size]
            return NSXAgentTodayNotes::processStringForAnnounce(str)
        end
        str
    end

    # NSXAgentTodayNotes::getAllObjects()
    def self.getAllObjects()
        sectionuuids = []
        integers = LucilleCore::integerEnumerator()
        sections = SectionsType2102::contents_to_sections(IO.read(DAY_NOTES_DATA_FILE_PATH).lines.to_a,[])
        sections = sections.take_while{|section| !section[0].include?("ee25043d-c12a-4e80-9d0a-fa70aff4dd00") }
        objects = sections
            .map{|section|
                sectionuuid = SectionsType2102::section_to_uuid(section)
                sectionuuids << sectionuuid
                uuid = NSXAgentTodayNotes::sectionUUIDToCatalystUUID(sectionuuid)
                if NSXRunner::isRunning?(uuid) and NSXRunner::runningTimeOrNull(uuid)>=1200 then
                end
                runningMarker = ""
                if NSXRunner::isRunning?(uuid) then
                    runningMarker = " (running for #{(NSXRunner::runningTimeOrNull(uuid).to_f/60).round(2)} minutes)"
                end
                sectionAsString = SectionsType2102::section_to_string(section)
                if sectionAsString.lines.size == 1 then
                    sectionAsString = NSXAgentTodayNotes::removeStartingMarker(sectionAsString)
                else
                    sectionAsString = "\n" + sectionAsString
                end
                {
                    "uuid"               => uuid,
                    "agentuid"           => NSXAgentTodayNotes::agentuuid(),
                    "metric"             => NSXRunner::isRunning?(uuid) ? 2 : (0.88 - integers.next().to_f/1000),
                    "announce"           => "Today: #{NSXAgentTodayNotes::processStringForAnnounce(sectionAsString).lines.first}#{runningMarker}",
                    "body"               => "Today: #{NSXAgentTodayNotes::processStringForAnnounce(sectionAsString)}#{runningMarker}",
                    "commands"           => ["done", ">stream"],
                    "defaultExpression"  => "done",
                    "section-uuid"       => SectionsType2102::section_to_uuid(section),
                    "section"            => section
                }
            }
        NSXAgentTodayNotes::processSectionUUIDs(sectionuuids)
        objects
    end

    # NSXAgentTodayNotes::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "done" then
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
            return
        end
        if command == ">stream" then
            text = object["section"].join()
            genericContentsItem = NSXGenericContents::issueItemText(text)
            streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
            streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
            ordinal = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
            streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, ordinal)
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
            return
        end
    end
end
