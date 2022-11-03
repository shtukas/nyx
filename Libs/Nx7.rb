
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::allNx7FilepathsEnumerator()
    def self.allNx7FilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find(Config::pathToDesktop()) do |path|
                if path[-4, 4] == ".Nx7" then
                    filepaths << path
                end
            end
            Find.find(Config::pathToGalaxy()) do |path|
                if path[-4, 4] == ".Nx7" then
                    filepaths << path
                end
            end
        end
    end

    # Nx7::items()
    def self.items()
        Nx7::allNx7FilepathsEnumerator()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # Nx7::allInstanceFilpathsEnumerator(uuid)
    def self.allInstanceFilpathsEnumerator(uuid)
        Enumerator.new do |filepaths|
            Nx7::allNx7FilepathsEnumerator().each{|filepath|
                if Nx5Ext::readFileAsAttributesOfObject(filepath)["uuid"] == uuid then
                    filepaths << filepath
                end
            }
        end
    end

    # Nx7::getFilepathOrNull(uuid)
    def self.getFilepathOrNull(uuid)

        nx8 = Nx8::getItemOrNull(uuid)
        if nx8 then
            nx8["locations"].each{|filepath|
                if File.exists?(filepath) then
                    return filepath
                end
            }
        end

        filepaths = Nx7::allInstanceFilpathsEnumerator(uuid).to_a

        if filepaths.size > 0 then
            Nx8::updateNx8WithLocations(uuid, filepaths)
            return filepaths.first
        end

        nil
    end

    # Nx7::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = Nx7::getFilepathOrNull(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Nx7::commitObject(object)
    def self.commitObject(object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        filepath = Nx7::getFilepathOrNull(object["uuid"])
        if filepath.nil? then
            filepath = "#{Config::pathToGalaxy()}/DataHub/Misc-Nx7s/#{object["uuid"]}.Nx7"
            Nx5::issueNewFileAtFilepath(filepath, object["uuid"])
        end
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, object["uuid"])
        end
        object.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
        Nx8::updateNx8FromNx7(filepath)
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        Nx7::allInstanceFilpathsEnumerator(uuid).each{|filepath|
            FileUtils.rm(filepath)
        }
    end

    # ------------------------------------------------

    # Nx7::interactivelySelectFilepathForNewNx7File(uuid)
    def self.interactivelySelectFilepathForNewNx7File(uuid)
        choice = LucilleCore::selectEntityFromListOfEntitiesOrNull("location", ["misc folder (default)", "desktop (for manual positioning)"])
        if choice.nil? or choice == "misc folder (default)" then
            return "#{Config::pathToGalaxy()}/DataHub/Misc-Nx7s/#{uuid}.Nx7"
        end
        "#{Config::pathToDesktop()}/#{uuid}.Nx7"
    end

    # Nx7::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Nx7::getFilepathOrNull(uuid)
        if filepath.nil? then
            filepath = Nx7::interactivelySelectFilepathForNewNx7File(uuid)
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
        uuid = SecureRandom.uuid
        operator = Nx7::operatorForUUID(uuid)
        state = GridState::interactivelyBuildGridStateOrNull(operator) || GridState::nullGridState(operator)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_f,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "networkType1"  => networkType1,
            "states"        => [state],
            "comments"      => [],
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
        }
        FileSystemCheck::fsck_Nx7(operator, item, SecureRandom.hex, true)
        Nx7::commitObject(item)
        item
    end

    # Nx7::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        networkType1 = "Information"
        operator = Nx7::operatorForUUID(uuid)
        states = [GridState::fileGridState(operator, filepath)]
        item = {
            "uuid"         => uuid,
            "mikuType"     => "Nx7",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => states,
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
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
        operator = Nx7::operatorForUUID(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        networkType1 = "Information"
        states = [GridState::directoryPathToNxDirectoryContentsGridState(operator, location)]
        item = {
            "uuid"         => uuid,
            "mikuType"     => "Nx7",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => states,
            "parentsuuids"  => [],
            "relatedsuuids" => [],
            "childrenuuids" => []
        }
        Nx7::commitObject(item)
        item
    end

    # ------------------------------------------------
    # Data

    # Nx7::toString(item)
    def self.toString(item)
        state = item["states"].last
        "(Nx7) #{GridState::toString(item["states"].last)} #{item["description"]}"
    end

    # Nx7::parents(item)
    def self.parents(item)
        item["parentsuuids"]
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

    # Nx7::relateds(item)
    def self.relateds(item)
        item["relatedsuuids"]
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

    # Nx7::children(item)
    def self.children(item)
        item["childrenuuids"]
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

    # ------------------------------------------------
    # Network Topology

    # Nx7::relate(item1, item2)
    def self.relate(item1, item2)
        item1["relatedsuuids"] = (item1["relatedsuuids"] + [item2["uuid"]]).uniq
        Nx7::commitObject(item1)
        item2["relatedsuuids"] = (item2["relatedsuuids"] + [item1["uuid"]]).uniq
        Nx7::commitObject(item2)
    end

    # Nx7::arrow(item1, item2)
    def self.arrow(item1, item2)
        item1["childrenuuids"] = (item1["childrenuuids"] + [item2["uuid"]]).uniq
        Nx7::commitObject(item1)
        item2["parentsuuids"] = (item2["parentsuuids"] + [item1["uuid"]]).uniq
        Nx7::commitObject(item2)
    end

    # Nx7::detach(item1, item2)
    def self.detach(item1, item2)
        item1["parentsuuids"].delete(item2["uuid"])
        item1["relatedsuuids"].delete(item2["uuid"])
        item1["childrenuuids"].delete(item2["uuid"])
        Nx7::commitObject(item1)

        item2["parentsuuids"].delete(item1["uuid"])
        item2["relatedsuuids"].delete(item1["uuid"])
        item2["childrenuuids"].delete(item1["uuid"])
        Nx7::commitObject(item2)
    end

    # ------------------------------------------------
    # Operations

    # Nx7::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = Nx7::getFilepathOrNull(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # Nx7::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: 520a0efa-48a1-4b81-82fb-f61760af7329)" if item["mikuType"] != "Nx7"
        filepath = Nx7::getFilepathOrNull(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        ElizabethNx5.new(filepath)
    end

    # Nx7::access(item)
    def self.access(item)
        filepath = Nx7::getFilepathOrNull(item["uuid"])
        if filepath.nil? then
            puts "I could not find an instance filepath for this item"
            LucilleCore::pressEnterToContinue()
            return
        end
        folderpath = Nx7::getCompanionFolderpathForContentsOrNull_WithPolicyFeatures(filepath)
        if folderpath.nil? then
            puts "I can see an instance item for this Nx7 item, but I could not recover a companion folder"
            LucilleCore::pressEnterToContinue()
            return
        end
        if LucilleCore::locationsAtFolder(folderpath).size > 0 then
            puts "I am sending to an already open instance"
            LucilleCore::pressEnterToContinue()
            system("open '#{folderpath}'")
            return
        end
        object = Nx5Ext::readFileAsAttributesOfObject(filepath)
        Nx7::exportNx7AtLocation(object, folderpath)
        system("open '#{folderpath}'")
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

            nx8 = Nx8::getItemOrNull(uuid)
            if nx8 then
                nx8["locations"].each{|filepath|
                    puts "instance: #{filepath}".yellow
                }
            end

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
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
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
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
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
                        puts "    #{store.prefixString()} #{PolyFunctions::toString(entity)}"
                    }
            end

            puts ""
            puts "<n> | access | description | datetime | network type | set state | expose | destroy".yellow
            puts "line | related | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid".yellow
            puts "[grid points] make Nx9".yellow
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
                Nx7::arrow(item, i2)
                next
            end

            if input == "make Nx9" then
                description = item["description"]
                safedescription = CommonUtils::sanitiseStringForFilenaming(description)
                filename = "#{safedescription}.Nx9"
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

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("set state", input) then
                operator = Nx7::operatorForItem(item)
                state = GridState::interactivelyBuildGridStateOrNull(operator)
                next if state.nil?
                item["states"] << state
                Nx7::commitObject(item)
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

        }
    end

    # ------------------------------------------------
    # Openess Manager

    # Nx7::nx7InstanceIsOpen(filepath)
    def self.nx7InstanceIsOpen(filepath)
        exportFolderpath = filepath.gsub(".Nx7", "")
        File.exists?(exportFolderpath)
    end

    # Nx7::getOpenLocations(uuid)
    def self.getOpenLocations(uuid)
        Nx7::allInstanceFilpathsEnumerator(uuid)
            .select{|filepath| Nx7::nx7InstanceIsOpen(filepath) }
            .map{|filepath|
                filepath.gsub(".Nx7", "")
            }
    end

    # Nx7::nx7IsOpenAnywhere(uuid)
    def self.nx7IsOpenAnywhere(uuid)
        Nx7::getOpenLocations(uuid).size > 0
    end

    # Nx7::exportNx7AtLocation(object, location)
    def self.exportNx7AtLocation(object, location)
        state = object["states"].last
        operator = Nx7::getElizabethOperatorForItem(object)
        GridState::exportStateAtFolder(operator, object["states"].last, location)
    end

    # Nx7::getCompanionFolderpathForContentsOrNull_WithPolicyFeatures(filepath1)
    def self.getCompanionFolderpathForContentsOrNull_WithPolicyFeatures(filepath1)

        nx7 = Nx5Ext::readFileAsAttributesOfObject(filepath1)
        folderpaths = Nx7::getOpenLocations(nx7["uuid"])

        if folderpaths.size == 0 then
            folderpath = filepath1.gsub(".Nx7", "")
            FileUtils.mkdir(folderpath)
            return folderpath
        end

        if folderpaths.size == 1 then
            return folderpaths.first
        end

        puts "You are trying to open instance '#{filepath1}', but the following instances are all open:"
        folderpaths.each{|folderpath|
            puts "    - #{folderpath}"
        }
        puts "Please sort that out..."
        LucilleCore::pressEnterToContinue()

        return nil
    end
end
