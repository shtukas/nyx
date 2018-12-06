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
        sections.map{|section|
            # section: Array[String]
            uuid = SectionsType2102::section_to_uuid(section)
            {
                "uuid"               => uuid,
                "agent-uid"          => NSXAgentTodayNotes::agentuuid(),
                "metric"             => 0.95 - integers.next().to_f/1000,
                "announce"           => NSXAgentTodayNotes::removeStartingMarker(SectionsType2102::section_to_string(section)),
                "commands"           => ["done", ">stream"],
                "default-expression" => "done",
                "is-running"         => false,
                "commands-lambdas"   => nil,
                "section-uuid"       => SectionsType2102::section_to_uuid(section),
                "section"            => section
            }

        }.compact
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
        end
        if command == ">stream" then
            text = object["section"].join()
            genericContentsItem = NSXGenericContents::issueItemText(text)
            lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
            return if lightThread.nil?
            streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(lightThread["streamuuid"], genericContentsItem)
            NSXAgentTodayNotes::reWriteTodayFileWithoutThisSectionUUID(object["section-uuid"])
        end
    end

    def self.interface()

    end

end
