
class TimeCommitments

    # TimeCommitments::timeCommitments()
    def self.timeCommitments()
        NxProjects::items() + NxLimitedEmptiers::items()
    end

    # TimeCommitments::itemMissingHours(item)
    def self.itemMissingHours(item)
        if item["mikuType"] == "NxProject" then
            data = Ax39::standardAx39CarrierData(item)
            return 0 if !data["shouldListing"]
            return 0 if data["todayMissingTimeInHoursOpt"].nil?
            return data["todayMissingTimeInHoursOpt"]
        end
        if item["mikuType"] == "NxLimitedEmptier" then
            valueTodayInHours = Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::unrealisedTimespanForItemOrNull(item)).to_f/3600
            return 0 if (valueTodayInHours >= item["hours"])
            return item["hours"] - valueTodayInHours
        end
        raise "(error: cf5e1901-7190-4e82-a417-fd1041cff9bf)"
    end

    # TimeCommitments::itemToString(item)
    def self.itemToString(item)
        if item["mikuType"] == "NxProject" then
            return NxProjects::toStringWithDetails(item, true)
        end
        if item["mikuType"] == "NxLimitedEmptier" then
            return NxLimitedEmptiers::toString(item)
        end
        raise "(error: cf5e1901-7190-4e82-a417-fd1041cff9bf)"
    end

    # TimeCommitments::itemShouldDisplay(item)
    def self.itemShouldDisplay(item)
        return false if !DoNotShowUntil::isVisible(item["uuid"])
        TimeCommitments::itemMissingHours(item) > 0
    end

    # TimeCommitments::missingHours()
    def self.missingHours()
        TimeCommitments::timeCommitments()
            .map{|item| TimeCommitments::itemMissingHours(item) }
            .inject(0, :+)
    end

    # TimeCommitments::printMissingHoursLine() # linecount
    def self.printMissingHoursLine()
        todayMissingInHours = TimeCommitments::missingHours()
        if todayMissingInHours > 0 then
            puts "> missing today in hours: #{todayMissingInHours.round(2)}, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s}".yellow
            return 1
        end
        0
    end

    # TimeCommitments::printing(store) # linecount
    def self.printing(store)
        linecount = 0
        TimeCommitments::timeCommitments()
        .select{|item| TimeCommitments::itemShouldDisplay(item) }
        .sort{|i1, i2| TimeCommitments::itemMissingHours(i1) <=> TimeCommitments::itemMissingHours(i2) }
        .reverse
        .each{|item|
            next if !TimeCommitments::itemToString(item)
            store.register(item, false)
            puts "(#{store.prefixString()}) #{TimeCommitments::itemToString(item)}".yellow
            linecount = linecount + 1
        }
        linecount
    end
end
