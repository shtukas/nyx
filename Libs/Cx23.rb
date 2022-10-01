
class Cx23

    # Cx23::makeCx23(groupuuid, position)
    def self.makeCx23(groupuuid, position)
        {
            "mikuType"  => "Cx22",
            "groupuuid" => groupuuid,
            "position"  => position
        }
    end

    # Cx23::makeNewOrNull1(groupuuid, positionsAndDescriptions)
    def self.makeNewOrNull1(groupuuid, positionsAndDescriptions)
        positionsAndDescriptions.each{|i|
            puts "#{i["position"]} : #{i["description"]}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for abort): ")
        return nil if position == ""
        position = position.to_f
        Cx23::makeCx23(groupuuid, position)
    end

    # Cx23::makeNewOrNull2(groupuuid)
    def self.makeNewOrNull2(groupuuid)
        positionsAndDescriptions = Cx22::groupuuidToItemsWithPositionInPositionOrder(groupuuid)
            .map{|item|
                {
                    "position"    => item["cx23"]["position"],
                    "description" => item["description"]
                }
            }
        Cx23::makeNewOrNull1(groupuuid, positionsAndDescriptions)
    end

    # Cx23::interactivelySetCx23ForItemOrNothing(item)
    def self.interactivelySetCx23ForItemOrNothing(item)
        if item["mikuType"] != "NxTodo" then
            puts "At the moment we only set Cx23 for NxTodos"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["cx22"].nil? then
            puts "This item is not contributing (missing Cx22) so we are not going to set a Cx23"
            LucilleCore::pressEnterToContinue()
            return
        end
        cx23 = Cx23::makeNewOrNull2(item["cx22"]["groupuuid"])
        return if cx23.nil?
        ItemsEventsLog::setAttribute2(item["uuid"], "cx23", cx23)
    end
end