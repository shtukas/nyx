# encoding: UTF-8

class NxBalls

    # --------------------------------------------------
    # Makers

    # NxBalls::issue(accounts, linkeditemuuid = nil, sequenceStart = nil, isActive = true)
    def self.issue(accounts, linkeditemuuid = nil, sequenceStart = nil, isActive = true)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxBall",
            "unixtime" => Time.new.to_i,
            "isActive" => isActive,
            "accounts" => accounts,
            "itemuuid" => linkeditemuuid,
            "sequenceStart" => sequenceStart
         }
        ItemsManager::commit("NxBall", item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBalls::toRunningStatement(item)
    def self.toRunningStatement(item)
        if item["isActive"] then
            timespan = (Time.new.to_i - item["unixtime"]).to_f/3600
            sequenceStartStr = item["sequenceStart"] ? ", sequence: #{((Time.new.to_i - item["sequenceStart"]).to_f/3600).round(2)} hours" : ""
            "(running for #{timespan.round(2)} hours#{sequenceStartStr})"
        else
            "(paused)"
        end
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

    # NxBalls::pause(nxball)
    def self.pause(nxball)
        NxBalls::close(nxball)
        NxBalls::issue(nxball["accounts"], nxball["itemuuid"], nil, false)
    end

    # NxBalls::pursue(nxball)
    def self.pursue(nxball)
        # We close the existing ball and issue a new one with the same payload (and it doesn't need to have the same uuid)
        NxBalls::close(nxball)
        NxBalls::issue(nxball["accounts"], nxball["itemuuid"], nxball["isActive"] ? nxball["unixtime"] : nil)
    end

    # NxBalls::closeNxBallForItemOrNothing(item)
    def self.closeNxBallForItemOrNothing(item)
        nxball = NxBalls::getNxBallForItemOrNull(item)
        return if nxball.nil?
        NxBalls::close(nxball)
    end
end
