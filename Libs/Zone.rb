
# encoding: UTF-8

class Zone

    # Zone::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxZoneItem")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Zone::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # Zone::toString(item)
    def self.toString(item)
        "(zone) #{item["description"]}"
    end

    # Zone::issueNew(line)
    def self.issueNew(line)
        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i
        item = {
          "uuid"         => uuid,
          "mikuType"     => "TxZoneItem",
          "unixtime"     => unixtime,
          "description"  => line
        }
        Librarian::commit(item)
        item
    end

    # Zone::access(item)
    def self.access(item)
        puts item["description"].green
        if LucilleCore::askQuestionAnswerAsBoolean("done ? : ", true) then
            Zone::destroy(item["uuid"])
            NxBallsService::close(item["uuid"], true)
        end
    end
end
