
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DailyTimes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

# -----------------------------------------------------------

DAILY_TOTAL_ORDINAL_TIME_IN_HOURS = 3

class InFlightControlSystem

    # InFlightControlSystem::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/ifcs-claims2"
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

    # InFlightControlSystem::destroy(claim)
    def self.destroy(claim)
        uuid = claim["uuid"]
        filepath = "#{InFlightControlSystem::path()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)

        Mercury::postValue("A6711E39-E69E-4A36-A9FA-C8BA1030118E", claim["itemuuid"])
    end

    # InFlightControlSystem::claimsOrdered()
    def self.claimsOrdered()
        Dir.entries(InFlightControlSystem::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{InFlightControlSystem::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .select{|claim| !InFlightControlSystem::getTodoItemOrNull(claim["itemuuid"]).nil? }
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
        InFlightControlSystem::claimsOrdered()
            .select{|claim| claim["itemuuid"] == itemuuid }
    end

    # InFlightControlSystem::claimToStringOrNull(claim)
    def self.claimToStringOrNull(claim)
        todoitem = InFlightControlSystem::getTodoItemOrNull(claim["itemuuid"])
        uuid = claim["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hour)" : ""
        position = claim["position"]
        ordinal = InFlightControlSystem::getClaimOrdinalOrNull(uuid)
        timeexpectation = DailyTimes::getItem24HoursTimeExpectationInHours(DAILY_TOTAL_ORDINAL_TIME_IN_HOURS, ordinal)
        timeInBank = Bank::total(uuid)
        "[ifcs] (pos: #{claim["position"]}, time exp.: #{timeexpectation.round(2)} hours, bank: #{(timeInBank.to_f/3600).round(2)} hours) [todo item] #{todoitem ? todoitem["description"] : "(Could not extract todo item)"}"
    end

    # InFlightControlSystem::metric(claim)
    def self.metric(claim)
        uuid = claim["uuid"]
        return 1 if Runner::isRunning(uuid)
        return 0 if InFlightControlSystem::getClaimOrdinalOrNull(uuid) >= 4 # we only want 0 (Guardian) and 1, 2, 3
        timeInHours = Bank::total(uuid).to_f/3600
        if 0 <= timeInHours then
            0.70*Math.exp(-timeInHours) # We decrease rapidely to 0
        else
            # negative
            if -0.5 < timeInHours then
                # we are between -0.5 and 0
                0.4 + 0.4*(-timeInHours) 
                    # at  0   -> 0.4
                    # at -0.5 -> 0.4 + 0.4*(0.5) = 0.6
            else
                0.70 + 0.05*(1-Math.exp(timeInHours))
            end
        end
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # InFlightControlSystem::interactiveChoiceOfIfcsPosition()
    def self.interactiveChoiceOfIfcsPosition() # Float
        puts "ifcs claims"
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

    # InFlightControlSystem::getTodoItemOrNull(itemuuid)
    def self.getTodoItemOrNull(itemuuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/items2/#{itemuuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end
end
