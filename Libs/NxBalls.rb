
class NxBalls

    # ---------------------------------
    # IO

    # NxBalls::issueNxBall(item, accounts)
    def self.issueNxBall(item, accounts)
        nxball = {
            "type"           => "running",
            "startunixtime"  => Time.new.to_i,
            "accounts"       => accounts,
            "sequencestart"  => nil
        }
        Lookups::commit("NxBalls", item["uuid"], nxball)
    end

    # NxBalls::getNxballOrNull(item)
    def self.getNxballOrNull(item)
        Lookups::getValueOrNull("NxBalls", item["uuid"])
    end

    # ---------------------------------
    # Statuses

    # NxBalls::itemIsRunning(item)
    # returns false if the item doesn't have a nxball of is paused
    def self.itemIsRunning(item)
        nxball = NxBalls::getNxballOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "running"
    end

    # NxBalls::itemIsPaused(item)
    def self.itemIsPaused(item)
        nxball = NxBalls::getNxballOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "paused"
    end

    # NxBalls::itemIsBallFree(item)
    def self.itemIsBallFree(item)
        NxBalls::getNxballOrNull(item).nil?
    end

    # ---------------------------------
    # Ops

    # NxBalls::start(item)
    def self.start(item)
        return if !NxBalls::itemIsBallFree(item)
        accounts = PolyFunctions::itemsToBankingAccounts(item)
        accounts.each{|account|
            puts "starting account: (#{account["description"]}, #{account["number"]})"
        }
        NxBalls::issueNxBall(item, accounts)
    end

    # NxBalls::stop(item)
    def self.stop(item)
        if NxBalls::itemIsBallFree(item) then
            Lookups::destroy("NxBalls", item["uuid"])
            return
        end
        if NxBalls::itemIsPaused(item) then
            puts "stopping paused item, nothing to do..."
            Lookups::destroy("NxBalls", item["uuid"])
            return
        end
        # Item is running
        nxball = NxBalls::getNxballOrNull(item)
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["accounts"].each{|account|
            puts "adding #{timespanInSeconds} seconds to account: (#{account["description"]}, #{account["number"]})"
            BankCore::put(account["number"], timespanInSeconds)
        }
        Lookups::destroy("NxBalls", item["uuid"])
    end

    # NxBalls::pause(item)
    def self.pause(item)
        return if !NxBalls::itemIsRunning(item)
        nxball = NxBalls::getNxballOrNull(item)
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["accounts"].each{|account|
            puts "adding #{timespanInSeconds} seconds to account: (#{account["description"]}, #{account["number"]})"
            BankCore::put(account["number"], timespanInSeconds)
        }
        nxball["type"] = "paused"
        nxball["sequencestart"] = nxball["sequencestart"] || Time.new.to_i
        Lookups::commit("NxBalls", item["uuid"], nxball)
    end

    # NxBalls::pursue(item)
    def self.pursue(item)
        return item if !NxBalls::itemIsPaused(item)
        nxball = NxBalls::getNxballOrNull(item)
        nxball["type"]          = "running"
        nxball["startunixtime"] = Time.new.to_i
        nxball["sequencestart"] = nxball["sequencestart"] || nxball["startunixtime"]
        Lookups::commit("NxBalls", item["uuid"], nxball)
    end

    # ---------------------------------
    # Data

    # NxBalls::nxBallToString(nxball)
    def self.nxBallToString(nxball)
        accounts = nxball["accounts"].map{|a| a["description"]}.compact.join(", ")
        if nxball["type"] == "running" and nxball["sequencestart"] then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours, sequence started #{((Time.new.to_i - nxball["sequencestart"]).to_f/3600).round(2)} hours ago, #{accounts})"
        end
        if nxball["type"] == "running" then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours, #{accounts})"
        end
        if nxball["type"] == "paused" then
            return "(nxball: paused) (#{accounts})"
        end
        raise "(error: 93abde39-fd9d-4aa5-8e56-d09cf47a0f46) nxball: #{nxball}"
    end

    # NxBalls::nxballSuffixStatusIfRelevant(item)
    def self.nxballSuffixStatusIfRelevant(item)
        nxball = NxBalls::getNxballOrNull(item)
        return "" if nxball.nil?
        " #{NxBalls::nxBallToString(nxball)}"
    end

end