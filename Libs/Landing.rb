
# encoding: UTF-8

class Landing

    # Landing::removeConnected(item)
    def self.removeConnected(item)
        uuid = item["uuid"]

        store = ItemStore.new()

        NxLink::relatedItems(item["uuid"])
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entity| 
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NxLink::unlink(node1uuid, node2uuid)
        end
    end

    # Landing::link(item)
    def self.link(item)
        newItem = Architect::architectOneOrNull()
        return if newItem.nil?
        NxLink::issue(item["uuid"], newItem["uuid"])
    end

    # Landing::networkAggregationNodeLanding(item)
    def self.networkAggregationNodeLanding(item)
        loop {
            return if item.nil?

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

            related  = NxLink::relatedItems(item["uuid"])

            if related.size > 50 then
                puts "Many related, please use `navigation`"
            else
                related
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            end

            puts "commands: iam | <n> | description | datetime | note | json | link | unlink | navigation | upload | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    item["name"] = name1
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    item["description"] = description
                end
                Librarian::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian::commit(item)
            end

            if Interpreting::match("iam", command) then
                Iam::transmutation(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner()
                NxLink::issue(item["uuid"], ox["uuid"])
                puts JSON.pretty_generate(ox)
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

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroyClique(item["uuid"])
                    break
                end
            end
        }
    end

    # Landing::implementsNx111Landing(item)
    def self.implementsNx111Landing(item)
        loop {
            return if item.nil?

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

            NxLink::relatedItems(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                }

            puts "commands: access | iam | <n> | description | datetime | nx111 | note | json | link | unlink | upload | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                LxAction::action("access", item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian::commit(item)
            end

            if Interpreting::match("nx111", command) then
                nx111 = Nx111::interactivelyCreateNewNx111OrNull()
                next if nx111.nil?
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("iam", command) then
                Iam::transmutation(item)
                return
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner()
                NxLink::issue(item["uuid"], ox["uuid"])
                puts JSON.pretty_generate(ox)
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

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroyClique(item["uuid"])
                    break
                end
            end
        }
    end

    # Landing::primitiveFileLanding(item)
    def self.primitiveFileLanding(item)
        loop {
            return if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "(#{item["mikuType"].yellow}) #{item["description"]}"
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "dottedExtension: #{item["dottedExtension"]}".yellow
            puts "nhash: #{item["nhash"]}".yellow
            puts "parts (count): #{item["parts"].size}".yellow

            NxLink::relatedItems(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                }

            puts "commands: access | <n> | description | datetime | note | json | update | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                LxAction::action("access", item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian::commit(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner()
                NxLink::issue(item["uuid"], ox["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("update", command) then
                location = CommonUtils::interactivelySelectDesktopLocationOrNull()
                next if location.nil?
                data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(location) # [dottedExtension, nhash, parts]
                next if data.nil?
                item["dottedExtension"] = dottedExtension
                item["nhash"] = nhash
                item["parts"] = parts
                Librarian::commit(item)
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroyClique(item["uuid"])
                    break
                end
            end
        }
    end

    # Landing::landing(item)
    def self.landing(item)
        if Iam::implementsNx111(item) then
            Landing::implementsNx111Landing(item)
            return
        end
        if Iam::isNetworkAggregation(item) then
            Landing::networkAggregationNodeLanding(item)
            return
        end
        raise "(error: 1e84c68b-b602-41af-b2e9-00e66fa687ac) item: #{item}"
    end
end
