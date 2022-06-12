
# encoding: UTF-8

class Landing

    # Landing::removeFromCircle(item)
    def self.removeFromCircle(item)
        uuid = item["uuid"]

        store = ItemStore.new()

        Ax1Text::itemsForOwner(uuid).each{|note|
            indx = store.register(note, false)
            puts "[#{indx.to_s.ljust(3)}] (note) #{Ax1Text::toString(note)}" 
        }

        NxArrow::parents(item["uuid"])
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entity| 
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] (parent) #{LxFunction::function("toString", entity)}"
            }

        NxRelation::related(item["uuid"])
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entity| 
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] (related) #{LxFunction::function("toString", entity)}"
            }

        NxArrow::children(item["uuid"])
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entity| 
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] (child) #{LxFunction::function("toString", entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NxArrow::unlink(item["uuid"], entity["uuid"])
            NxArrow::unlink(entity["uuid"], item["uuid"])
            NxRelation::unlink(NxRelation::unlink(node1uuid, node2uuid))
        end
    end

    # Landing::addToCircle(item)
    def self.addToCircle(item)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["add parent", "add related", "add child"])
        return if action.nil?
        if action == "add parent" then
            newItem = Architect::architectOneOrNull()
            return if newItem.nil?
            NxArrow::issue(newItem["uuid"], item["uuid"])
        end
        if action == "add related" then
            newItem = Architect::architectOneOrNull()
            return if newItem.nil?
            NxRelation::issue(item["uuid"], newItem["uuid"])
        end
        if action == "add child" then
            newItem = Architect::architectOneOrNull()
            return if newItem.nil?
            NxArrow::issue(item["uuid"], newItem["uuid"])
        end
    end

    # Landing::networkAggregationNodeLanding(item)
    def self.networkAggregationNodeLanding(item)
        loop {
            return if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "(#{item["mikuType"].yellow}) #{item["description"]}"
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            Ax1Text::itemsForOwner(uuid).each{|note|
                indx = store.register(note, false)
                puts "[#{indx.to_s.ljust(3)}] (note) #{Ax1Text::toString(note)}" 
            }

            NxArrow::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (parent) #{LxFunction::function("toString", entity)}"
                }

            NxRelation::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (related) #{LxFunction::function("toString", entity)}"
                }

            NxArrow::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (child) #{LxFunction::function("toString", entity)}"
                }

            puts "commands: iam | access | <n> | description | datetime | note | json | add | remove | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessCollectionItem(item)
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

            if Interpreting::match("iam", command) then
                Iam::processItem(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("add", command) then
                Landing::addToCircle(item)
            end

            if Interpreting::match("remove", command) then
                Landing::removeFromCircle(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroy(item["uuid"])
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

            nx111toLandingString = lambda {|nx111|
                if nx111["type"] == "file" then
                    nx111["parts"] = "(...)"
                    return nx111.to_s
                end
                nx111.to_s
            }

            puts "nx111: #{nx111toLandingString.call(item["nx111"])}".yellow

            Ax1Text::itemsForOwner(uuid).each{|note|
                indx = store.register(note, false)
                puts "[#{indx.to_s.ljust(3)}] (note) #{Ax1Text::toString(note)}" 
            }

            NxArrow::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (parent) #{LxFunction::function("toString", entity)}"
                }

            NxRelation::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (related) #{LxFunction::function("toString", entity)}"
                }

            NxArrow::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (child) #{LxFunction::function("toString", entity)}"
                }

            puts "commands: iam | access | <n> | description | datetime | nx111 | note | json | add | remove | destroy".yellow

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
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("iam", command) then
                Iam::processItem(item)
                return
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("add", command) then
                Landing::addToCircle(item)
            end

            if Interpreting::match("remove", command) then
                Landing::removeFromCircle(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroy(item["uuid"])
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

            Ax1Text::itemsForOwner(uuid).each{|note|
                indx = store.register(note, false)
                puts "[#{indx.to_s.ljust(3)}] (note) #{Ax1Text::toString(note)}" 
            }

            NxArrow::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (parent) #{LxFunction::function("toString", entity)}"
                }

            NxRelation::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (related) #{LxFunction::function("toString", entity)}"
                }

            NxArrow::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] (child) #{LxFunction::function("toString", entity)}"
                }

            puts "commands: access | <n> | description | datetime | note | json | update | add | remove | destroy".yellow

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
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
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

            if Interpreting::match("add", command) then
                Landing::addToCircle(item)
            end

            if Interpreting::match("remove", command) then
                Landing::removeFromCircle(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Librarian::destroy(item["uuid"])
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
