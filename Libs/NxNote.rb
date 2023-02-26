
class NxNote

    # NxNote::makeNoteOrNull()
    def self.makeNoteOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        return nil if line == ""
        {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_i,
            "line"     => line
        }
    end

    # NxNote::landing(note)
    def self.landing(note)
        puts "NxNote::landing not implemented yet"
        LucilleCore::pressEnterToContinue() 
    end
end
