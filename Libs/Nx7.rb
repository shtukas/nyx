
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::items()
    def self.items()
        items = []
        Find.find("/Users/pascal/Galaxy") do |path|
            next if File.basename(path)[-4, 4] != ".Nx7"
            filepath1 = path
            items << Nx5Ext::readFileAsAttributesOfObject(filepath1)
        end
        items
    end

    # Nx7::filepath(uuid)
    def self.filepath(uuid)
        Find.find("/Users/pascal/Galaxy") do |path|
            next if File.basename(path)[-4, 4] != ".Nx7"
            filepath1 = path
            item = Nx5Ext::readFileAsAttributesOfObject(filepath1)
            next if item["uuid"] != uuid
            return filepath1
        end

        if filepath.nil? then
            puts "Cannot find a Nx7 path for uuid: #{uuid}. Building a filepath:"
            folder = LucilleCore::askQuestionAnswerAsString("parent folder: ")
            fileDescription = LucilleCore::askQuestionAnswerAsString("file description: ")
            filepath = "#{folder}/#{fileDescription}.Nx7"
        end

        filepath
    end

    # Nx7::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Nx7::filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Nx7::commit(object)
    def self.commit(object)
        FileSystemCheck::fsck_MikuTypedItem(object, false)
        filepath = Nx7::filepath(object["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, object["uuid"])
        end
        object.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        filepath = Nx7::filepath(object["uuid"])
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # ------------------------------------------------
    # Operators

    # Nx7::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Nx7::filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
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
        filepath = Nx7::filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # Nx7::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: 520a0efa-48a1-4b81-82fb-f61760af7329)" if item["mikuType"] != "Nx7"
        filepath = Nx7::filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        ElizabethNx5.new(filepath)
    end

    # Nx7::access(item)
    def self.access(item)
        folderpath = "#{Config::pathToDesktop()}/#{CommonUtils::sanitiseStringForFilenaming(Nx7::toString(item))}-#{SecureRandom.hex(2)}"
        FileUtils.mkdir(folderpath)
        Nx7::exportItemAtFolder(object, folderpath, 1)
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
            puts "<n> | access | description | datetime | payload | expose | destroy".yellow
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
    # Openess Manager

    # Nx7::exportItemAtFolder(item, location, depth)
    def self.exportItemAtFolder(item, location, depth)
        if !File.exists?(location) then
            raise "(error: e0398a01-83d7-418d-ac63-bdf1b600d269) location doesn't exist: #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 24b89a73-4033-4184-b12d-ddee240e3020) location exists but is not a directory: #{location}"
        end

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            operator = Nx7::getElizabethOperatorForItem(item)
            state = nx7Payload["state"]
            GridState::exportStateAtFolder(operator, state, location)
            return
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            Nx7::children(item).each{|child|
                filepath1 = Nx7::filepath(child["uuid"])
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
end
