
# encoding: UTF-8

class IfcsTimePenalties
    # IfcsTimePenalties::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # IfcsTimePenalties::getClaimOrdinalOrNull(uuid)
    def self.getClaimOrdinalOrNull(uuid)
        IfcsClaims::claimsOrderedWithOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # IfcsTimePenalties::getTotalAttributed24TimeExpectation1()
    def self.getTotalAttributed24TimeExpectation1()
        # This is the time given to IFCS and then we move to standard projects
        if IfcsTimePenalties::isWeekDay() then
            2 * 3600
        else
            4 * 3600
        end
    end

    # IfcsTimePenalties::getGuardian24TimeExpectation()
    def self.getGuardian24TimeExpectation()
        if IfcsTimePenalties::isWeekDay() then
            5 * 3600
        else
            2 * 3600
        end
    end

    # IfcsTimePenalties::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        IfcsTimePenalties::getTotalAttributed24TimeExpectation1() * (1.to_f / 2**(ordinal+1))
    end

    # IfcsTimePenalties::getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
    def self.getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
        return IfcsTimePenalties::getGuardian24TimeExpectation() if uuid == "20200502-141331-226084"
        IfcsTimePenalties::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    end

    # IfcsTimePenalties::distributeIfcsPenatiesIfNotDoneAlready()
    def self.distributeIfcsPenatiesIfNotDoneAlready()
        return if Time.new.hour < 9
        return if Time.new.hour > 18
        IfcsClaims::claimsOrdered()
            .each{|claim|
                uuid = claim["uuid"]
                next if IfcsTimePenalties::getClaimOrdinalOrNull(uuid) >= 4 # we only want 0 (Guardian) and 1, 2, 3
                next if Ping::pong(uuid) < -3600 # This values allows small targets to get some time and the big ones not to become overwelming
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = IfcsTimePenalties::getProject24HoursTimeExpectationInSeconds(uuid, IfcsTimePenalties::getClaimOrdinalOrNull(uuid))
                next if timespan.nil?
                Ping::ping(uuid, -timespan, Utils::pingRetainPeriodInSeconds())
                KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
            }
    end
end
