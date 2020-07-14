
# encoding: UTF-8

class Comments

    # Comments::make(targetuuid, author: null or String, text)
    def self.make(targetuuid, author, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "7e99bb92-098d-4f84-a680-f158126aa3bf",
            "unixtime"    => Time.new.to_f,
            "author"      => author,
            "targetuuid"  => targetuuid,
            "namedhash"   => namedhash
        }
    end

    # Comments::issue(targetuuid, author: null or String, text)
    def self.issue(targetuuid, author, text)
        object = Comments::make(targetuuid, author, text)
        NyxObjects::put(object)
        object
    end

    # Comments::getCommentsForTargetInTimeOrder(targetuuid)
    def self.getCommentsForTargetInTimeOrder(targetuuid)
        NyxObjects::getSet("7e99bb92-098d-4f84-a680-f158126aa3bf")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Comments::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
