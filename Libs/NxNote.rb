
class NxNote

    # ------------------------------------
    # Makers

    # NxNote::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()
        text = CommonUtils::editTextSynchronously("").strip
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxNote",
            "unixtime" => Time.new.to_i,
            "text"     => text
        }
    end

    # ------------------------------------
    # Data

    # NxNote::toString(note)
    def self.toString(note)
        lines = note["text"].strip.lines
        if lines.empty? then
            return "(empty note)"
        end
        "(note) #{lines.first}"
    end

    # ------------------------------------
    # Operations

    # NxNote::program(note)
    def self.program(note)
        loop {
            system('clear')

            puts "--------------------------------------"
            puts note["text"]
            puts "--------------------------------------"

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["edit"])
            return if action.nil?
            if action == "edit" then
                puts "NxNote edit is not yet impemented"
                LucilleCore::pressEnterToContinue()
            end
        }
        nil
    end

    # NxNote::fsck(note)
    def self.fsck(note)
        if note["uuid"].nil? then
            raise "note: #{JSON.pretty_generate(note)} does not have a uuid"
        end
        if note["mikuType"].nil? then
            raise "note: #{JSON.pretty_generate(note)} does not have a mikuType"
        end
        if note["mikuType"] != 'NxNote' then
            raise "note: #{JSON.pretty_generate(note)} does not have the correct mikuType"
        end
        if note["unixtime"].nil? then
            raise "note: #{JSON.pretty_generate(note)} does not have a unixtime"
        end
        if note["text"].nil? then
            raise "note: #{JSON.pretty_generate(note)} does not have a text"
        end
    end
end
