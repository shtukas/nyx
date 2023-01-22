class GeneralTimeCommitments

    # GeneralTimeCommitments::items()
    def self.items()
        NxWTCTodayTimeLoads::itemsThatShouldBeListed() + NxOTimeCommitments::items()
    end

    # GeneralTimeCommitments::pendingTimeTodayInHours()
    def self.pendingTimeTodayInHours()
        todayMissingInHours1 = NxWTCTodayTimeLoads::pendingTimeTodayInSeconds().to_f/3600
        hours2 = NxOTimeCommitments::pendingTimeTodayInSeconds().to_f/3600
        todayMissingInHours1 + hours2
    end

    # GeneralTimeCommitments::summaryLine()
    def self.summaryLine()
        total = GeneralTimeCommitments::pendingTimeTodayInHours()
        "> time commitment pending: #{"%5.2f" % total} hours, projected end: #{Time.at( Time.new.to_i + total*3600 ).to_s}, light speed: #{TheSpeedOfLight::getDaySpeedOfLightOrNull()}"
    end

    # GeneralTimeCommitments::itemPendingTimeTodayInSeconds(item)
    def self.itemPendingTimeTodayInSeconds(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTCTodayTimeLoads::itemPendingTimeTodayInSeconds(item)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::itemPendingTimeTodayInSeconds(item)
        end
        raise "(error: 037e7af4-e182-4130-9c11-cc27b966d973)"
    end

    # GeneralTimeCommitments::reportItemsX()
    def self.reportItemsX()
        GeneralTimeCommitments::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| GeneralTimeCommitments::itemPendingTimeTodayInSeconds(item) > 1 }
            .sort{|i1, i2| GeneralTimeCommitments::itemPendingTimeTodayInSeconds(i1) <=>  GeneralTimeCommitments::itemPendingTimeTodayInSeconds(i2) }
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
