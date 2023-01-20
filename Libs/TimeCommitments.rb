
class TimeCommitments

    # TimeCommitments::timeCommitments()
    def self.timeCommitments()
        NxTimeCommitments::items() + Waves::items()
    end

    # TimeCommitments::itemMissingHours(item)
    def self.itemMissingHours(item)
        if item["mikuType"] == "NxTimeCommitment" then
            return NxTimeCommitments::numbers(item)["missingHoursForToday"]
        end
        if item["mikuType"] == "Wave" then
            return Waves::numbers(item)["missingHoursForToday"]
        end
        raise "(error: a458a103-1fb8-46d6-b3a2-72e583b28863)"
    end

    # TimeCommitments::itemToAllAssociatedListingItems(item)
    def self.itemToAllAssociatedListingItems(item)
        if item["mikuType"] == "NxTimeCommitment" then
            return NxTimeCommitments::itemWithToAllAssociatedListingItems(item)
        end
        if item["mikuType"] == "Wave" then
            return item
        end
        raise "(error: 774dc851-f949-4ed6-b076-d91079d8b393)"
    end

    # TimeCommitments::totalMissingHours()
    def self.totalMissingHours()
        TimeCommitments::timeCommitments()
            .map{|item| TimeCommitments::itemMissingHours(item) }
            .inject(0, :+)
    end

    # TimeCommitments::reportItemsX()
    def self.reportItemsX()
        items = TimeCommitments::timeCommitments()
            .select{|item| item["mikuType"] != "Wave" }
            .select{|item| NxBalls::itemIsRunning(item) or TimeCommitments::itemMissingHours(item) > 0 }
            .sort{|i1, i2| TimeCommitments::itemMissingHours(i1) <=> TimeCommitments::itemMissingHours(i2) }
        isMidDay = Time.new.hour >= 9 and Time.new.hour < 16
        if isMidDay then
            items = items.reverse # higher demand first as they usually correspond to work
        end
        items
    end

    # TimeCommitments::listingItems()
    def self.listingItems()
        TimeCommitments::reportItemsX()
            .map{|item| TimeCommitments::itemToAllAssociatedListingItems(item) }
            .flatten
    end

    # TimeCommitments::summaryLine()
    def self.summaryLine()
        todayMissingInHours = TimeCommitments::totalMissingHours()
        "> pending today: #{"%5.2f" % todayMissingInHours} hours, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s}"
    end

    # TimeCommitments::toStringForListing(item)
    def self.toStringForListing(item)
        hours = TimeCommitments::itemMissingHours(item)
        "[tc: #{"%5.2f" % hours} hours] #{PolyFunctions::toStringForCatalystListing(item)}"
    end
end
