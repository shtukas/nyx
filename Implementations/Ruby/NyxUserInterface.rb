
# encoding: UTF-8

class NyxUserInterface
    # NyxUserInterface::issueNew()
    def self.issueNew()
        ops = ["Nereid data carrier", "Event"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ops)
        return if operation.nil?
        if operation == "Nereid data carrier" then
            element = NereidInterface::interactivelyIssueNewElementOrNull()
            return if element.nil?
            NereidInterface::setOwnership(element["uuid"], "nyx")
            NereidInterface::landing(element)
        end
        if operation == "Event" then
            event = Events::interactivelyIssueNewEventOrNull()
            return if event.nil?
            Events::landing(event)
        end
    end

    # NyxUserInterface::main()
    def self.main()
        loop {
            system("clear")
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
