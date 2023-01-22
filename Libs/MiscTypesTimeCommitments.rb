class MiscTypesTimeCommitments

    # MiscTypesTimeCommitments::livePendingTimeTodayInHours()
    def self.livePendingTimeTodayInHours()
        todayMissingInHours1 = NxWTCTodayTimeLoads::typeLiveTimeThatShouldBeDoneTodayInHours().to_f/3600
        hours2 = NxOTimeCommitments::typeLiveTimeThatShouldBeDoneTodayInHours().to_f/3600
        todayMissingInHours1 + hours2
    end

    # MiscTypesTimeCommitments::summaryLine()
    def self.summaryLine()
        total = MiscTypesTimeCommitments::livePendingTimeTodayInHours()
        "> time commitment pending: #{"%5.2f" % total} hours, light speed: #{TheSpeedOfLight::getDaySpeedOfLight()}"
    end

    # MiscTypesTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(item)
    def self.itemLiveTimeThatShouldBeDoneTodayInHours(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTCTodayTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(item)
        end
        raise "(error: 037e7af4-e182-4130-9c11-cc27b966d973)"
    end

    # MiscTypesTimeCommitments::reportItemsX()
    def self.reportItemsX()
        (NxWTimeCommitments::items() + NxOTimeCommitments::items())
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| NxBalls::itemIsRunning(item) or MiscTypesTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(item) > 1 }
            .sort{|i1, i2| MiscTypesTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(i1) <=>  MiscTypesTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(i2) }
    end

    # MiscTypesTimeCommitments::listingItems()
    def self.listingItems()
        (NxOTimeCommitments::items() + NxWTimeCommitments::items())
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| NxBalls::itemIsRunning(item) or MiscTypesTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(item) > 1 }
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

    # MiscTypesTimeCommitments::toString(item)
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
