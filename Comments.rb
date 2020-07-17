
# encoding: UTF-8

class Comments

    # Comments::make(text)
    def self.make(text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "7e99bb92-098d-4f84-a680-f158126aa3bf",
            "unixtime"    => Time.new.to_f,
            "namedhash"   => namedhash
        }
    end

    # Comments::issue(text)
    def self.issue(text)
        object = Comments::make(text)
        NyxObjects::put(object)
        object
    end

    # Comments::comments()
    def self.comments()
        NyxObjects::getSet("7e99bb92-098d-4f84-a680-f158126aa3bf")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Comments::getCommentsForSourceInTimeOrder(source)
    def self.getCommentsForSourceInTimeOrder(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["7e99bb92-098d-4f84-a680-f158126aa3bf"])
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Comments::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
