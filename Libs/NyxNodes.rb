
# encoding: UTF-8

class NyxNodes

    # NyxNodes::items()
    def self.items()
        Items::mikuTypeToItems("NyxNode")
    end

    # NyxNodes::networkType()
    def self.networkType()
        ["PureData", "Concept", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
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

        # We have the convention that only PureData NyxNodes carry (points to) a Nx113
        if networkType == "PureData" then
            nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        end

        ItemsEventsLog::setAttribute2(uuid, "uuid", uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType", "NyxNode")
        ItemsEventsLog::setAttribute2(uuid, "networkType", networkType)
        ItemsEventsLog::setAttribute2(uuid, "unixtime", unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime", datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)

        if nx113nhash then
            ItemsEventsLog::setAttribute2(uuid, "nx113", nx113nhash)
        end

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 6035de89-5fbc-4882-a6f9-f1f703e8b106) How did that happen ? 🤨"
        end
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

        ItemsEventsLog::setAttribute2(uuid, "uuid", uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType", "NyxNode")
        ItemsEventsLog::setAttribute2(uuid, "networkType", networkType)
        ItemsEventsLog::setAttribute2(uuid, "unixtime", unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime", datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)

        ItemsEventsLog::setAttribute2(uuid, "nx113", nx113nhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 6035de89-5fbc-4882-a6f9-f1f703e8b106) How did that happen ? 🤨"
        end
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

        ItemsEventsLog::setAttribute2(uuid, "uuid", uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType", "NyxNode")
        ItemsEventsLog::setAttribute2(uuid, "networkType", networkType)
        ItemsEventsLog::setAttribute2(uuid, "unixtime", unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime", datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)

        ItemsEventsLog::setAttribute2(uuid, "nx113", nx113nhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 6035de89-5fbc-4882-a6f9-f1f703e8b106) How did that happen ? 🤨"
        end
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

        ItemsEventsLog::setAttribute2(uuid, "uuid", uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType", "NyxNode")
        ItemsEventsLog::setAttribute2(uuid, "networkType", networkType)
        ItemsEventsLog::setAttribute2(uuid, "unixtime", unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime", datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)

        ItemsEventsLog::setAttribute2(uuid, "nx113", nx113nhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 6035de89-5fbc-4882-a6f9-f1f703e8b106) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNodes::toString(item)
    def self.toString(item)
        "(NyxNode: #{item["networkType"]}) #{Nx113Access::toStringOrNull("", item["nx113"], " ")} #{item["description"]}"
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
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
        item
    end

    # NyxNodes::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = ItemsEventsLog::getProtoItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts NyxNodes::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            parents = NetworkArrows::parents(item["uuid"])
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

            entities = NetworkLinks::linkedEntities(item["uuid"])
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

            children = NetworkArrows::children(item["uuid"])
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
            commands = [
                "<n> | access | description | name | datetime | nx112 | edit | transmute | expose | destroy",
                "search",
                "link | child | parent | parents>related | parents>children | related>children | related>parents",
            ]
            puts commands.join(" | ").yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyPrograms::itemLanding(entity)
                next
            end

            if Interpreting::match("parents>children", input) then
                NetworkArrows::recastSelectedParentsAsChildren(item)
                return
            end

            if Interpreting::match("parents>related", input) then
                NetworkArrows::recastSelectedParentsAsRelated(item)
                return
            end

            if Interpreting::match("related>children", input) then
                NetworkArrows::recastSelectedLinkedAsChildren(item)
                return
            end

            if Interpreting::match("related>parents", input) then
                NetworkArrows::recastSelectedLinkedAsParents(item)
                return
            end

            if Interpreting::match("access", input) then
                PolyActions::access(item)
                return
            end

            if input == "child" then
                NetworkArrows::architectureAndSetAsChild(item)
                return
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("datetime", input) then
                PolyActions::editDatetime(item)
                return
            end

            if Interpreting::match("description", input) then
                PolyActions::editDescription(item)
                return
            end

            if Interpreting::match("edit", input) then
                PolyFunctions::edit(item)
                return
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                return
            end

            if Interpreting::match("nx113", input) then
                PolyActions::setNx113(item)
                return
            end

            if input == "link" then
                NetworkLinks::architectureAndLink(item)
                return
            end

            if Interpreting::match("name", input) then
                PolyActions::editDescription(item)
                return
            end

            if input == "parent" then
                NetworkArrows::architectureAndSetAsParent(item)
                return
            end

            if input == "transmute" then
                PolyActions::transmute(item)
                return
            end

            if input == "unlink" then
                NetworkLinks::selectOneLinkedAndUnlink(item)
                return
            end

            if input == "upload" then
                Upload::interactivelyUploadToItem(item)
                return
            end

            if input == "upload" then
                Upload::interactivelyUploadToItem(item)
                return
            end
        }
    end
end
