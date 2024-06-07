
class NyxNodesGI

    # NyxNodesGI::nodes()
    def self.nodes()
        Items::mikuType("NxDot41") +
        Items::mikuType("NxType3NavigationNode") +
        Items::mikuType("NxType1FileSystemNode")
    end

    # NyxNodesGI::interactivelyMakeNewNodeOrNull()
    def self.interactivelyMakeNewNodeOrNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("node type", ["navigation", "data carrier", "file system location"])
        return nil if option.nil?
        if option == "navigation" then
            return NxType3NavigationNodes::interactivelyIssueNewOrNull()
        end
        if option == "data carrier" then
            return NxDot41s::interactivelyIssueNewOrNull()
        end
        if option == "file system location" then
            return NxType1FileSystemNodes::interactivelyIssueNewOrNull()
        end
    end

    # NyxNodesGI::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNote::program(item)
            return nil
        end
        if item["mikuType"] == "NxDot41" then
            return NxDot41s::program(item)
        end
        if item["mikuType"] == "NxType3NavigationNode" then
            return NxType3NavigationNodes::program(item)
        end
        if item["mikuType"] == "NxType1FileSystemNode" then
            return NxType1FileSystemNodes::program(item)
        end
        raise "(error: adaa46f8) I do not know how to NyxNodesGI::program this node: #{item}"
    end

    # NyxNodesGI::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        Items::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
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
                node = NyxNodesGI::interactivelyMakeNewNodeOrNull()
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
                selected = NyxNodesGI::nodes()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Items::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = NyxNodesGI::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end
