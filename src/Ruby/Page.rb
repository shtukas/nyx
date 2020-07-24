
# encoding: UTF-8

class Page

    # Page::make(textid, text)
    def self.make(textid, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "ab01a47c-bb91-4a15-93f5-b98cd3eb1866",
            "unixtime"  => Time.new.to_f,
            "textid"    => textid,
            "namedhash" => namedhash
        }
    end

    # Page::issue(textid, text)
    def self.issue(textid, text)
        text = Page::make(textid, text)
        NyxObjects::put(text)
        text
    end

    # Page::getPageForIdOrderedByTime(textid)
    def self.getPageForIdOrderedByTime(textid)
        NyxObjects::getSet("ab01a47c-bb91-4a15-93f5-b98cd3eb1866")
            .select{|note| note["textid"] == textid }
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Page::getMostRecentTextForIdOrNull(textid)
    def self.getMostRecentTextForIdOrNull(textid)
        texts = Page::getPageForIdOrderedByTime(textid)
        return nil if texts.empty?
        NyxBlobs::getBlobOrNull(texts.last["namedhash"])
    end

    # Page::issueNewTextWithNewId()
    def self.issueNewTextWithNewId()
        textid = SecureRandom.uuid
        text = Miscellaneous::editTextUsingTextmate("")
        Page::make(textid, text)
    end
end
