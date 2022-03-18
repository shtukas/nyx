
# encoding: UTF-8

class Nx47CalendarItems

    # ----------------------------------------------------------------------
    # IO

    # Nx47CalendarItems::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx47CalendarItem")
    end

    # Nx47CalendarItems::getOrNull(uuid): null or Nx47CalendarItem
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx47CalendarItems::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx47CalendarItems::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid = SecureRandom.uuid
        creationUnixtime = Time.new.to_i

        calendarDate = LucilleCore::askQuestionAnswerAsString("calendarDate (format: YYYY-MM-DD) : ")
        calendarTime = LucilleCore::askQuestionAnswerAsString("calendarTime (format: HH:MM) : ")

        item = {
          "uuid"         => uuid,
          "mikuType"     => "Nx47CalendarItem",
          "description"  => description,
          "creationUnixtime" => creationUnixtime,
          "calendarDate" => calendarDate,
          "calendarTime" => calendarTime,
          "atomuuid"     => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx47CalendarItems::selectExistingOrNull()
    def self.selectExistingOrNull()
        items = Nx47CalendarItems::items()
                    .sort{|i1, i2| "#{i1["calendarDate"]} #{i1["calendarTime"]}" <=> "#{i2["calendarDate"]} #{i2["calendarTime"]}" }
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| "#{Nx47CalendarItems::toString(item)} [#{item["uuid"][0, 4]}]" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx47CalendarItems::toString(item)
    def self.toString(item)
        "[cale] (#{item["calendarDate"]} #{item["calendarTime"]}) #{item["description"]}"
    end

    # Nx47CalendarItems::toStringWithTrace4(item)
    def self.toStringWithTrace4(item)
        "#{Nx47CalendarItems::toString(item)} [#{item["uuid"][0, 4]}]"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx47CalendarItems::landing(item)
    def self.landing(item)
        loop {
            item = Nx47CalendarItems::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx47CalendarItems::toString(entity)}" 
                }

            Links::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx47CalendarItems::toString(entity)}" 
                }

            Links::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx47CalendarItems::toString(entity)}" 
                }

            puts ""

            puts Nx47CalendarItems::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "atomuuid: #{item["atomuuid"]}".yellow
            atom = Librarian6Objects::getObjectByUUIDOrNull(item["atomuuid"])
            puts "atom: #{atom}".yellow

            Librarian7Notes::getObjectNotes(item["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            Libriarian16SpecialCircumstances::atomLandingPresentation(item["atomuuid"])

            #Librarian::notes(item["uuid"]).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | description | datetime | atom | note | notes | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Nx47CalendarItems::landing(entity)
            end

            if Interpreting::match("access", command) then
                Libriarian16SpecialCircumstances::accessAtom(item["atomuuid"])
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = Utils::editTextSynchronously(item["datetime"]).strip
                next if !Utils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian6Objects::commit(item) 
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = item["atomuuid"]
                Librarian6Objects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian7Notes::addNote(item["uuid"], text)
                next
            end

            if Interpreting::match("notes", command) then
                Librarian7Notes::notesLanding(item["uuid"])
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOtherArchitectured(item)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromLinkedInteractively(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx47CalendarItems::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx47CalendarItems::itemToNx20s(item)
    def self.itemToNx20s(item)
        # At the moment we only transform Nx47CalendarItems
        x1 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{Nx47CalendarItems::toStringWithTrace4(item)}]",
            "payload"  => item
        }]
        x4 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{item["uuid"]}",
            "payload"  => item
        }]
        (x1 + x4).flatten
    end

    # Nx47CalendarItems::getNx20s()
    def self.getNx20s()
        Nx47CalendarItems::items().map{|item| Nx47CalendarItems::itemToNx20s(item) }.flatten
    end
end
