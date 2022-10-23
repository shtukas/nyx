
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
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        TheBook::commitObjectToDisk("#{Config::pathToDataCenter()}/NyxNode", object)
    end

    # NyxNodes::destroy(uuid)
    def self.destroy(uuid)
        TheBook::destroy("#{Config::pathToDataCenter()}/NyxNode", uuid)
    end

    # ----------------------------------------------------------------------
    # Makers

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
        nxst1 = NxSt1::interactivelyMake()
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nxst1"       => nxst1
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
        nxst1 = NxSt1::makeNewUsingLocation(location)
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nxst1"       => nxst1
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
        nxst1 = NxSt1::makeNewUsingFile(filepath)
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nxst1"       => nxst1
        }
        NyxNodes::commitObject(item)
        item
    end

    # NyxNodes::interactivelyIssueNewPureDataTextOrNull()
    def self.interactivelyIssueNewPureDataTextOrNull()
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nxst1 = NxSt1::makeNewText()

        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "mikuType"    => "NyxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nxst1"       => nxst1
        }

        NyxNodes::commitObject(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNodes::toString(item)
    def self.toString(item)
        "(NyxNode) (#{NxSt1::toString(item["nxst1"])}) #{item["description"]}"
    end

    # NyxNodes::toStringForSearchResult(item)
    def self.toStringForSearchResult(item)
        nwt = item["networkType"] ? ": #{item["networkType"]}" : ""
        parents = NetworkEdges::parents(item["uuid"])
        parentsstr = 
            if parents.size > 0 then
                " #{parents.map{|i| "(#{i["description"]})".green }.join(" ")}"
            else
                ""
            end
        "(NyxNode) (#{NxSt1::toString(item["nxst1"])}) #{item["description"]}#{parentsstr}"
    end

    # NyxNodes::getNyxNodeByQuantumDropUUIDOrNull(dropuuid)
    def self.getNyxNodeByQuantumDropUUIDOrNull(dropuuid)
        NyxNodes::items()
            .select{|item| item["nxst1"]["type"] == "NxQuantumDrop" }
            .select{|item| item["nxst1"]["drop"]["uuid"] == dropuuid }
            .first
    end

    # ----------------------------------------------------------------------
    # Operations

    # NyxNodes::access(item)
    def self.access(item)
        puts item["description"]
        NxSt1::access(item["nxst1"])
    end

    # NyxNodes::edit(item) # item
    def self.edit(item)
        nxst1v2 = NxSt1::edit(item["nxst1"])
        return if nxst1v2.nil?
        item["nxst1"] = nxst1v2
        NyxNodes::commitObject(item)

        # So now that the object has been sent to disk, we need to consider that 
        # a QuantumDrop could have been updated and propagate the changes to disk.

        return if nxst1v2["type"] != "NxQuantumDrop"
        QuantumDrops::propagateQuantumDrop(nxst1v2["drop"])

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
            puts "<n> | access | description | name | datetime | nxst1 | edit | network type | expose | destroy".yellow
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

            if Interpreting::match("nxst1", input) then
                nxst1 = NxSt1::interactivelyMakeNewOrNull()
                next if nxst1.nil?
                item["nxst1"] = nxst1
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
                networkType = NyxNodes::interactivelySelectNetworkType()
                item["networkType"] = networkType
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
                    NetworkEdges::arrow(item["uuid"], targetuuid)
                }
            end

        }
    end
end
