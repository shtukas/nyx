#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/SectionsType2102.rb"

# -------------------------------------------------------------------------------------

DAY_NOTES_DATA_FILE_PATH = "/Users/pascal/Desktop/Today.txt"

class NSXAgentTodayNotes

    # NSXAgentTodayNotes::agentuuid()
    def self.agentuuid()
        "f7b21eb4-c249-4f0a-a1b0-d5d584c03316"
    end

    def self.getObjects()
        integers = LucilleCore::integerEnumerator()
        sections = SectionsType2102::contents_to_sections(IO.read(DAY_NOTES_DATA_FILE_PATH).lines.to_a,[])
        sections.map{|section|
            # section: Array[String]
            {
                "uuid"               => SectionsType2102::section_to_uuid(section),
                "agent-uid"          => NSXAgentTodayNotes::agentuuid(),
                "metric"             => 0.95 - integers.next().to_f/1000,
                "announce"           => SectionsType2102::section_to_string(section),
                "commands"           => [],
                "default-expression" => nil,
                "is-running"         => false,
                "commands-lambdas"   => nil
            }
        }
    end

    def self.processObjectAndCommand(object, command)
        if command == "" then

        end
    end

    def self.interface()

    end

end
