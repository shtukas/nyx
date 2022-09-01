
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
            if item["mikuType"] == "CxAionPoint" then
                return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "CxDx8Unit" then
                return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "CxFile" then
               return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "CxText" then
                return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "CxUniqueString" then
                return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "CxUrl" then
                return "#{item["mikuType"]}"
            end
            if item["mikuType"] == "DxAionPoint" then
                return item["description"]
            end
            if item["mikuType"] == "DxFile" then
                return (item["description"] ? item["description"] : "DxFile: #{item["nhash"]}")
            end
            if item["mikuType"] == "DxLine" then
                return item["line"]
            end
            if item["mikuType"] == "DxText" then
                return item["description"]
            end
            if item["mikuType"] == "DxUniqueString" then
                return item["description"]
            end
            if item["mikuType"] == "DxUrl" then
                return item["url"]
            end
            if item["mikuType"] == "InboxItem" then
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
            if item["mikuType"] == "TxThread" then
                return item["description"]
            end
            if item["mikuType"] == "TxTimeCommitmentProject" then
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
            if item["mikuType"] == "DxAionPoint" then
                return DxAionPoint::toString(item)
            end
            if item["mikuType"] == "CxFile" then
                return CxFile::toString(item)
            end
            if item["mikuType"] == "CxText" then
                return CxText::toString(item)
            end
            if item["mikuType"] == "CxUniqueString" then
                return CxUniqueString::toString(item)
            end
            if item["mikuType"] == "CxUrl" then
                return CxUrl::toString(item)
            end
            if item["mikuType"] == "DxFile" then
                return DxFile::toString(item)
            end
            if item["mikuType"] == "DxLine" then
                return DxLine::toString(item)
            end
            if item["mikuType"] == "DxText" then
                return DxText::toString(item)
            end
            if item["mikuType"] == "DxUniqueString" then
                return DxUniqueString::toString(item)
            end
            if item["mikuType"] == "DxUrl" then
                return DxUrl::toString(item)
            end
            if item["mikuType"] == "InboxItem" then
                return InboxItems::toString(item)
            end
            if item["mikuType"] == "MxPlanning" then
                return MxPlanning::toString(item)
            end
            if item["mikuType"] == "MxPlanningDisplay" then
                return MxPlanning::displayItemToString(item)
            end
            if item["mikuType"] == "NxAnniversary" then
                return Anniversaries::toString(item)
            end
            if item["mikuType"] == "NxBall.v2" then
                return item["description"]
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
            if item["mikuType"] == "TxTimeCommitmentProject" then
                return TxTimeCommitmentProjects::toString(item)
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
        raise "(error: e123ee48-3aad-4fdd-8548-0aef46814bbd)"
    end
end