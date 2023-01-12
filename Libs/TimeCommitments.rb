
class TimeCommitments

    # TimeCommitments::missingHours()
    def self.missingHours()
        todayMissingInHours = NxProjects::getTodayMissingInHours()
        limitedMissingInHours = NxLimitedEmptiers::listingItems()
                                    .map{|limited|
                                        valueToday = Bank::valueAtDate(limited["uuid"], CommonUtils::today(), NxBalls::unrealisedTimespanForItemOrNull(limited))
                                        if (valueToday.to_f/3600) < limited["hours"] then
                                            limited["hours"] - (valueToday.to_f/3600)
                                        else
                                            0
                                        end
                                    }
                                    .inject(0, :+)
        todayMissingInHours + limitedMissingInHours
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

        todayMissingInHours = TimeCommitments::missingHours()
        if todayMissingInHours > 0 then
            puts "      (missing today in hours: #{todayMissingInHours.round(2)}, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s})".yellow
            linecount = linecount + 1
        end

        {
            projects: projects,
            linecount: linecount
        }
    end

end
