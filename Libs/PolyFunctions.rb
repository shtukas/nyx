
class PolyFunctions

    # PolyFunctions::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNote::program(item)
            return nil
        end
        if item["mikuType"] == "NxNode28" then
            return NxNode28s::program(item)
        end
        raise "(error: adaa46f8) I do not know how to PolyFunctions::program this node: #{item}"
    end

    # PolyFunctions::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        NxNode28s::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
    end

    # PolyFunctions::connect2(node)
    def self.connect2(node)
        node2 = PolyFunctions::architectNodeOrNull()
        return if node2.nil?
        PolyFunctions::connect1(node, node2["uuid"])
        PolyFunctions::connect1(node2, node["uuid"])
    end

    # PolyFunctions::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = PolyFunctions::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "interactively make new" then
                node = NxNode28s::interactivelyIssueNewOrNull()
                if node then
                    return node
                end
            end
        }
    end

    # PolyFunctions::getNodeOrNullUsingSelectionAndNavigation() nil or node
    def self.getNodeOrNullUsingSelectionAndNavigation()
        puts "get node using selection and navigation".green
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = NxNode28s::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| NxNode28s::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = NxNode28s::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end
