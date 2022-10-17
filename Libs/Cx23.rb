
class Cx23

    # Cx23::makeCx23(cx22, position)
    def self.makeCx23(cx22, position)
        {
            "groupuuid" => cx22["uuid"],
            "position"  => position
        }
    end

    # Cx23::makeNewOrNull(cx22)
    def self.makeNewOrNull(cx22)
        data = NxTodos::itemsInPositionOrderForGroup(cx22)
            .select{|item| item["cx23"] }
            .map{|item|
                {
                    "position"    => item["cx23"]["position"],
                    "description" => item["description"]
                }
            }
        data.each{|i|
            puts "#{i["position"]} : #{i["description"]}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for abort): ")
        return nil if position == ""
        position = position.to_f
        Cx23::makeCx23(cx22, position)
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
        cx22 = Cx22::getOrNull(item["cx22"])
        return if cx22.nil?
        cx23 = Cx23::makeNewOrNull(cx22)
        return if cx23.nil?
        PhageRefactoring::setAttribute2(item["uuid"], "cx23", cx23)
    end
end