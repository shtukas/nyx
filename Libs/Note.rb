
class Note

    # ------------------------------------
    # Makers

    # Note::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()
        text = CommonUtils::editTextSynchronously("")
        {
            "uuid"     => SecureRandom.uuid,
            "datetime" => Time.new.utc.iso8601,
            "text"     => text
        }
    end

    # ------------------------------------
    # Data

    # Note::toString(note)
    def self.toString(note)
        lines = note["text"].strip.lines
        if lines.empty? then
            return "(empty note)"
        end
        "(note) #{lines.first}"
    end

    # ------------------------------------
    # Operations

    # Note::program(note)
    def self.program(note)
        loop {
            puts "--------------------------------------"
            puts note["text"]
            puts "--------------------------------------"

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["edit"])
            return if action.nil?
            if action == "edit" then
                puts "Note edit is not yet impemented"
                LucilleCore::pressEnterToContinue()
            end
        }
        nil
    end
end
