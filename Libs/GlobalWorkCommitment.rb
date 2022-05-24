# encoding: UTF-8

class GlobalWorkCommitment

    # GlobalWorkCommitment::universes()
    def self.universes()
        return ["backlog"] if [0, 6].include?(Time.new.wday)
        if Time.new.hour >= 8 and Time.new.hour <= 16 then
            ["work", "backlog"]
        else
            ["backlog"]
        end
    end

    # GlobalWorkCommitment::workExpectationInHours()
    def self.workExpectationInHours()
        5
    end

    # GlobalWorkCommitment::getTodayWorkGlobalCommitmentOrNull()
    def self.getTodayWorkGlobalCommitmentOrNull()
        return nil if !GlobalWorkCommitment::universes().include?("work")
        date = DidactUtils::today()
        object = XCache::getOrNull("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}")
        if object then
            object = JSON.parse(object)
            done_ = Bank::valueAtDate(object["uuid"], date)
            return nil if done_ >= 3600*GlobalWorkCommitment::workExpectationInHours()
            left_ = 3600*GlobalWorkCommitment::workExpectationInHours() - done_
            object["announce"] = "Work global commitment, done: #{(done_.to_f/3600).round(2)} hours, left: #{(left_.to_f/3600).round(2)} hours"
            return object
        end
        object = {
            "uuid"        => SecureRandom.hex,
            "mikuType"    => "Tx0930",
            "announce"    => "Work global commitment (awaiting first start)",
            "nonListingDefaultable" => true
        }
        XCache::set("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}", JSON.generate(object))
        object
    end

    # GlobalWorkCommitment::updateWorkGlobalCommitmentWithDoneSeconds(timeInSeconds)
    def self.updateWorkGlobalCommitmentWithDoneSeconds(timeInSeconds)
        date = DidactUtils::today()
        object = GlobalWorkCommitment::getTodayWorkGlobalCommitmentOrNull()
        return if object.nil?
        XCache::set("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}", JSON.generate(object))
    end

    # GlobalWorkCommitment::getEndOfDayRStream()
    def self.getEndOfDayRStream()
        {
            "uuid"     => "23f00ec1-b901-4e74-943f-fd5604c4fa33:#{DidactUtils::today()}",
            "mikuType" => "Tx0938",
            "announce" => "rstream",
            "lambda"   => lambda { TxTodos::rstream() }
        }
    end
end


