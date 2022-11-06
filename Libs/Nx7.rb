
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::allNx70FilepathsFromFsRootEnumerator(fsroot)
    def self.allNx70FilepathsFromFsRootEnumerator(fsroot)
        Enumerator.new do |filepaths|
            Find.find(fsroot) do |path|
                next if File.basename(path)[-4, 4] != ".Nx7"
                filepaths << path
            end
        end
    end

    # Nx7::itemsFromFsRootEnumerator(fsroot)
    def self.itemsFromFsRootEnumerator(fsroot)
        Enumerator.new do |items|
            Nx7::allNx70FilepathsFromFsRootEnumerator(fsroot).each{|filepath|
                items << Nx5Ext::readFileAsAttributesOfObject(filepath)
            }
        end
    end

    # Nx7::galaxyFilepathsEnumerator()
    def self.galaxyFilepathsEnumerator()
        Nx7::allNx70FilepathsFromFsRootEnumerator(Config::pathToGalaxy())
    end

    # Nx7::galaxyItemsEnumerator()
    def self.galaxyItemsEnumerator()
        Nx7::itemsFromFsRootEnumerator(Config::pathToGalaxy())
    end

    # Nx7::galaxyFilepathsForUUIDEnumerator(uuid)
    def self.galaxyFilepathsForUUIDEnumerator(uuid)
        Enumerator.new do |filepaths|
            Nx7::allNx70FilepathsFromFsRootEnumerator(Config::pathToGalaxy()).each{|filepath|
                item = Nx5Ext::readFileAsAttributesOfObject(filepath)
                if item["uuid"] == uuid then
                    filepaths << filepath
                end
            }
        end
    end

    # Nx7::oneFilepathToNx7OrNull(uuid, shouldCreateOneNx7IfMissing)
    def self.oneFilepathToNx7OrNull(uuid, shouldCreateOneNx7IfMissing)
        Nx7::galaxyFilepathsForUUIDEnumerator(uuid).each{|filepath|
            return filepath # we return the first one
        }

        if shouldCreateOneNx7IfMissing then
            filepath = nil

            loop {
                puts "Cannot find a Nx7 path for uuid: #{uuid}. Building a filepath:"
                folder = LucilleCore::askQuestionAnswerAsString("parent folder: ")
                if !File.exists?(folder) then
                    puts "The folder you provided doesn't exists"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                if !File.directory?(folder) then
                    puts "The path you provided is not a directory"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                fileDescription = LucilleCore::askQuestionAnswerAsString("file description: ")
                filepath = "#{folder}/#{fileDescription}.Nx7"
                Nx5::issueNewFileAtFilepath(filepath, uuid)
                break
            }

            return filepath
        end

        nil
    end

    # Nx7::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Nx7::oneFilepathToNx7OrNull(uuid, false)
        return nil if filepath.nil?
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Nx7::commit(object)
    def self.commit(object)
        FileSystemCheck::fsck_MikuTypedItem(object, false)
        filepath = Nx7::oneFilepathToNx7OrNull(object["uuid"], true)
        if filepath.nil? then
            raise "Could not commit item #{JSON.pretty_generate(object)} due to missing filepath to commit to"
        end
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, object["uuid"])
        end
        object.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        filepath = Nx7::oneFilepathToNx7OrNull(object["uuid"], false)
        return if filepath.nil?
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # ------------------------------------------------
    # Elizabeth

    # Nx7::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Nx7::oneFilepathToNx7OrNull(uuid, true)
        ElizabethNx5.new(filepath)
    end

    # Nx7::operatorForItem(item)
    def self.operatorForItem(item)
        Nx7::operatorForUUID(item["uuid"])
    end

    # ------------------------------------------------
    # Makers

    # Nx7::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        operator = Nx7::operatorForUUID(uuid)
        nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_f,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "comments"      => [],
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
        }
        FileSystemCheck::fsck_Nx7(operator, item, true)
        Nx7::commit(item)
        item
    end

    # Nx7::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        operator = Nx7::operatorForUUID(uuid)
        nx7Payload = Nx7Payloads::makeDataFile(operator, filepath)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
        }
        Nx7::commit(item)
        item
    end

    # Nx7::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        if File.file?(location) then
            return Nx7::issueNewUsingFile(location)
        end
        uuid = SecureRandom.uuid
        operator = Nx7::operatorForUUID(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        nx7Payload = Nx7Payloads::makeDataNxDirectoryContents(operator, location)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
        }
        Nx7::commit(item)
        item
    end

    # ------------------------------------------------
    # Data

    # Nx7::toString(item)
    def self.toString(item)
        "(Nx7) (#{item["nx7Payload"]["type"]}) #{item["description"]}"
    end

    # Nx7::toStringForNx7Landing(item)
    def self.toStringForNx7Landing(item)
        "(node) #{item["description"]}"
    end

    # Nx7::parents(item)
    def self.parents(item)
        item["parentsuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # Nx7::relateds(item)
    def self.relateds(item)
        item["relatedsuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # Nx7::children(item)
    def self.children(item)
        item["childrenuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # ------------------------------------------------
    # Network Topology

    # Nx7::relate(item1, item2)
    def self.relate(item1, item2)
        item1["relatedsuuids"] = (item1["relatedsuuids"] + [item2["uuid"]]).uniq
        Nx7::commit(item1)
        item2["relatedsuuids"] = (item2["relatedsuuids"] + [item1["uuid"]]).uniq
        Nx7::commit(item2)
    end

    # Nx7::arrow(item1, item2)
    def self.arrow(item1, item2)
        item1["childrenuuids"] = (item1["childrenuuids"] + [item2["uuid"]]).uniq
        Nx7::commit(item1)
        item2["parentsuuids"] = (item2["parentsuuids"] + [item1["uuid"]]).uniq
        Nx7::commit(item2)
    end

    # Nx7::detach(item1, item2)
    def self.detach(item1, item2)
        item1["parentsuuids"].delete(item2["uuid"])
        item1["relatedsuuids"].delete(item2["uuid"])
        item1["childrenuuids"].delete(item2["uuid"])
        Nx7::commit(item1)

        item2["parentsuuids"].delete(item1["uuid"])
        item2["relatedsuuids"].delete(item1["uuid"])
        item2["childrenuuids"].delete(item1["uuid"])
        Nx7::commit(item2)
    end

    # ------------------------------------------------
    # Operations

    # Nx7::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = Nx7::oneFilepathToNx7OrNull(uuid, true)
        ElizabethNx5.new(filepath)
    end

    # Nx7::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: 520a0efa-48a1-4b81-82fb-f61760af7329)" if item["mikuType"] != "Nx7"
        filepath = Nx7::oneFilepathToNx7OrNull(item["uuid"], true)
        ElizabethNx5.new(filepath)
    end

    # Nx7::access(item)
    def self.access(item)

        puts "running peer to peer sync..."
        item = Nx7::syncWithPeers(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            GridState::access(operator, state)
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            puts "This is a navigation node, there isn't an access per se. I could send you to the .Nx7 in galaxy if you want."
            if LucilleCore::askQuestionAnswerAsBoolean("Go to fs ? : ") then
                filepaths = Nx7::galaxyFilepathsForUUIDEnumerator(item["uuid"]).to_a
                if filepaths.size == 1 then
                    filepath = filepaths.first
                    system("open '#{filepath}'")
                else
                    filepath = LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", filepaths)
                    if filepath then
                        system("open '#{filepath}'")
                    end
                end
            end
        end
    end

    # Nx7::edit(item)
    def self.edit(item)
        puts "running peer to peer sync..."
        item = Nx7::syncWithPeers(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            state2 = GridState::edit(operator, state)
            if state2 then
                nx7Payload["state"] = state2
                item["nx7Payload"] = nx7Payload
                Nx7::commit(item)
                item = Nx7::syncWithPeers(item)
                Nx7::reExportAtAllCurrentlyExportedLocations(item)
            end
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            puts "This is a navigation node, there isn't an edit per se."
            LucilleCore::pressEnterToContinue()
        end
    end

    # Nx7::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = Nx7::itemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts Nx7::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "payload: #{item["nx7Payload"]["type"]}".yellow

            item["comments"].each{|comment|
                puts "[comment] #{comment}"
            }

            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            parents = Nx7::parents(item)
            if parents.size > 0 then
                puts ""
                puts "parents: "
                parents
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            entities = Nx7::relateds(item)
            if entities.size > 0 then
                puts ""
                puts "related: "
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            children = Nx7::children(item)
            if children.size > 0 then
                puts ""
                puts "children: "
                children
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            puts ""
            puts "<n> | access | edit | description | datetime | payload | expose | destroy".yellow
            puts "comment | related | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid".yellow
            puts "[grid points] export at folder".yellow
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

            if Interpreting::match("edit", input) then
                Nx7::edit(item)
                next
            end

            if input == "comment" then
                comment = LucilleCore::askQuestionAnswerAsString("comment: ")
                item["comments"] << comment
                Nx7::commit(item)
                next
            end

            if input == "export at folder" then
                folder = LucilleCore::askQuestionAnswerAsString("export folder: ")
                Nx7::exportItemAtFolder(item, folder, 1)
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

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("payload", input) then
                operator = Nx7::operatorForItem(item)
                nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
                item["nx7Payload"] = nx7Payload
                Nx7::commit(item)
                next
            end

            if input == "related" then
                NetworkShapeAroundNode::architectureAndRelate(item)
                next
            end

            if input == "parent" then
                NetworkShapeAroundNode::architectureAndSetAsParent(item)
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

        }
    end

    # ------------------------------------------------
    # Export Manager

    # Nx7::exportItemAtFolder(item, location, depth)
    def self.exportItemAtFolder(item, location, depth)
        if !File.exists?(location) then
            raise "(error: e0398a01-83d7-418d-ac63-bdf1b600d269) location doesn't exist: #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 24b89a73-4033-4184-b12d-ddee240e3020) location exists but is not a directory: #{location}"
        end

        item = Nx7::syncWithPeers(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            operator = Nx7::getElizabethOperatorForItem(item)
            state = nx7Payload["state"]
            GridState::exportStateAtFolder(operator, state, location)
            return
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            Nx7::children(item).each{|child|
                filepath1 = Nx7::oneFilepathToNx7OrNull(child["uuid"], false)
                next if filepath1.nil?
                location1 = "#{location}/#{CommonUtils::sanitiseStringForFilenaming(item["description"])}.Nx7"
                FileUtils.cp(filepath1, location1)
                if depth > 0 then
                    location2 = "#{location}/#{CommonUtils::sanitiseStringForFilenaming(item["description"])}"
                    FileUtils.mkdir(location2)
                    Nx7::exportItemAtFolder(child, location2, depth-1)
                end
            }
            return
        end

        raise "(error: 54c37521-1b07-4e34-bc5a-ec3d7c46f1e8) type: #{nx7Payload["type"]}"
    end

    # Nx7::currentExportLocations(item)
    def self.currentExportLocations(item)
        Nx7::galaxyFilepathsForUUIDEnumerator(item["uuid"])
            .map{|filepath| filepath.gsub(".Nx7", "") }
            .select{|location| File.exists?(location) }
    end

    # Nx7::reExportAtAllCurrentlyExportedLocations(item)
    def self.reExportAtAllCurrentlyExportedLocations(item)
        Nx7::currentExportLocations(item).each{|location|
            Nx7::exportItemAtFolder(item, location, 1)
        }
    end

    # Nx7::getPopulatedExportLocationForItemAndMakeSureItIsUniqueOrNull(item, preferenceInstanceFilepath)
    def self.getPopulatedExportLocationForItemAndMakeSureItIsUniqueOrNull(item, preferenceInstanceFilepath)
        currentExportLocations = Nx7::currentExportLocations(item)
        if currentExportLocations.size == 0 then
            location = preferenceInstanceFilepath.gsub(".Nx7", "")
            FileUtils.mkdir(location)
            Nx7::exportItemAtFolder(item, location, 1)
            return location
        end

        if currentExportLocations.size == 1 then
            location1 = currentExportLocations.first
            location2 = preferenceInstanceFilepath.gsub(".Nx7", "")
            if location1 != location2 then
                puts "You are targetting this instance: #{preferenceInstanceFilepath}"
                puts "There is an export folder here: #{location1}"
                puts "I am sending you there"
                LucilleCore::pressEnterToContinue()
            end
            return location1
        end

        if currentExportLocations.size > 1 then
            puts "You are targetting this instance: #{preferenceInstanceFilepath}"
            puts "I can see more than one export folders:"
            currentExportLocations.each{|location|
                puts "    - #{location}"
            }
            puts "Please reduce to one and continue"
            LucilleCore::pressEnterToContinue()
            return Nx7::getPopulatedExportLocationForItemAndMakeSureItIsUniqueOrNull(item, preferenceInstanceFilepath)
        end
    end

    # ------------------------------------------------
    # Multi Instance Sync

    # Nx7::peerToPeerSync(uuid)
    def self.peerToPeerSync(uuid)
        Nx7::galaxyFilepathsForUUIDEnumerator(uuid)
            .to_a
            .combination(2)
            .each{|filepath1, filepath2|
                Nx5Ext::contentsMirroring(filepath1, filepath2)
            }
    end

    # Nx7::syncWithPeers(item)
    def self.syncWithPeers(item)
        Nx7::peerToPeerSync(item["uuid"])
        Nx7::itemOrNull(item["uuid"])
    end

    # Nx7::globalSync()
    def self.globalSync()
        mapping = {}
        Nx7::galaxyFilepathsEnumerator()
            .each{|filepath|
                item = Nx5Ext::readFileAsAttributesOfObject(filepath)
                uuid = item["uuid"]
                if mapping[uuid].nil? then
                    mapping[uuid] = filepath
                else
                    puts "Global Sync:"
                    puts "    - #{mapping[uuid]}"
                    puts "    - #{filepath}"
                    Nx5Ext::contentsMirroring(mapping[uuid], filepath)
                end
            }
    end
end
