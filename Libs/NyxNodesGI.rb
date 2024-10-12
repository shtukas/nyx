
class NyxNodesGI

    # NyxNodesGI::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNote::program(item)
            return nil
        end
        if item["mikuType"] == "Sx0138" then
            return Sx0138s::program(item)
        end
        raise "(error: adaa46f8) I do not know how to NyxNodesGI::program this node: #{item}"
    end

    # NyxNodesGI::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        Interface::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
    end

    # NyxNodesGI::connect2(node)
    def self.connect2(node)
        node2 = NyxNodesGI::architectNodeOrNull()
        return if node2.nil?
        NyxNodesGI::connect1(node, node2["uuid"])
        NyxNodesGI::connect1(node2, node["uuid"])
    end

    # NyxNodesGI::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = NyxNodesGI::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "interactively make new" then
                node = Sx0138s::interactivelyIssueNewOrNull()
                if node then
                    return node
                end
            end
        }
    end

    # NyxNodesGI::getNodeOrNullUsingSelectionAndNavigation() nil or node
    def self.getNodeOrNullUsingSelectionAndNavigation()
        puts "get node using selection and navigation".green
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = Interface::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Interface::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Sx0138s::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end
