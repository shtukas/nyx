
# encoding: UTF-8

class NyxUserInterface
    # NyxUserInterface::issueNew()
    def self.issueNew()
        ops = ["Nereid Element", "TimelineItem", "Curated Listing"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ops)
        return if operation.nil?
        if operation == "Nereid Element" then
            element = NereidInterface::interactivelyIssueNewElementOrNull()
            return if element.nil?
            NereidInterface::landing(element)
        end
        if operation == "TimelineItem" then
            event = TimelineItems::interactivelyIssueNewTimelineItemOrNull()
            return if event.nil?
            TimelineItems::landing(event)
        end
        if operation == "Curated Listing" then
            listing = CuratedListings::interactivelyIssueNewCuratedListingOrNull()
            return if listing.nil?
            TimelineItems::landing(listing)
        end
    end

    # NyxUserInterface::main()
    def self.main()
        loop {
            system("clear")
            puts "Nyx 🗺"
            ops = ["Search", "Issue New"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
            break if operation.nil?
            if operation == "Search" then
                NyxPatricia::generalSearchLoop()
            end
            if operation == "Issue New" then
                NyxUserInterface::issueNew()
            end
        }
    end
end

# ----------------------------------------------------------------------------
