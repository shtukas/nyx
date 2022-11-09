
class Cx23

    # Cx23::makeCx23(cx22, itemuuid, position)
    def self.makeCx23(cx22, itemuuid, position)
        {
            "mikuType"  => "Cx23",
            "groupuuid" => cx22["uuid"],
            "itemuuid"  => itemuuid,
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

    # Cx23::interactivelyMakeNewGivenCx22OrNull(cx22, itemuuid)
    def self.interactivelyMakeNewGivenCx22OrNull(cx22, itemuuid)
        data = Cx22::itemsForCx22InPositionOrder(cx22)
                .map{|item|
                    cx23 = Cx22::getCx23ForItemAtCx22OrNull(cx22, item["uuid"])
                    {
                        "position"    => cx23["position"],
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
        Cx23::makeCx23(cx22, itemuuid, position)
    end

    # Cx23::interactivelyMakeNewOrNull(itemuuid)
    def self.interactivelyMakeNewOrNull(itemuuid)
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        Cx23::interactivelyMakeNewGivenCx22OrNull(cx22, itemuuid)
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
        cx23 = Cx23::interactivelyMakeNewGivenCx22OrNull(cx22, item["uuid"])
        return if cx23.nil?
        Cx22::commitCx23(cx23)
    end
end