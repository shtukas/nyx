
class TimeCommitments

    # TimeCommitments::timeCommitments()
    def self.timeCommitments()
        NxProjects::items() + NxLimitedEmptiers::items()
    end

    # TimeCommitments::itemMissingHours(item)
    def self.itemMissingHours(item)
        if item["mikuType"] == "NxProject" then
            return NxProjects::numbers(item)["missingHoursForToday"]
        end
        if item["mikuType"] == "NxLimitedEmptier" then
            return NxLimitedEmptiers::numbers(item)["missingHoursForToday"]
        end
        raise "(error: a458a103-1fb8-46d6-b3a2-72e583b28863)"
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

    # TimeCommitments::printLine() # linecount
    def self.printLine()
        todayMissingInHours = TimeCommitments::missingHours()
        if todayMissingInHours > 0 then
            puts "> missing today: #{todayMissingInHours.round(2)} hours, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s}".yellow
            return 1
        end
        0
    end

end
