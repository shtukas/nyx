class GeneralTimeCommitments

    # GeneralTimeCommitments::items()
    def self.items()
        NxWTCTodayTimeLoads::itemsThatShouldBeListed() + NxOTimeCommitments::items()
    end

    # GeneralTimeCommitments::pendingTimeInHours()
    def self.pendingTimeInHours()
        todayMissingInHours1 = NxWTCTodayTimeLoads::pendingTimeInSeconds().to_f/3600
        hours2 = NxOTimeCommitments::pendingTimeInSeconds().to_f/3600
        todayMissingInHours1 + hours2
    end

    # GeneralTimeCommitments::summaryLine()
    def self.summaryLine()
        total = GeneralTimeCommitments::pendingTimeInHours()
        "> pending: #{"%5.2f" % total} hours, projected end: #{Time.at( Time.new.to_i + total*3600 ).to_s}"
    end

    # GeneralTimeCommitments::itemPendingTimeInSeconds(item)
    def self.itemPendingTimeInSeconds(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTCTodayTimeLoads::itemPendingTimeInSeconds(item)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::itemPendingTimeInSeconds(item)
        end
        raise "(error: 037e7af4-e182-4130-9c11-cc27b966d973)"
    end

    # GeneralTimeCommitments::itemIsFullToday(item)
    def self.itemIsFullToday(item)
        GeneralTimeCommitments::itemPendingTimeInSeconds(item) <= 0
    end

    # GeneralTimeCommitments::reportItemsX()
    def self.reportItemsX()
        return [] if NxWTCSpeedOfLight::getDaySpeedOfLightOrNull().nil?
        GeneralTimeCommitments::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| !GeneralTimeCommitments::itemIsFullToday(item) }
            .sort{|i1, i2| GeneralTimeCommitments::itemPendingTimeInSeconds(i1) <=>  GeneralTimeCommitments::itemPendingTimeInSeconds(i2) }
    end

    # GeneralTimeCommitments::listingItems()
    def self.listingItems()
        GeneralTimeCommitments::reportItemsX().map{|item|
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
