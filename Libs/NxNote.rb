
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
end
