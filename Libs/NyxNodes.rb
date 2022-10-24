
# encoding: UTF-8

class NyxNodes

    # ----------------------------------------------------------------------
    # Basis IO

    # NyxNodes::items()
    def self.items()
        TheBook::getObjects("#{Config::pathToDataCenter()}/NyxNode")
    end

    # NyxNodes::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        TheBook::getObjectOrNull("#{Config::pathToDataCenter()}/NyxNode", uuid)
    end

    # NyxNodes::commitObject(object)
    def self.commitObject(object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        TheBook::commitObjectToDisk("#{Config::pathToDataCenter()}/NyxNode", object)
    end

    # NyxNodes::destroy(uuid)
    def self.destroy(uuid)
        TheBook::destroy("#{Config::pathToDataCenter()}/NyxNode", uuid)
    end

    # ----------------------------------------------------------------------
    # Makers

    # NyxNodes::type1s()
    def self.type1s()
        ["Information", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # NyxNodes::interactivelySelectType1s()
    def self.interactivelySelectType1s()
        choice = LucilleCore::selectEntityFromListOfEntitiesOrNull("networkType", NyxNodes::type1s())
        return choice if choice
        NyxNodes::interactivelySelectType1s()
    end

    # NyxNodes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        type_1 = NyxNodes::interactivelySelectType1s()
        payload_1 = Payload1::interactivelyMake()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "type_1"      => type_1,
            "payload_1"   => payload_1
        }
        NyxNodes::commitObject(item)
        item
    end

    # NyxNodes::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        type_1 = "Information"
        payload_1 = Payload1::makeNewUsingLocation(location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "type_1"      => type_1,
            "payload_1"   => payload_1
        }
        NyxNodes::commitObject(item)
        item
    end

    # NyxNodes::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        type_1 = "Information"
        payload_1 = Payload1::makeNewUsingFile(filepath)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "type_1"      => type_1,
            "payload_1"   => payload_1
        }
        NyxNodes::commitObject(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNodes::toString(item)
    def self.toString(item)
        "(NyxNode) (#{Payload1::toString(item["payload_1"])}) #{item["description"]}"
    end

    # NyxNodes::toStringForSearchResult(item)
    def self.toStringForSearchResult(item)
        nwt = item["networkType"] ? ": #{item["networkType"]}" : ""
        parents = NetworkLocalViews::parents(item["uuid"])
        parentsstr = 
            if parents.size > 0 then
                " #{parents.map{|i| "(#{i["description"]})".green }.join(" ")}"
            else
                ""
            end
        "(NyxNode) (#{Payload1::toString(item["payload_1"])}) #{item["description"]}#{parentsstr}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # NyxNodes::access(item)
    def self.access(item)
        puts item["description"]
        Payload1::access(item["payload_1"])
    end

    # NyxNodes::edit(item) # null or item
    def self.edit(item)
        payload_1v2 = Payload1::edit(item["payload_1"])
        return nil if payload_1v2.nil?
        item["payload_1"] = payload_1v2
        NyxNodes::commitObject(item)

        # So now that the object has been sent to disk, we need to consider that 
        # a QuantumDrop could have been updated and propagate the changes to disk.

        if payload_1v2["type"] == "NxGridFiber" then
            NxGridFiberFileSystemIntegration::propagateFiber(payload_1v2["fiber"])
        end

        item
    end

    # NyxNodes::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = NyxNodes::getItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts NyxNodes::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "payload: #{Payload1::toString(item["payload_1"])}".yellow

            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            parents = NetworkLocalViews::parents(item["uuid"])
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

            entities = NetworkLocalViews::relateds(item["uuid"])
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

            children = NetworkLocalViews::children(item["uuid"])
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
            puts "<n> | access | description | name | datetime | edit | network type | payload | expose | destroy".yellow
            puts "line | link | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid | acquire children by uuid".yellow
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
                i2 = NxLines::issue(line)
                NetworkLocalViews::arrow(item["uuid"], i2["uuid"])
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

            if Interpreting::match("payload", input) then
                payload_1 = Payload1::interactivelyMakeNewOrNull()
                next if payload_1.nil?
                item["payload_1"] = payload_1
                NyxNodes::commitObject(item)
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

            if input == "network type" then
                networkType = NyxNodes::interactivelySelectType1s()
                item["type_1"] = networkType
                NyxNodes::commitObject(item)
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

            if Interpreting::match("select children; move to uuid", input) then
                NetworkShapeAroundNode::selectChildrenAndMoveToUUID(item)
                next
            end

            if input == "acquire children by uuid" then
                targetuuids = []
                loop {
                    targetuuid = LucilleCore::askQuestionAnswerAsString("uuid (empty to stop): ")
                    break if targetuuid == ""
                    targetuuids << targetuuid
                }
                targetuuids.each{|targetuuid|
                    NetworkLocalViews::arrow(item["uuid"], targetuuid)
                }
            end

        }
    end
end
