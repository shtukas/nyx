class Architect

    # ---------------------------------------------------------------------
    # Select (1)

    # Architect::selectEntityFromGivenEntitiesOrNullUsingInteractiveInterface(items)
    def self.selectEntityFromGivenEntitiesOrNullUsingInteractiveInterface(items)
        CommonUtils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| LxFunction::function("toString", item) })
    end

    # Architect::selectExistingNetworkElementOrNull()
    def self.selectExistingNetworkElementOrNull()
        nx20 = Search::interativeInterfaceSelectNx20OrNull()
        return nil if nx20.nil?
        nx20["payload"]
    end

    # Architect::selectNodesUsingNavigationSandboxOrNull()
    def self.selectNodesUsingNavigationSandboxOrNull()
        system("clear")
        loop {
            nx20 = Search::interativeInterfaceSelectNx20OrNull()
            if nx20 then
                item = nx20["payload"]
                if LucilleCore::askQuestionAnswerAsBoolean("`#{LxFunction::function("toString", item).green}` select ? ") then
                    return item
                end
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                    next
                else
                    return nil
                end
            end
        }
    end

    # Architect::interactivelyMakeNewOrNull() # objectuuid or null
    def self.interactivelyMakeNewOrNull()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["NxDataNode"] + Iam::aggregationTypes())
        return if action.nil?

        if action == "NxDataNode" then
            return NxDataNodes::interactivelyIssueNewItemOrNull()
        end
        if action == "NxPerson" then
            return NxPersons::interactivelyIssueNewOrNull()
        end
        if action == "NxEntity" then
            return NxEntities::interactivelyIssueNewItemOrNull()
        end
        if action == "NxConcept" then
            return NxConcepts::interactivelyIssueNewItemOrNull()
        end
        if action == "NxCollection" then
            return NxCollections::interactivelyIssueNewItemOrNull()
        end
        if action == "NxTimeline" then
            return NxTimelines::interactivelyIssueNewItemOrNull()
        end

        raise "(error: 46cb00c3-9c1d-41cd-8d3d-bfc6598d3e73)"
    end

    # Architect::architectOneOrNull() # objectuuid or null
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            entityuuid = Architect::selectNodesUsingNavigationSandboxOrNull()
            return entityuuid if entityuuid
            return Architect::interactivelyMakeNewOrNull()
        end
        if operation == "new" then
            return Architect::interactivelyMakeNewOrNull()
        end
    end
end
