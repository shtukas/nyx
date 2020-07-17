
# encoding: UTF-8

class Notes

    # Notes::make(text)
    def self.make(text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "c6fad718-1306-49cf-a361-76ce85e909ca",
            "unixtime"   => Time.new.to_f,
            "namedhash"  => namedhash
        }
    end

    # Notes::issue(text)
    def self.issue(text)
        note = Notes::make(targetuuid, text)
        NyxObjects::put(note)
        note
    end

    # Notes::notes()
    def self.notes()
        NyxObjects::getSet("c6fad718-1306-49cf-a361-76ce85e909ca")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Notes::getNotesForSourceInTimeOrder(source)
    def self.getNotesForSourceInTimeOrder(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["c6fad718-1306-49cf-a361-76ce85e909ca"])
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Notes::getMostRecentTextForSourceOrNull(source)
    def self.getMostRecentTextForSourceOrNull(source)
        notes = Notes::getNotesForSourceInTimeOrder(source)
        return nil if notes.empty?
        note = notes.last
        NyxBlobs::getBlobOrNull(note["namedhash"])
    end
end
