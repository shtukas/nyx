
# encoding: UTF-8

class NxNotes

    # ------------------------------------
    # Makers

    # NxNotes::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()
        text = CommonUtils::editTextSynchronously("")
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxNote",
            "unixtime" => Time.new.to_i,
            "text"     => text
        }
    end

    # ------------------------------------
    # Data

    # NxNotes::toString(note)
    def self.toString(note)
        lines = note["text"].strip.lines
        if lines.empty? then
            return "(empty note)"
        end
        "(note) #{lines.first}"
    end

    # ------------------------------------
    # Operations

    # NxNotes::program(note)
    def self.program(note)
        loop {
            system('clear')

            puts "--------------------------------------"
            puts note["text"]
            puts "--------------------------------------"

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["edit"])
            return if action.nil?
            if action == "edit" then
                puts "edit is actually not yet impemented"
                LucilleCore::pressEnterToContinue()
            end
        }
        nil
    end
end
