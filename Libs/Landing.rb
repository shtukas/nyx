
# encoding: UTF-8

class Landing

    # Landing::removeConnected(item)
    def self.removeConnected(item)
        store = ItemStore.new()

        NxLink::linkedUUIDs(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = Fx18::itemOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NxLink::unlink(item["uuid"], entity["uuid"])
        end
    end

    # Landing::link(item)
    def self.link(item)
        newitem = Nyx::architectOneOrNull()
        return if newitem.nil?
        NxLink::issue(item["uuid"], newitem["uuid"])
    end

    # Landing::networkAggregationNodeLanding(item, isSearchAndSelect) # nil or item (if command: result)
    def self.networkAggregationNodeLanding(item, isSearchAndSelect)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = Fx18::itemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            makeFirstLine = lambda{|item|
                if item["mikuType"] == "NxPerson" then
                    return "(#{item["mikuType"].yellow}) #{item["name"]}"
                end
                "(#{item["mikuType"].yellow}) #{item["description"]}"
            }

            puts makeFirstLine.call(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            linkeds  = NxLink::linkedEntities(uuid)
            linkeds
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .first(200)
                .each{|entity|
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                }
            if linkeds.size > 200 then
                puts "(... more linked ...)"
            end

            puts "commands: iam | <n> | description | datetime | note | json | link | unlink | network-migration | navigation | upload | return (within search) | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = Landing::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                Fx18Attributes::set_objectUpdate(item["uuid"], "datetime", datetime)
            end

            if Interpreting::match("iam", command) then
                Iam::transmutation(item)
            end

            if Interpreting::match("note", command) then
                i2 = Ax1Text::interactivelyIssueNew()
                puts JSON.pretty_generate(i2)
                NxLink::issue(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("navigation", command) then
                LinkedNavigation::navigate(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("network-migration", command) then
                NxLink::networkMigration(item)
            end

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("return", command) then
                return item
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18::deleteObject(item["uuid"])
                    break
                end
            end
        }

        nil
    end

    # Landing::implementsNx111Landing(item, isSearchAndSelect) # nil or item (if command: result)
    def self.implementsNx111Landing(item, isSearchAndSelect)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = Fx18::itemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "(#{item["mikuType"].yellow}) #{item["description"]}"
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            if item["nx111"] then
                if item["nx111"]["type"] == "file" then
                    puts "nx111: file: nhash: #{item["nx111"]["nhash"]} (#{item["nx111"]["parts"].size} parts)".yellow
                else
                    puts "nx111: #{item["nx111"]}".yellow
                end
            else
                puts "nx111: (not found)".yellow
            end

            NxLink::linkedUUIDs(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entityuuid|
                    entity = Fx18::itemOrNull(entityuuid)
                    next if entity.nil?
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                }

            puts "commands: access | iam | <n> | description | datetime | nx111 | note | json | link | unlink | network-migration | upload | return (within search) | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = Landing::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                LxAction::action("access", item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                Fx18Attributes::set_objectUpdate(item["uuid"], "description", description)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                Fx18Attributes::set_objectUpdate(item["uuid"], "datetime", datetime)
            end

            if Interpreting::match("nx111", command) then
                nx111 = Nx111::interactivelyCreateNewNx111OrNull(item["uuid"])
                next if nx111.nil?
                Fx18Attributes::set_objectUpdate(item["uuid"], "nx111", JSON.generate(nx111))
            end

            if Interpreting::match("iam", command) then
                Iam::transmutation(item)
                return
            end

            if Interpreting::match("note", command) then
                i2 = Ax1Text::interactivelyIssueNew()
                puts JSON.pretty_generate(i2)
                NxLink::issue(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("network-migration", command) then
                NxLink::networkMigration(item)
            end

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("return", command) then
                return item
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18::deleteObject(item["uuid"])
                    break
                end
            end
        }

        nil
    end

    # Landing::landing(item, isSearchAndSelect)
    def self.landing(item, isSearchAndSelect)
        if Iam::implementsNx111(item) then
            return Landing::implementsNx111Landing(item, isSearchAndSelect)
        end
        if Iam::isNetworkAggregation(item) then
            return Landing::networkAggregationNodeLanding(item, isSearchAndSelect)
        end
        if item["mikuType"] == "TxThread" then
            return TxThreads::landing(item)
        end
        if item["mikuType"] == "TxTimeControl" then
            return TxTimeControls::landing(item)
        end
        if item["mikuType"] == "NxLine" then
            puts JSON.pretty_generate(item)
            puts "We do not have a landing for NxLines"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        raise "(error: 1e84c68b-b602-41af-b2e9-00e66fa687ac) item: #{item}"
    end
end
