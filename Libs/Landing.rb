
# encoding: UTF-8

class Landing

    # Landing::diveCircle(item)
    def self.diveCircle(item)

        loop {
            system("clear")

            puts LxFunction::function("toString", item)

            store = ItemStore.new()

            parents = NxArrow::parents(item["uuid"])
            puts ""
            if parents.size > 0 then
                puts "parents:"
                parents
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity| 
                        indx = store.register(entity, false)
                        puts "    [#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "parents (not found)"
            end

            related = NxRelation::related(item["uuid"])
            puts ""
            if related.size > 0 then
                puts "related:"
                related
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity| 
                        indx = store.register(entity, false)
                        puts "    [#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "related (not found)"
            end

            children = NxArrow::children(item["uuid"])
            puts ""
            if children.size > 0 then
                puts "children:"
                children
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity| 
                        indx = store.register(entity, false)
                        puts "    [#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "children (not found)"
            end

            puts ""
            puts "commands: <n> | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if command == "exit" then
                break
            end
        }
    end

    # Landing::generic_landing(item)
    def self.generic_landing(item)
        loop {
            return if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "(#{item["mikuType"].yellow}) #{item["description"]}"
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "nx111: #{item["nx111"]}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "commands: access | <n> | description | datetime | nx111 | note | circle | json | destroy".yellow

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
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::types(), item["uuid"])
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("circle", command) then
                Landing::diveCircle(item)
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy item ? : ") then
                    Librarian::destroy(item["uuid"])
                    break
                end
            end
        }
    end

end
