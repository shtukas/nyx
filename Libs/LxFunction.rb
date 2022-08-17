
class LxFunction

    # LxFunction::function(command, item or nil)
    def self.function(command, item)

        return if command.nil?

        if item.nil?  then
            raise "(error: d366d408-93a1-4e91-af92-c115e88c501f) null item sent to LxFuntion with command: #{command}"
        end

        if item["mikuType"].nil? then
            puts "Objects sent to LxFunction if not null should have a mikuType attribute."
            puts "Got:"
            puts "command: #{command}"
            puts "item: #{JSON.pretty_generate(item)}"
            puts "Aborting."
            raise "(error: f74385d4-5ece-4eae-8a09-90d3a5e0f120)"
        end

        if command == "generic-description" then
            if item["mikuType"] == "NxAnniversary" then
                return item["description"]
            end
            if item["mikuType"] == "Ax1Text" then
                firstline = Ax1Text::getFirstLineOrNull(item)
                return (firstline ? firstline : "(no generic-description)")
            end
            if item["mikuType"] == "NxDataNode" then
                return item["description"]
            end
            if item["mikuType"] == "NxCollection" then
                return item["description"]
            end
            if item["mikuType"] == "NxConcept" then
                return item["description"]
            end
            if item["mikuType"] == "NxEntity" then
                return item["description"]
            end
            if item["mikuType"] == "NxEvent" then
                return item["description"]
            end
            if item["mikuType"] == "NxFrame" then
                return item["description"]
            end
            if item["mikuType"] == "NxIced" then
                return item["description"]
            end
            if item["mikuType"] == "TxThread" then
                return item["description"]
            end
            if item["mikuType"] == "NxLine" then
                return item["line"]
            end
            if item["mikuType"] == "NxPerson" then
                return item["name"]
            end
            if item["mikuType"] == "NxTask" then
                return item["description"]
            end
            if item["mikuType"] == "NxTimeline" then
                return item["description"]
            end
            if item["mikuType"] == "TopLevel" then
                firstline = TopLevel::getFirstLineOrNull(item)
                return (firstline ? firstline : "(no generic-description)")
            end
            if item["mikuType"] == "TxDated" then
                return item["description"]
            end

            if item["mikuType"] == "Wave" then
                return item["description"]
            end
        end

        if command == "toString" then
            if item["mikuType"] == "(rstream-to-target)" then
                return item["announce"]
            end
            if item["mikuType"] == "fitness1" then
                return item["announce"]
            end
            if item["mikuType"] == "Ax1Text" then
                return Ax1Text::toString(item)
            end
            if item["mikuType"] == "NxAnniversary" then
                return Anniversaries::toString(item)
            end
            if item["mikuType"] == "NxBall.v2" then
                return item["description"]
            end
            if item["mikuType"] == "NxDataNode" then
                return NxDataNodes::toString(item)
            end
            if item["mikuType"] == "NxCollection" then
                return NxCollections::toString(item)
            end
            if item["mikuType"] == "NxEntity" then
                return NxEntities::toString(item)
            end
            if item["mikuType"] == "NxEvent" then
                return NxEvents::toString(item)
            end
            if item["mikuType"] == "NxFrame" then
                return NxFrames::toString(item)
            end
            if item["mikuType"] == "NxIced" then
                return NxIceds::toString(item)
            end
            if item["mikuType"] == "NxLine" then
                return NxLines::toString(item)
            end
            if item["mikuType"] == "NxPerson" then
                return NxPersons::toString(item)
            end
            if item["mikuType"] == "NxTask" then
                return NxTasks::toString(item)
            end
            if item["mikuType"] == "NxTimeline" then
                return NxTimelines::toString(item)
            end
            if item["mikuType"] == "TopLevel" then
                return TopLevel::toString(item)
            end
            if item["mikuType"] == "TxDated" then
                return TxDateds::toString(item)
            end
            if item["mikuType"] == "Wave" then
                return Waves::toString(item)
            end
        end

        puts "I do not know how to LxFunction::function (command: #{command}, item: #{JSON.pretty_generate(item)})"
        puts "Aborting."
        exit
    end
end