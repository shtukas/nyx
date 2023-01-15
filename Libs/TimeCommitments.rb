
class TimeCommitments

    # TimeCommitments::timeCommitments()
    def self.timeCommitments()
        NxProjects::items() + NxLimitedEmptiers::items() + Waves::items()
    end

    # TimeCommitments::itemMissingHours(item)
    def self.itemMissingHours(item)
        if item["mikuType"] == "NxProject" then
            return NxProjects::numbers(item)["missingHoursForToday"]
        end
        if item["mikuType"] == "NxLimitedEmptier" then
            return NxLimitedEmptiers::numbers(item)["missingHoursForToday"]
        end
        if item["mikuType"] == "Wave" then
            return Waves::numbers(item)["missingHoursForToday"]
        end
        raise "(error: a458a103-1fb8-46d6-b3a2-72e583b28863)"
    end

    # TimeCommitments::missingHours()
    def self.missingHours()
        TimeCommitments::timeCommitments()
            .map{|item| TimeCommitments::itemMissingHours(item) }
            .inject(0, :+)
    end

    # TimeCommitments::line()
    def self.line()
        todayMissingInHours = TimeCommitments::missingHours()
        "> missing: #{"%5.2f" % todayMissingInHours} hours, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s}"
    end

    # TimeCommitments::report()
    def self.report()
        TimeCommitments::timeCommitments()
            .map{|item|
                hours = TimeCommitments::itemMissingHours(item)
                if hours > 0 then
                    "> missing: #{"%5.2f" % hours} hours; #{PolyFunctions::toString(item)}"
                else
                    nil
                end
            }
            .compact
    end
end
