
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

class InFlightControlSystem

    # InFlightControlSystem::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/ifcs-claims2"
    end

    # InFlightControlSystem::save(item)
    def self.save(item)
        filepath = "#{InFlightControlSystem::path()}/#{item["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # InFlightControlSystem::issue(itemuuid, position)
    def self.issue(itemuuid, position)
        claim = {
            "uuid"        => SecureRandom.uuid,
            "itemuuid"    => itemuuid,
            "position"    => position
        }
        InFlightControlSystem::save(claim)
    end

    # InFlightControlSystem::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{InFlightControlSystem::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # InFlightControlSystem::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{InFlightControlSystem::path()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # InFlightControlSystem::claimsOrdered() # Array[ (ifcs claim, ordinal: Int) ]
    def self.claimsOrdered()
        Dir.entries(InFlightControlSystem::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{InFlightControlSystem::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["position"] <=> c2["position"] }
    end

    # InFlightControlSystem::claimsOrderedWithOrdinal() # Array[ (ifcs claim, ordinal: Int) ]
    def self.claimsOrderedWithOrdinal()
        InFlightControlSystem::claimsOrdered()
            .map
            .with_index
            .to_a
    end

    # InFlightControlSystem::getClaimsByItemUUID(itemuuid)
    def self.getClaimsByItemUUID(itemuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Todo/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .select{|claim| claim["itemuuid"] == itemuuid }
    end

    # InFlightControlSystem::claimToStringOrNull(claim)
    def self.claimToStringOrNull(claim)
        item = InFlightControlSystem::getOrNull(claim["itemuuid"])
        return nil if item.nil?
        uuid = claim["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hour)" : ""
        position = claim["position"]
        ordinal = InFlightControlSystem::getClaimOrdinalOrNull(uuid)
        timeexpectation = DailyNegativeTimes::getItem24HoursTimeExpectationInHours(DAILY_TOTAL_ORDINAL_TIME_IN_HOURS, ordinal)
        timeInBank = Bank::total(uuid)
        "[ifcs] (pos: #{claim["position"]}, time exp.: #{timeexpectation.round(2)} hours, bank: #{(timeInBank.to_f/3600).round(2)} hours) [item] #{Items::itemBestDescription(item)}#{runningSuffix}"
    end

    # InFlightControlSystem::claimMetric(ifcsclaim)
    def self.claimMetric(ifcsclaim)
        uuid = ifcsclaim["uuid"]
        return 1 if Runner::isRunning(uuid)
        return 0 if InFlightControlSystem::getClaimOrdinalOrNull(uuid) >= 4 # we only want 0 (Guardian) and 1, 2, 3
        timeInHours = Bank::total(uuid).to_f/3600
        timeInQuarterOfHours = timeInHours*4
        if timeInHours > 0 then
            0.70*Math.exp(-timeInHours)
        else
            0.70 + 0.05*(1-Math.exp(timeInHours))
        end
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # InFlightControlSystem::interactiveChoiceOfIfcsPosition()
    def self.interactiveChoiceOfIfcsPosition() # Float
        puts "Items"
        InFlightControlSystem::claimsOrdered()
            .each{|claim|
                uuid = claim["uuid"]
                puts "    - #{("%5.3f" % claim["position"])} #{InFlightControlSystem::claimToStringOrNull(claim)}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # InFlightControlSystem::nextIfcsPosition()
    def self.nextIfcsPosition()
        InFlightControlSystem::claimsOrdered().map{|claim| claim["position"] }.max.ceil
    end

    # InFlightControlSystem::getClaimOrdinalOrNull(uuid)
    def self.getClaimOrdinalOrNull(uuid)
        InFlightControlSystem::claimsOrderedWithOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end
end
