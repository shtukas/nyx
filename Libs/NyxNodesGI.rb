
class NyxNodesGI

    # NyxNodesGI::nodes()
    def self.nodes()
        NxDot41s::items() +
        NxType3NavigationNodes::items() +
        NxType1FileSystemNodes::items()
    end

    # NyxNodesGI::getOrNull(uuid)
    def self.getOrNull(uuid)
        node = NxDot41s::getOrNull(uuid)
        return node if node

        node = NxType3NavigationNodes::getOrNull(uuid)
        return node if node

        node = NxType1FileSystemNodes::getOrNull(uuid)
        return node if node

        nil
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
        end
        if item["mikuType"] == "NxCoreDataRef" then
            reference = item
            CoreDataRefsNxCDRs::program(node["uuid"], reference)
        end
        if item["mikuType"] == "NxDot41" then
            x = NxDot41s::program(item)
            if x then
                return x # was selected during a landing/program
            end
            return
        end
        if item["mikuType"] == "NxType3NavigationNode" then
            x = NxType3NavigationNodes::program(item)
            if x then
                return x # was selected during a landing/program
            end
            return
        end
        if item["mikuType"] == "NxType1FileSystemNode" then
            x = NxType1FileSystemNodes::program(item)
            if x then
                return x # was selected during a landing/program
            end
            return
        end
        raise "(error: adaa46f8) I do not know how to NyxNodesGI::program this node: #{item}"
    end

    # NyxNodesGI::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        if item["mikuType"] == "NxDot41" then
            NxDot41s::commit(node)
        end
        if item["mikuType"] == "NxType3NavigationNode" then
            NxType3NavigationNodes::reCommit(node)
        end
        if item["mikuType"] == "NxType1FileSystemNode" then
            NxType1FileSystemNodes::reCommit(node)
        end
        raise "(error: a0c86621) I do not know how to NyxNodesGI::connect1 this node: #{item}"
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
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "build and return"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = NyxNodesGI::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "build and return" then
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
        sleep 0.5
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
                    selected = selected.select{|node| NxDot41s::getOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
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

    # NyxNodesGI::toString(item)
    def self.toString(item)
        if item["mikuType"] == "NxDot41" then
            return NxDot41s::toString(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            return CoreDataRefsNxCDRs::toString(item)
        end
        raise "(error: f0b8340c-9ed8-4046-b102-7e461cedef21) unsupported miku type: #{item["mikuType"]}"
    end
end
