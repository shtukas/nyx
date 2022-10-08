
# encoding: UTF-8

class NyxNodes

    # NyxNodes::items()
    def self.items()
        Items::mikuTypeToItems("NyxNode")
    end

    # NyxNodes::networkType()
    def self.networkType()
        ["PureData", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # NyxNodes::interactivelySelectNetworkType()
    def self.interactivelySelectNetworkType()
        choice = LucilleCore::selectEntityFromListOfEntitiesOrNull("networkType", NyxNodes::networkType())
        return choice if choice
        NyxNodes::interactivelySelectNetworkType()
    end

    # NyxNodes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        networkType = NyxNodes::interactivelySelectNetworkType()

        nx113nhash = nil

        # We have the convention that only PureData NyxNodes carry (points to) a Nx113
        if networkType == "PureData" then
            nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        end

        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash
        }

        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NyxNodes::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        networkType = "PureData"
        nx113nhash = Nx113Make::aionpoint(location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NyxNodes::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        networkType = "PureData"
        nx113nhash = Nx113Make::file(filepath)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NyxNodes::interactivelyIssueNewPureDataTextOrNull()
    def self.interactivelyIssueNewPureDataTextOrNull()
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        networkType = "PureData"
        text = CommonUtils::editTextSynchronously("")
        nx113nhash = Nx113Make::text(text)

        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNodes::toString(item)
    def self.toString(item)
        "(NyxNode: #{item["networkType"]})#{Nx113Access::toStringOrNullShort(" ", item["nx113"], "")} #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # NyxNodes::access(item)
    def self.access(item)
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        else
            puts item["description"]
            LucilleCore::pressEnterToContinue()
        end
    end

    # NyxNodes::edit(item) # item
    def self.edit(item)
        Nx113Edit::edit(item)
        Items::getItemOrNull(item["uuid"])
    end

    # NyxNodes::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = Items::getItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts NyxNodes::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            parents = NetworkEdges::parents(item["uuid"])
            if parents.size > 0 then
                puts ""
                puts "parents: "
                parents
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
                    }
            end

            entities = NetworkEdges::relateds(item["uuid"])
            if entities.size > 0 then
                puts ""
                puts "related: "
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
                    }
            end

            children = NetworkEdges::children(item["uuid"])
            if children.size > 0 then
                puts ""
                puts "children: "
                children
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
                    }
            end

            puts ""
            puts "<n> | access | description | name | datetime | nx113 | edit | transmute | expose | destroy".yellow
            puts "line | link | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::landing(entity)
                next
            end

            if Interpreting::match("access", input) then
                PolyActions::access(item)
                next
            end
            if input == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                i2 = NxLines::issueNew(line)
                NetworkEdges::arrow(item["uuid"], i2["uuid"])
                next
            end

            if input == "child" then
                NetworkShapeAroundNode::architectureAndSetAsChild(item)
                next
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("datetime", input) then
                PolyActions::editDatetime(item)
                next
            end

            if Interpreting::match("description", input) then
                PolyActions::editDescription(item)
                next
            end

            if Interpreting::match("edit", input) then
                item = NyxNodes::edit(item)
                puts JSON.pretty_generate(item)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("nx113", input) then
                PolyActions::setNx113(item)
                next
            end

            if input == "link" then
                NetworkShapeAroundNode::architectureAndRelate(item)
                next
            end

            if Interpreting::match("name", input) then
                PolyActions::editDescription(item)
                next
            end

            if input == "parent" then
                NetworkShapeAroundNode::architectureAndSetAsParent(item)
                next
            end

            if input == "transmute" then
                PolyActions::transmute(item)
                next
            end

            if input == "unlink" then
                NetworkShapeAroundNode::selectOneRelatedAndDetach(item)
                next
            end

            if input == "upload" then
                Upload::interactivelyUploadToItem(item)
                next
            end

            if Interpreting::match("parents>children", input) then
                NetworkShapeAroundNode::selectParentsAndRecastAsChildren(item)
                next
            end

            if Interpreting::match("parents>related", input) then
                NetworkShapeAroundNode::selectParentsAndRecastAsRelated(item)
                next
            end

            if Interpreting::match("related>children", input) then
                NetworkShapeAroundNode::selectLinkedsAndRecastAsChildren(item)
                next
            end

            if Interpreting::match("children>related", input) then
                NetworkShapeAroundNode::selectChildrenAndRecastAsRelated(item)
                next
            end

            if Interpreting::match("related>parents", input) then
                NetworkShapeAroundNode::selectLinkedAndRecastAsParents(item)
                next
            end

            if Interpreting::match("select children; move to selected child", input) then
                NetworkShapeAroundNode::selectChildrenAndSelectTargetChildAndMove(item)
                next
            end
        }
    end
end
