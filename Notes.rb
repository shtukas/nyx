
# encoding: UTF-8

class Notes

    # Notes::make(targetuuid, text)
    def self.make(targetuuid, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "c6fad718-1306-49cf-a361-76ce85e909ca",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "namedhash"  => namedhash
        }
    end

    # Notes::issue(targetuuid, text)
    def self.issue(targetuuid, text)
        note = Notes::make(targetuuid, text)
        NyxObjects::put(note)
        note
    end

    # Notes::getNotesForTargetOrderedByTime(targetuuid)
    def self.getNotesForTargetOrderedByTime(targetuuid)
        NyxObjects::getSet("c6fad718-1306-49cf-a361-76ce85e909ca")
            .select{|note| note["targetuuid"] == targetuuid }
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Notes::getMostRecentTextForTargetOrNull(targetuuid)
    def self.getMostRecentTextForTargetOrNull(targetuuid)
        notes = Notes::getNotesForTargetOrderedByTime(targetuuid)
        return nil if notes.empty?
        note = notes.last
        NyxBlobs::getBlobOrNull(note["namedhash"])
    end
end
