
# encoding: UTF-8

=begin
{
    "uuid"         : String
    "mikuType"     : "TxZoneItem"
    "unixtime"     : Float
    "description"  : String
}
=end

class Zone # Zone is entirely contained in XCache, for extra fun

    # Zone::items()
    def self.items()
        XCacheSets::values("5cd02e58-fcc5-482a-9549-9bc812f9d59b")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Zone::destroy(item)
    def self.destroy(item)
        XCacheSets::destroy("5cd02e58-fcc5-482a-9549-9bc812f9d59b", item["uuid"])
    end

    # Zone::toString(item)
    def self.toString(item)
        "(zone) #{item["description"]}"
    end

    # Zone::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i

        item = {
          "uuid"         => uuid,
          "mikuType"     => "TxZoneItem",
          "unixtime"     => unixtime,
          "description"  => description
        }
        XCacheSets::set("5cd02e58-fcc5-482a-9549-9bc812f9d59b", uuid, item)
        item
    end

    # Zone::access(item)
    def self.access(item)
        puts item["description"].green
        if LucilleCore::askQuestionAnswerAsBoolean("done ? : ", true) then
            XCacheSets::destroy("5cd02e58-fcc5-482a-9549-9bc812f9d59b", item["uuid"])
            NxBallsService::close(item["uuid"], true)
        end
    end
end
