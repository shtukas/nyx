# encoding: UTF-8

class NyxNetwork

    # ---------------------------------------------------------------------
    # Select (1)

    # NyxNetwork::selectEntityFromGivenEntitiesOrNullUsingInteractiveInterface(items)
    def self.selectEntityFromGivenEntitiesOrNullUsingInteractiveInterface(items)
        CommonUtils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| LxFunction::function("toString", item) })
    end

    # NyxNetwork::selectExistingNetworkElementOrNull()
    def self.selectExistingNetworkElementOrNull()
        nx20 = Search::interativeInterfaceSelectNx20OrNull()
        return nil if nx20.nil?
        nx20["payload"]
    end

    # NyxNetwork::selectNodesUsingNavigationSandboxOrNull()
    def self.selectNodesUsingNavigationSandboxOrNull()
        system("clear")
        loop {
            nx20 = Search::interativeInterfaceSelectNx20OrNull()
            if nx20 then
                item = nx20["payload"]
                if LucilleCore::askQuestionAnswerAsBoolean("`#{LxFunction("toString", item)}` select ? ") then
                    return item
                else
                    if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                        next
                    else
                        return nil
                    end
                end
            end
        }
    end

    # NyxNetwork::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        NxDataNodes::interactivelyIssueNewItemOrNull()
    end

    # ---------------------------------------------------------------------
    # Select (2)

    # NyxNetwork::selectOneLinkedOrNull(uuid)
    def self.selectOneLinkedOrNull(uuid)
        linked = Links::linked(uuid)
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("linked", linked, lambda{ |i| LxFunction::function("toString", i) })
    end

    # NyxNetwork::selectSubsetOfLinked(uuid)
    def self.selectSubsetOfLinked(uuid)
        linked = Links::linked(uuid)
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        nodessubset, _ = LucilleCore::selectZeroOrMore("linked", [], linked, lambda{ |i| LxFunction::function("toString", i) })
        nodessubset
    end

    # ---------------------------------------------------------------------
    # Architect

    # NyxNetwork::architectOneOrNull()
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetwork::selectNodesUsingNavigationSandboxOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
        if operation == "new" then
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
    end

    # NyxNetwork::architectMultiple()
    def self.architectMultiple()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return [] if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetwork::selectNodesUsingNavigationSandboxOrNull()
            return [entity] if entity
            puts "-> new"
            sleep 1
            return [NyxNetwork::interactivelyMakeNewOrNull()].compact
        end
        if operation == "new" then
            return [NyxNetwork::interactivelyMakeNewOrNull()].compact
        end
    end

    # ---------------------------------------------------------------------
    # Link

    # NyxNetwork::interactivelySelectLinkTypeAndLink(item, other)
    def self.interactivelySelectLinkTypeAndLink(item, other)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related (default)", "other is child"])
        if connectionType.nil? or connectionType == "other is related (default)" then
            NxRelation::issue(item["uuid"], other["uuid"])
        end
        if connectionType == "other is parent" then
            NxArrow::issue(other["uuid"], item["uuid"])
        end
        if connectionType == "other is child" then
            NxArrow::issue(item["uuid"], other["uuid"])
        end
    end

    # NyxNetwork::connectToOneOrMoreOthersArchitectured(item)
    def self.connectToOneOrMoreOthersArchitectured(item)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related", "other is child"])
        return if connectionType.nil?
        NyxNetwork::architectMultiple().each{|other|
            if connectionType == "other is parent" then
                NxArrow::issue(other["uuid"], item["uuid"])
            end
            if connectionType == "other is related" then
                NxRelation::issue(item["uuid"], other["uuid"])
            end
            if connectionType == "other is child" then
                NxArrow::issue(item["uuid"], other["uuid"])
            end
        }
    end

    # NyxNetwork::disconnectFromLinkedInteractively(item)
    def self.disconnectFromLinkedInteractively(item)
        entities = Links::linked(item["uuid"])
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], entities, lambda{ |i| LxFunction::function("toString", i) })
        selected.each{|other|
            Links::unlink(item["uuid"], other["uuid"])
        }
    end

    # ---------------------------------------------------------------------
    # Ops (5)

    # NyxNetwork::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
        if item["nx111"]["type"] != "aion-point" then
            puts "I can only do that with aion-points"
            LucilleCore::pressEnterToContinue()
            return
        end
        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Genesis",
            "nx111"       => item["nx111"].clone
        }
        puts JSON.pretty_generate(item2)
        Librarian::commit(item2)
        NxArrow::issue(item["uuid"], item2["uuid"])
        item["mikuType"] = "NxNavigation"
        puts JSON.pretty_generate(item)
        Librarian::commit(item)
        puts "Operation completed"
        LucilleCore::pressEnterToContinue()
    end

    # NyxNetwork::uploadAllLocationsOfAFolderAsAionPointChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPointChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issueNewItemAionPointFromLocation(location)
            NxArrow::issue(item["uuid"], child["uuid"])
        }
    end

    # NyxNetwork::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
            next if child.nil?
            NxArrow::issue(item["uuid"], child["uuid"])
        }
    end

    # ---------------------------------------------------------------------
    # Ops (6)

    # NyxNetwork::selectItemsByYear(year)
    def self.selectItemsByYear(year)
        NxDataNodes::items().select{|item| item["datetime"][0, 4] == year }
    end

    # NyxNetwork::selectItemsByYearMonth(yearMonth)
    def self.selectItemsByYearMonth(yearMonth)
        NxDataNodes::items().select{|item| item["datetime"][0, 7] == yearMonth }
    end

    # NyxNetwork::getDistictYearMonthsFromItems()
    def self.getDistictYearMonthsFromItems()
        NxDataNodes::items().map{|item| item["datetime"][0, 7] }.uniq.sort
    end

    # NyxNetwork::getItemsFromTheBiggestYearMonth()
    def self.getItemsFromTheBiggestYearMonth()
        last = NyxNetwork::getDistictYearMonthsFromItems()
            .map{|yearMonth|  
                {
                    "yearMonth" => yearMonth,
                    "items" => NyxNetwork::selectItemsByYearMonth(yearMonth)
                }
            }
            .sort{|p1, p2| p1["items"].size <=> p2["items"].size }
            .last
        last["items"].sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end

    # NyxNetwork::getItemsFromTheBiggestYearMonthGame1Edition()
    def self.getItemsFromTheBiggestYearMonthGame1Edition()
        last = NyxNetwork::getDistictYearMonthsFromItems()
            .map{|yearMonth|
                items = NyxNetwork::selectItemsByYearMonth(yearMonth)
                items = items.select{|item| !XCache::getFlag("4636773d-6aa6-4835-b740-0415e4f9149e:#{item["uuid"]}") }
                {
                    "yearMonth" => yearMonth,
                    "items" => items
                }
            }
            .sort{|p1, p2| p1["items"].size <=> p2["items"].size }
            .last
        last["items"].sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end
end
