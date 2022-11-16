
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::filepaths()
    def self.filepaths()
        Enumerator.new do |filepaths|
            Find.find(Config::pathToDesktop()) do |path|
                if File.basename(path)[-4, 4] == ".Nx7" then
                    filepaths << path
                end
            end
            Find.find(Config::pathToGalaxy()) do |path|
                if File.basename(path)[-4, 4] == ".Nx7" then
                    filepaths << path
                end
            end
        end
    end

    # Nx7::itemsEnumerator()
    def self.itemsEnumerator()
        Enumerator.new do |items|
            Nx7::filepaths().each{|filepath|
                items << Nx5Ext::readFileAsAttributesOfObject(filepath)
            }
        end
    end

    # Nx7::newFilepathOnDesktop(uuid)
    def self.newFilepathOnDesktop(uuid)
        filepath = "#{Config::pathToDesktop()}/#{uuid}.Nx7"
        Nx5::issueNewFileAtFilepath(filepath, uuid)
        filepath
    end

    # Nx7::trueIfFilepathIsInstanceOfGivenUUID(filepath, uuid)
    def self.trueIfFilepathIsInstanceOfGivenUUID(filepath, uuid)
        return false if !File.exists?(filepath)
        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        return false if item["uuid"].nil?
        item["uuid"] == uuid
    end

    # Nx7::existingItemFilepathOrNull(uuid)
    def self.existingItemFilepathOrNull(uuid)
        nx7Locations = Nx7Locations::getNx7Locations(uuid)
        nx7Locations["locations"].each{|filepath|
            if Nx7::trueIfFilepathIsInstanceOfGivenUUID(filepath, uuid) then
                return filepath
            end
        }
        Nx7::filepaths().each{|filepath|
            if Nx7::trueIfFilepathIsInstanceOfGivenUUID(filepath, uuid) then
                return filepath
            end
        }
        nil
    end

    # Nx7::existingItemFilepathOrError(uuid)
    def self.existingItemFilepathOrError(uuid)
        filepath = Nx7::existingItemFilepathOrNull(uuid)
        return filepath if filepath
        raise "(error: 0b09f017-0423-4eb8-ac46-4a8966ad4ca6) could not determine presumably existing filepath for uuid: #{uuid}"
    end

    # Nx7::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Nx7::existingItemFilepathOrNull(uuid)
        return nil if filepath.nil?
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Nx7::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = Nx7::existingItemFilepathOrError(item["uuid"])
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
        Nx7EventDispatch::itemCreatedOrUpdated(item)
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        filepath = Nx7::existingItemFilepathOrNull(uuid)
        if filepath then
            FileUtils.rm(filepath)
        end
        Nx7EventDispatch::itemDeleted(uuid)
    end

    # ------------------------------------------------
    # Elizabeth

    # Nx7::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Nx7::existingItemFilepathOrError(uuid)
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
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
        puts JSON.pretty_generate(nx7Payload)
        FileSystemCheck::fsck_Nx7Payload(operator, nx7Payload, true)
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
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::makeDataFile(operator, filepath)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => []
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
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::makeDataNxDirectoryContents(operator, location)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => []
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
        return [] if item["nx7Payload"]["type"] == "Data"
        item["nx7Payload"]["childrenuuids"]
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
        # Type Data doesn't get children
        if item1["nx7Payload"]["type"] == "Data" then
            puts "We have a policy not to set a data carrier as parent"
            LucilleCore::pressEnterToContinue()
            return
        end
        item1["nx7Payload"]["childrenuuids"] = (item1["nx7Payload"]["childrenuuids"] + [item2["uuid"]]).uniq
        Nx7::commit(item1)
        item2["parentsuuids"] = (item2["parentsuuids"] + [item1["uuid"]]).uniq
        Nx7::commit(item2)
    end

    # Nx7::detach(item1, item2)
    def self.detach(item1, item2)
        item1["parentsuuids"].delete(item2["uuid"])
        item1["relatedsuuids"].delete(item2["uuid"])
        if item1["nx7Payload"]["type"] == "Data" then
            item1["nx7Payload"]["childrenuuids"].delete(item2["uuid"])
        else
            item1["childrenuuids"].delete(item2["uuid"])
        end
        Nx7::commit(item1)

        item2["parentsuuids"].delete(item1["uuid"])
        item2["relatedsuuids"].delete(item1["uuid"])
        if item2["nx7Payload"]["type"] == "Data" then
            item2["nx7Payload"]["childrenuuids"].delete(item1["uuid"])
        else
            item2["childrenuuids"].delete(item1["uuid"])
        end
        Nx7::commit(item2)
    end

    # ------------------------------------------------
    # Operations

    # Nx7::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = Nx7::existingItemFilepathOrError(uuid)
        ElizabethNx5.new(filepath)
    end

    # Nx7::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: 520a0efa-48a1-4b81-82fb-f61760af7329)" if item["mikuType"] != "Nx7"
        Nx7::getElizabethOperatorForUUID(item["uuid"])
    end

    # Nx7::access(item)
    def self.access(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            GridState::access(operator, state)
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            puts "This is a navigation node, there isn't an access per se."
            LucilleCore::pressEnterToContinue()
        end
    end

    # Nx7::edit(item)
    def self.edit(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            state2 = GridState::edit(operator, state)
            if state2 then
                nx7Payload["state"] = state2
                item["nx7Payload"] = nx7Payload
                Nx7::commit(item)
                Nx7::reExportAllItemCurrentlyExportedLocations(item)
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

            filepath = Nx7::existingItemFilepathOrError(uuid)
            puts "filepath: #{filepath}".yellow

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
            puts "<n> | access | edit | export | description | datetime | payload | expose | destroy".yellow
            puts "comment | related | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid".yellow
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
                puts "Your current payload is:"
                puts JSON.pretty_generate(item["nx7Payload"])
                next if !LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to override it ? : ")
                operator = Nx7::operatorForItem(item)
                nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
                puts "New payload:"
                next if !LucilleCore::askQuestionAnswerAsBoolean("Confirm : ")
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
end

class Nx7EventDispatch

    # Nx7EventDispatch::itemCreatedOrUpdated(item)
    def self.itemCreatedOrUpdated(item)
        SearchNyx::commitNx7ToNx20Cache(item)
    end

    # Nx7EventDispatch::itemDeleted(uuid)
    def self.itemDeleted(uuid)
        SearchNyx::deleteNx7FromNx20Cache(uuid)
    end
end

class Nx7Locations

    # Nx7Locations::getNx7Locations(uuid)
    def self.getNx7Locations(uuid)
        key = "2a01c6ab-aa94-499b-919f-afdf9af5ec3c:#{uuid}"
        item = XCache::getOrNull(key)
        if item.nil? then
            return {
                "itemuuid"  => uuid,
                "mikuType"  => "Nx7Locations",
                "locations" => []
            }
        end
        JSON.parse(item)
    end

    # Nx7Locations::commitNx7Locations(item)
    def self.commitNx7Locations(item)
        puts "Nx7Locations::commitNx7Locations(#{JSON.pretty_generate(item)})"
        key = "2a01c6ab-aa94-499b-919f-afdf9af5ec3c:#{item["itemuuid"]}"
        XCache::set(key, JSON.generate(item))
    end

    # Nx7Locations::registerFilepathForItem(uuid, filepath)
    def self.registerFilepathForItem(uuid, filepath)
        item1 = Nx7Locations::getNx7Locations(uuid)
        item2 = JSON.parse(JSON.generate(item1))
        item2["locations"] << filepath
        item2["locations"] = item2["locations"]
                                .select{|filepath| File.exists?(filepath) }
                                .sort
                                .uniq
        if item1.to_s != item2.to_s then
            Nx7Locations::commitNx7Locations(item2)
        end
    end

    # Nx7Locations::scanAndUpdate()
    def self.scanAndUpdate()
        Nx7::filepaths().each{|filepath|
            item = Nx5Ext::readFileAsAttributesOfObject(filepath)
            Nx7Locations::registerFilepathForItem(item["uuid"], filepath)
        }
    end
end

class Nx7InstanceTraces

    # Nx7InstanceTraces::getNx7InstanceTracesOrNull(filepath)
    def self.getNx7InstanceTracesOrNull(filepath)
        key = "bc8c2901-17de-490c-b429-94308ba221b5:#{filepath}"
        item = XCache::getOrNull(key)
        return nil if item.nil?
        JSON.parse(item)
    end

    # Nx7InstanceTraces::commitInstanceItem(filepath, item)
    def self.commitInstanceItem(filepath, item)
        key = "bc8c2901-17de-490c-b429-94308ba221b5:#{filepath}"
        XCache::set(key, JSON.generate(item))
    end

    # Nx7InstanceTraces::computeForFilepath(filepath)
    def self.computeForFilepath(filepath)
        eventsTrace = Digest::SHA1.hexdigest(Nx5::getOrderedEvents(filepath).map{|event| JSON.generate(event) }.join(":"))
        exportTrace = nil
        exportFolder = filepath.gsub(".Nx7", "")
        if File.exists?(exportFolder) then
            exportTrace = CommonUtils::locationTraceWithoutTopName(exportFolder)
        end
        {
            "filepath"    => filepath,
            "eventsTrace" => eventsTrace,
            "exportTrace" => exportTrace
        }
    end

    # Nx7InstanceTraces::issueNewNx7InstanceTracesForFilepath(filepath)
    def self.issueNewNx7InstanceTracesForFilepath(filepath)
        item = Nx7InstanceTraces::computeForFilepath(filepath)
        Nx7InstanceTraces::commitInstanceItem(filepath, item)
    end
end

class AutomaticNx7NetworkMainteance

    # AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
    def self.trueIfFilepathIsInstanceDataCarrier(filepath)
        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        item["nx7Payload"]["type"] == "Data"
    end

    # AutomaticNx7NetworkMainteance::instanceAnalysis_ifDataCarrier_ensureThatInstanceAndExportFolderAreTheSame(filepath)
    def self.instanceAnalysis_ifDataCarrier_ensureThatInstanceAndExportFolderAreTheSame(filepath)
        exportFolder = filepath.gsub(".Nx7", "")
        return if !File.exists?(exportFolder)
        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        if item["nx7Payload"]["type"] == "Data" then
            state = item["nx7Payload"]["state"]
            operator = ElizabethNx5.new(filepath)
            folderCheck = "#{exportFolder}-Check"
            if !File.exists?(folderCheck) then
                FileUtils.mkdir(folderCheck)
            end
            GridState::exportStateAtFolder(operator, state, folderCheck)
            loop {
                message = CommonUtils::firstDifferenceBetweenTwoLocations(exportFolder, folderCheck)
                if message.nil? then
                    break
                end
                if message then
                    system("open '#{exportFolder}'")
                    puts "AutomaticNx7NetworkMainteance::instanceAnalysis(#{filepath})"
                    puts "message: #{message}"
                    puts "Ensure that both are the same and..."
                    LucilleCore::pressEnterToContinue()
                
                end
            }
            LucilleCore::removeFileSystemLocation(folderCheck)
        end
    end

    # AutomaticNx7NetworkMainteance::ifDataCarrier_exportInstanceAtFolder(filepath, exportFolder)
    def self.ifDataCarrier_exportInstanceAtFolder(filepath, exportFolder)
        return if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        if item["nx7Payload"]["type"] == "Data" then
            puts "AutomaticNx7NetworkMainteance::ifDataCarrier_exportInstanceAtFolder(#{filepath}, exportFolder)"
            state = item["nx7Payload"]["state"]
            operator = ElizabethNx5.new(filepath)
            GridState::exportStateAtFolder(operator, state, exportFolder)
        end
    end

    # AutomaticNx7NetworkMainteance::ifDataCarrier_importToInstanceFromExportFolder(filepath, exportFolder)
    def self.ifDataCarrier_importToInstanceFromExportFolder(filepath, exportFolder)
        return if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        nx7Payload = item["nx7Payload"]
        if nx7Payload["type"] == "Data" then
            puts "AutomaticNx7NetworkMainteance::ifDataCarrier_importToInstanceFromExportFolder(#{filepath}, exportFolder)"
            operator = ElizabethNx5.new(filepath)
            state2 = GridState::directoryPathToNxDirectoryContentsGridState(operator, exportFolder)
            nx7Payload["state"] = state2
            # Then, instance of calling the main commit function, we do it manually like this to ensure that we are talking to the correct instance
            Nx5::emitEventToFile1(filepath, "nx7Payload", nx7Payload)
            # Technically we should also call this, but we don't: Nx7EventDispatch::itemCreatedOrUpdated(item)
        end
    end

    # AutomaticNx7NetworkMainteance::instanceAnalysis(filepath)
    def self.instanceAnalysis(filepath)

        return if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)

        # If there is not export folder, then there is nothing for us to do here

        exportFolder = filepath.gsub(".Nx7", "")
        return if !File.exists?(exportFolder)

        # Nothing to do if the item is not data carrier

        item = Nx5Ext::readFileAsAttributesOfObject(filepath)
        return if item["nx7Payload"]["type"] != "Data"

        # Getting the Instance Traces

        instanceTracesXisting = Nx7InstanceTraces::getNx7InstanceTracesOrNull(filepath)

        # If there is no Nx7InstanceTraces, then we compare the folder and the instance and make a decision

        if instanceTracesXisting.nil? then
            AutomaticNx7NetworkMainteance::instanceAnalysis_ifDataCarrier_ensureThatInstanceAndExportFolderAreTheSame(filepath)
            # So by now, the two are identical
            # Let's issue the Nx7InstanceTraces
            Nx7InstanceTraces::issueNewNx7InstanceTracesForFilepath(filepath)
            return
        end

        # So we have instanceTraces

        # If the instance trace and the export folder traces are the same, then there has not been any evolution since the last time
        # If the instance trace is different, but the export folder is the same, then we export
        # If the instance trace if the same, but the export folder trace is different, then we import
        # If both traces have moved, then we have a problem.

        instanceTracesLive = Nx7InstanceTraces::computeForFilepath(filepath)

        #Nx7InstanceTraces { # stored in xcache against the instance filepath
        #    "filepath"    : String
        #    "eventsTrace" : String
        #    "exportTrace" : StringOrNull # null if 
        #}

        if instanceTracesXisting["eventsTrace"] == instanceTracesLive["eventsTrace"] and instanceTracesXisting["exportTrace"] == instanceTracesLive["exportTrace"] then
            return
        end

        if instanceTracesXisting["eventsTrace"] != instanceTracesLive["eventsTrace"] and instanceTracesXisting["exportTrace"] == instanceTracesLive["exportTrace"] then
            AutomaticNx7NetworkMainteance::ifDataCarrier_exportInstanceAtFolder(filepath, exportFolder)
            Nx7InstanceTraces::issueNewNx7InstanceTracesForFilepath(filepath)
            return
        end

        if instanceTracesXisting["eventsTrace"] == instanceTracesLive["eventsTrace"] and instanceTracesXisting["exportTrace"] != instanceTracesLive["exportTrace"] then
            AutomaticNx7NetworkMainteance::ifDataCarrier_importToInstanceFromExportFolder(filepath, exportFolder)
            Nx7InstanceTraces::issueNewNx7InstanceTracesForFilepath(filepath)
            return
        end
        
        if instanceTracesXisting["eventsTrace"] != instanceTracesLive["eventsTrace"] and instanceTracesXisting["exportTrace"] != instanceTracesLive["exportTrace"] then
            puts "Houston, we have a problem!"
            AutomaticNx7NetworkMainteance::instanceAnalysis_ifDataCarrier_ensureThatInstanceAndExportFolderAreTheSame(filepath)
            Nx7InstanceTraces::issueNewNx7InstanceTracesForFilepath(filepath)
            return
        end
    end

    # AutomaticNx7NetworkMainteance::pairAnalysisExportFoldersResolution(filepath1, filepath2)
    def self.pairAnalysisExportFoldersResolution(filepath1, filepath2)
        return if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath1)
        return if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath2)
        exportFolder1 = filepath1.gsub(".Nx7", "")
        exportFolder2 = filepath2.gsub(".Nx7", "")
        if File.exists?(exportFolder1) and File.exists?(exportFolder2) then
            message = CommonUtils::firstDifferenceBetweenTwoLocations(exportFolder1, exportFolder2)
            if message then
                puts "AutomaticNx7NetworkMainteance::pairAnalysisExportFoldersResolution(#{filepath1}, #{filepath2})"
                puts "message: #{message}"
                exit
            end
        end
    end

    # AutomaticNx7NetworkMainteance::run()
    def self.run()

        time1 = Time.new.to_i

        puts "> AutomaticNx7NetworkMainteance::run()"

        # First let us make sure that we have the right filepaths

        puts "> Nx7Locations scan and update"
        Nx7Locations::scanAndUpdate()

        # The priority is then to detect if two export folders have diverged or not

        puts "> Pairs analysis, export folders resolution"
        Nx7::filepaths().each{|filepath|
            next if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
            item = Nx5Ext::readFileAsAttributesOfObject(filepath)
            uuid = item["uuid"]
            nx7locations = Nx7Locations::getNx7Locations(uuid)
            nx7locations["locations"]
                .combination(2)
                .each{|filepath1, filepath2|
                    AutomaticNx7NetworkMainteance::pairAnalysisExportFoldersResolution(filepath1, filepath2)
                }
        }

        # Then we want to make sure that changes in an export folder are reported into the instance

        puts "> Instance analysis, batch"
        Nx7::filepaths().each{|filepath|
            next if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
            AutomaticNx7NetworkMainteance::instanceAnalysis(filepath)
        }

        # Then we mirror pairs of instances

        puts "> Pairs analysis: contents mirroring "
        Nx7::filepaths().each{|filepath|
            next if !AutomaticNx7NetworkMainteance::trueIfFilepathIsInstanceDataCarrier(filepath)
            item = Nx5Ext::readFileAsAttributesOfObject(filepath)
            uuid = item["uuid"]
            nx7locations = Nx7Locations::getNx7Locations(uuid)
            nx7locations["locations"]
                .combination(2)
                .each{|filepath1, filepath2|
                    hash1 = File.mtime(filepath1).to_s
                    hash2 = File.mtime(filepath2).to_s
                    key = "4694f05c-a071-40dc-9c62-3b42c25ca9e6:#{hash1}:#{hash2}"
                    next if XCache::getFlag(key)
                    Nx5Ext::contentsMirroring(filepath1, filepath2)
                    XCache::setFlag(key, true)
                }
        }

        time2 = Time.new.to_i

        puts "AutomaticNx7NetworkMainteance::run() completed successfully in #{(time2 - time1)} seconds".green
    end
end
