
class TimeCommitments

    # TimeCommitments::timeCommitments()
    def self.timeCommitments()
        NxProjects::items() + NxLimitedEmptiers::items()
    end

    # TimeCommitments::itemMissingHours(item)
    def self.itemMissingHours(item)
        if item["mikuType"] == "NxProject" then
            data = Ax39::standardAx39CarrierData(item)
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

    # TimeCommitments::printAtListing(store) # linecount
    def self.printAtListing(store)
        linecount = 0

        projectsHaveDisplayed = false

        projects1, projects2 = NxProjects::projectsForListing().partition{|project| project["isWork"] }
        projects = projects1 + projects2
        if projects.size > 0 then
            puts ""
            linecount = linecount + 1
            projects.each{|project|
                store.register(project, false)
                line = "(#{store.prefixString()}) #{NxProjects::toStringWithDetails(project, true)}"
                if (nxball = NxBalls::getNxBallForItemOrNull(project)) then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                else
                    line = line.yellow
                end
                puts line
                linecount = linecount + 1
            }
            projectsHaveDisplayed = true
        end

        limiteds = NxLimitedEmptiers::listingItems()
        if !projectsHaveDisplayed and limiteds.size > 0 then
            puts ""
            linecount = linecount + 1
        end
        limiteds.each{|limited|
            store.register(limited, false)
            line = "(#{store.prefixString()}) #{NxLimitedEmptiers::toString(limited)}"
            if (nxball = NxBalls::getNxBallForItemOrNull(limited)) then
                line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
            else
                line = line.yellow
            end
            puts line
            linecount = linecount + 1
        }

        {
            projects: projects,
            linecount: linecount
        }
    end
end
