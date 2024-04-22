
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
end
