# encoding: UTF-8

class NxBalls

    # --------------------------------------------------
    # Makers

    # NxBalls::issue(accounts, linkeditemuuid = nil)
    def self.issue(accounts, linkeditemuuid = nil)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxBall",
            "unixtime" => Time.new.to_i,
            "accounts" => accounts,
            "itemuuid" => linkeditemuuid
         }
        ItemsManager::commit("NxBall", item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBalls::toRunningStatement(item)
    def self.toRunningStatement(item)
        timespan = (Time.new.to_i - item["unixtime"]).to_f/3600
        "(running for #{timespan.round(2)} hours)"
    end

    # NxBalls::toString(item)
    def self.toString(item)
        "(nxball) #{item["accounts"].map{|account| account["description"]}.join("; ")} #{NxBalls::toRunningStatement(item)}"
    end

    # NxBalls::getNxBallForItemOrNull(item)
    def self.getNxBallForItemOrNull(item)
        ItemsManager::items("NxBall")
            .select{|nxball| nxball["itemuuid"] == item["uuid"] }
            .first
    end

    # --------------------------------------------------
    # Operations

    # NxBalls::close(nxball)
    def self.close(nxball)
        timespan = Time.new.to_i - nxball["unixtime"]
        nxball["accounts"].each{|account|
            puts "Bank: putting #{timespan} seconds into '#{account["description"]}', account: #{account["number"]}"
            Bank::put(account["number"], timespan)
        }
        ItemsManager::destroy("NxBall", nxball["uuid"])
    end

    # NxBalls::closeNxBallForItemOrNothing(item)
    def self.closeNxBallForItemOrNothing(item)
        nxball = NxBalls::getNxBallForItemOrNull(item)
        return if nxball.nil?
        NxBalls::close(nxball)
    end
end
