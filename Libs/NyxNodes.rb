
# encoding: UTF-8

class NyxNodes

    # ----------------------------------------------------------------------
    # Basis IO

    # NyxNodes::items()
    def self.items()
        variants = []
        Find.find("#{Config::pathToDataCenter()}/NyxNode") do |path|
            next if File.basename(path)[-5, 5] != ".json"
            variants << JSON.parse(IO.read(path))
        end
        PhageInternals::variantsToObjects(variants)
    end

    # NyxNodes::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        fragment = Digest::SHA1.hexdigest(uuid)[0, 3]
        folderpath = "#{Config::pathToDataCenter()}/NyxNode/#{fragment}/#{uuid}"
        variants = LucilleCore::locationsAtFolder(folderpath)
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        objects = PhageInternals::variantsToObjects(variants)
        raise "(error: d8015bf3-542f-4830-9a3b-b72c9c3c4589)" if objects.size >= 2
        objects.first
    end

    # NyxNodes::commitVariant(variant)
    def self.commitVariant(variant)
        variant["phage_uuid"] = SecureRandom.uuid
        variant["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_PhageItem(variant, SecureRandom.hex, false)
        fragment = Digest::SHA1.hexdigest(variant["uuid"])[0, 3]
        filepath = "#{Config::pathToDataCenter()}/NyxNode/#{fragment}/#{variant["uuid"]}/#{variant["phage_uuid"]}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(variant)) }
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        object = NyxNodes::getItemOrNull(uuid)
        return if object.nil?
        object["phage_alive"] = false
        NyxNodes::commitVariant(object)
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

        networkType = NyxNodes::interactivelySelectNetworkType()

        nx113 = nil

        # We have the convention that only PureData NyxNodes carry (points to) a Nx113
        if networkType == "PureData" then
            nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        end

        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113
        }

        NyxNodes::commitVariant(item)
        item
    end

    # NyxNodes::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(location)
        networkType = "PureData"
        nx113 = Nx113Make::aionpoint(location)
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113
        }
        NyxNodes::commitVariant(item)
        item
    end

    # NyxNodes::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        networkType = "PureData"
        nx113 = Nx113Make::file(filepath)
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113
        }
        NyxNodes::commitVariant(item)
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
        nx113 = Nx113Make::text(text)

        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "NyxNode",
            "networkType" => networkType,
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113
        }

        NyxNodes::commitVariant(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNodes::toString(item)
    def self.toString(item)
        nwt = item["networkType"] ? ": #{item["networkType"]}" : ""
        "(NyxNode#{nwt})#{Nx113Access::toStringOrNullShort(" ", item["nx113"], "")} #{item["description"]}"
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
        "(NyxNode#{nwt})#{Nx113Access::toStringOrNullShort(" ", item["nx113"], "")} #{item["description"]}#{parentsstr}"
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
        NyxNodes::getItemOrNull(item["uuid"])
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
            puts "<n> | access | description | name | datetime | nx113 | edit | network type | expose | destroy".yellow
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

            if input == "network type" then
                networkType = NyxNodes::interactivelySelectNetworkType()
                item["networkType"] = networkType
                NyxNodes::commitVariant(item)
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
