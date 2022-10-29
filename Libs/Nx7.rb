
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::items()
    def self.items()
        TheBook::getObjects("#{Config::pathToDataCenter()}/Nx7")
    end

    # Nx7::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        TheBook::getObjectOrNull("#{Config::pathToDataCenter()}/Nx7", uuid)
    end

    # Nx7::commitObject(object)
    def self.commitObject(object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        TheBook::commitObjectToDisk("#{Config::pathToDataCenter()}/Nx7", object)
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        TheBook::destroy("#{Config::pathToDataCenter()}/Nx7", uuid)
    end

    # ------------------------------------------------
    # Makers

    # Nx7::networkType1()
    def self.networkType1()
        ["Information", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # Nx7::interactivelySelectNetworkType1()
    def self.interactivelySelectNetworkType1()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("networkType", Nx7::networkType1())
        return type if type
        Nx7::interactivelySelectNetworkType1()
    end

    # Nx7::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        networkType1 = Nx7::interactivelySelectNetworkType1()
        state = GridState::interactivelyBuildGridStateOrNull() || GridState::nullGridState()
        item = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "Nx7",
            "unixtime"     => Time.new.to_f,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => [state],
            "comments"     => []
        }
        FileSystemCheck::fsck_Nx7(item, SecureRandom.hex, true)
        item
    end

    # Nx7::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        networkType1 = "Information"
        states = [GridState::fileGridState(filepath)]
        item = {
            "uuid"         => uuid,
            "mikuType"     => "NyxNode",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => states
        }
        Nx7::commitObject(item)
        item
    end

    # Nx7::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        if File.file?(location) then
            return Nx7::issueNewUsingFile(location)
        end
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        networkType1 = "Information"
        states = [GridState::directoryPathToNxDirectoryContentsGridState(location)]
        item = {
            "uuid"         => uuid,
            "mikuType"     => "NyxNode",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => states
        }
        Nx7::commitObject(item)
        item
    end

    # ------------------------------------------------
    # Data

    # Nx7::toString(item)
    def self.toString(item)
        state = item["states"].last
        "(NyxNode) #{GridState::toString(item["states"].last)} #{item["description"]}"
    end

    # ------------------------------------------------
    # Operations

    # Nx7::access(item)
    def self.access(item)
        puts item["description"]
        GridState::access(item["states"].last)
    end

    # Nx7::edit(item) # null or item
    def self.edit(item)
        states = item["states"]
        state2 = GridState::edit(states.last)
        return nil if state2.nil?
        states << state2
        item["states"] = states
        Nx7::commitObject(item)
        # Todo: We might need to propagate this to disk...
        item
    end

    # Nx7::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = Nx7::getItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts Nx7::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "payload: #{GridState::toString(item["states"].last)}".yellow

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
            puts "<n> | access | description | datetime | edit | network type | set state | expose | destroy".yellow
            puts "line | link | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid | acquire children by uuid".yellow
            puts "[grid points] make nyx7".yellow
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
                Nx7::access(item)
                next
            end
            if input == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                i2 = NxLines::issue(line)
                NetworkLocalViews::arrow(item["uuid"], i2["uuid"])
                next
            end

            if input == "make nyx7" then
                description = item["description"]
                safedescription = CommonUtils::sanitiseStringForFilenaming(description)
                filename = "#{safedescription}.nyx7"
                filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
                File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item))}
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
                item = Nx7::edit(item)
                next if item.nil?
                puts JSON.pretty_generate(item)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("set state", input) then
                state = GridState::interactivelyBuildGridStateOrNull()
                next if state.nil?
                item["states"] << state
                Nx7::commitObject(item)
                next
            end

            if input == "link" then
                NetworkShapeAroundNode::architectureAndRelate(item)
                next
            end

            if input == "parent" then
                NetworkShapeAroundNode::architectureAndSetAsParent(item)
                next
            end

            if input == "network type" then
                networkType1 = Nx7::interactivelySelectNetworkType1()
                item["networkType1"] = networkType1
                Nx7::commitObject(item)
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
