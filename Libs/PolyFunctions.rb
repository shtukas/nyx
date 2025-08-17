
class PolyFunctions

    # PolyFunctions::program(item, isSeekingSelect)
    def self.program(item, isSeekingSelect)
        if item["mikuType"] == "NxNote" then
            NxNotes::program(item, isSeekingSelect)
            return nil
        end
        if item["mikuType"] == "NxNode28" then
            return NxNode28::program(item, isSeekingSelect)
        end
        raise "(error: adaa46f8) I do not know how to PolyFunctions::program this node: #{item}"
    end

    # PolyFunctions::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        NxNode28::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
    end

    # PolyFunctions::connect2(node, isSeekingSelect) # nil or node
    def self.connect2(node, isSeekingSelect)
        node2 = PolyFunctions::architectNodeOrNull()
        return nil if node2.nil?
        PolyFunctions::connect1(node, node2["uuid"])
        PolyFunctions::connect1(node2, node["uuid"])
        # We have connected node and node2
        # We are now going to land on it and get an opportunity to select it.
        NxNode28::program(node2, isSeekingSelect)
    end

    # PolyFunctions::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new (automatically selected)"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = PolyFunctions::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "interactively make new (automatically selected)" then
                node = NxNode28::interactivelyIssueNewOrNull()
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
                selected = NxNode28::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| NxNode28::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = NxNode28::program(node, true)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end
