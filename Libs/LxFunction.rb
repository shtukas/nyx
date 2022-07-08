
class LxFunction

    # LxFunction::function(command, item or nil)
    def self.function(command, item)

        return if command.nil?

        if item and item["mikuType"].nil? then
            puts "Objects sent to LxFunction if not null should have a mikuType attribute."
            puts "Got:"
            puts JSON.pretty_generate(item)
            puts "Aborting."
            exit
        end

        if command == "toString" then
            if item["mikuType"] == "(rstream)" then
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
            if item["mikuType"] == "NxConcept" then
                return NxConcepts::toString(item)
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
            if item["mikuType"] == "NxLine" then
                return NxLines::toString(item)
            end
            if item["mikuType"] == "NxPerson" then
                return NxPersons::toString(item)
            end
            if item["mikuType"] == "TxProject" then
                return TxProjects::toString(item)
            end
            if item["mikuType"] == "NxTask" then
                return NxTasks::toString(item)
            end
            if item["mikuType"] == "NxTimeline" then
                return NxTimelines::toString(item)
            end
            if item["mikuType"] == "TxQueue" then
                return TxQueues::toString(item)
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