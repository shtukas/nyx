class GeneralTimeCommitments

    # GeneralTimeCommitments::livePendingTimeTodayInHours()
    def self.livePendingTimeTodayInHours()
        todayMissingInHours1 = NxWTCTodayTimeLoads::livePendingTimeTodayInSeconds().to_f/3600
        hours2 = NxOTimeCommitments::livePendingTimeTodayInSeconds().to_f/3600
        todayMissingInHours1 + hours2
    end

    # GeneralTimeCommitments::summaryLine()
    def self.summaryLine()
        total = GeneralTimeCommitments::livePendingTimeTodayInHours()
        "> time commitment pending: #{"%5.2f" % total} hours, projected end: #{Time.at( Time.new.to_i + total*3600 ).to_s}, light speed: #{TheSpeedOfLight::getDaySpeedOfLight()}"
    end

    # GeneralTimeCommitments::itemLivePendingTimeTodayInSeconds(item)
    def self.itemLivePendingTimeTodayInSeconds(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTCTodayTimeLoads::itemLivePendingTimeTodayInSeconds(item)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::itemLivePendingTimeTodayInSeconds(item)
        end
        raise "(error: 037e7af4-e182-4130-9c11-cc27b966d973)"
    end

    # GeneralTimeCommitments::reportItemsX()
    def self.reportItemsX()
        (NxWTimeCommitments::items() + NxOTimeCommitments::items())
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| NxBalls::itemIsRunning(item) or GeneralTimeCommitments::itemLivePendingTimeTodayInSeconds(item) > 1 }
            .sort{|i1, i2| GeneralTimeCommitments::itemLivePendingTimeTodayInSeconds(i1) <=>  GeneralTimeCommitments::itemLivePendingTimeTodayInSeconds(i2) }
    end

    # GeneralTimeCommitments::listingItems()
    def self.listingItems()
        (NxOTimeCommitments::items() + NxWTimeCommitments::items())
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| NxBalls::itemIsRunning(item) or GeneralTimeCommitments::itemLivePendingTimeTodayInSeconds(item) > 1 }
            .map{|item|
                (lambda{|item|
                    if item["mikuType"] == "NxWTimeCommitment" then
                        return NxWTimeCommitments::itemWithToAllAssociatedListingItems(item)
                    end
                    if item["mikuType"] == "NxOTimeCommitment" then
                        return item
                    end
                }).call(item)
            }
            .flatten
    end

    # GeneralTimeCommitments::toString(item)
    def self.toString(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTimeCommitments::toStringWithDetails(item, true)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::toString(item)
        end
        raise "(error: 137e7af4-e182-4130-9c11-cc27b966d974)"
    end
end
