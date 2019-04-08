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

# -------------------------------------------------------------------------------------

DAY_NOTES_DATA_FILE_PATH = "/Users/pascal/Desktop/Today.txt"

class NSXAgentTodayNotes

    # NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(uuid)
    def self.reWriteTodayFileWithoutThisSectionUUID(uuid)
        NSXMiscUtils::copyLocationToCatalystBin(DAY_NOTES_DATA_FILE_PATH)
        filecontents1 = IO.read(DAY_NOTES_DATA_FILE_PATH)
        sections1 = SectionsType2102::contents_to_sections(filecontents1.lines.to_a,[])
        sections2 = sections1.reject{|section| SectionsType2102::section_to_uuid(section)==uuid }
        filecontents2 = sections2.map{|section| section.join() }.join()
        File.open(DAY_NOTES_DATA_FILE_PATH, "w") { |io| io.puts(filecontents2)  }
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
        integers = LucilleCore::integerEnumerator()
        sections = SectionsType2102::contents_to_sections(IO.read(DAY_NOTES_DATA_FILE_PATH).lines.to_a,[])
        sections = sections.take_while{|section| !section[0].include?("ee25043d-c12a-4e80-9d0a-fa70aff4dd00") }
        sections
            .map{|section|
                uuid = "#{SectionsType2102::section_to_uuid(section)}-#{NSXMiscUtils::currentDay()}"
                if NSXRunner::isRunning?(uuid) and NSXRunner::runningTimeOrNull(uuid)>=1200 then
                    NSXMiscUtils::onScreenNotification("Catalyst", "Today item running by more than 20 minutes")
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
                    "prioritization"     => NSXRunner::isRunning?(uuid) ? "running" : "standard",
                    "metric"             => NSXRunner::isRunning?(uuid) ? 2 : (0.65 - integers.next().to_f/1000),
                    "announce"           => "Today: #{sectionAsString.lines.first}#{runningMarker}",
                    "body"               => "Today: #{sectionAsString}#{runningMarker}",
                    "commands"           => ["done", ">stream"],
                    "defaultExpression"  => "done",
                    "section-uuid"       => SectionsType2102::section_to_uuid(section),
                    "section"            => section
                }
            }
            .map{|object| NSXMiscUtils::catalystObjectToObjectOrPrioritizedObjectOrNilIfDoNotShowUntil(object) }
            .compact
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # NSXAgentTodayNotes::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "done" then
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
        end
        if command == ">stream" then
            text = object["section"].join()
            genericContentsItem = NSXGenericContents::issueItemText(text)
            streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
            streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
            streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, Time.new.to_f)
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
        end
    end
end
