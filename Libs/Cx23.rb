
class Cx23

    # Cx23::makeCx23(cx22, position)
    def self.makeCx23(cx22, position)
        {
            "mikuType"  => "Cx23",
            "groupuuid" => cx22["uuid"],
            "position"  => position
        }
    end

    # Cx23::toStringOrNull(cx23)
    def self.toStringOrNull(cx23)
        return nil if cx23.nil?
        cx22 = Cx22::getOrNull(cx23["groupuuid"])
        return nil if cx22.nil?
        "#{cx22["description"]}, #{cx23["position"]}"
    end

    # Cx23::interactivelyMakeNewGivenCx22OrNull(cx22)
    def self.interactivelyMakeNewGivenCx22OrNull(cx22)
        data = NxTodos::itemsInPositionOrderForGroup(cx22)
            .select{|item| item["cx23"] }
            .map{|item|
                {
                    "position"    => item["cx23"]["position"],
                    "description" => item["description"]
                }
            }
        data.take(CommonUtils::screenHeight()-4)
             .each{|i|
                puts "#{"%6.2f" % i["position"]} : #{i["description"]}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            position = Cx22::nextPositionForCx22(cx22)
        else
            position = position.to_f
        end
        Cx23::makeCx23(cx22, position)
    end

    # Cx23::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        Cx23::interactivelyMakeNewGivenCx22OrNull(cx22)
    end

    # Cx23::interactivelySetCx23ForItemOrNothing(item)
    def self.interactivelySetCx23ForItemOrNothing(item)
        if item["mikuType"] != "NxTodo" then
            puts "At the moment we only set Cx23 for NxTodos"
            LucilleCore::pressEnterToContinue()
            return
        end
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        cx23 = Cx23::interactivelyMakeNewGivenCx22OrNull(cx22)
        return if cx23.nil?
        item["cx23"] = cx23
        PolyActions::commit(item)
    end
end