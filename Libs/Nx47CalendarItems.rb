
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
          "atomuuid"     => atom["uuid"],
          "active"       => true
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx47CalendarItems::selectExistingOrNull()
    def self.selectExistingOrNull()
        items = Nx47CalendarItems::items()
                    .sort{|i1, i2| "#{i1["calendarDate"]} #{i1["calendarTime"]}" <=> "#{i2["calendarDate"]} #{i2["calendarTime"]}" }
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx47CalendarItems::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx47CalendarItems::toString(item)
    def self.toString(item)
        "[cale] (#{item["calendarDate"]} #{item["calendarTime"]}) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx47CalendarItems::landing(item)
    def self.landing(item)
        loop {
            item = Nx47CalendarItems::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx47CalendarItems::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "calendarDate: #{item["calendarDate"]}".yellow
            puts "calendarTime: #{item["calendarTime"]}".yellow
            puts "atomuuid: #{item["atomuuid"]}".yellow
            atom = Librarian6Objects::getObjectByUUIDOrNull(item["atomuuid"])
            puts "atom: #{atom}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

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

            Libriarian16SpecialCircumstances::atomLandingPresentation(item["atomuuid"])

            puts "access | description | datetime | atom | attachment | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
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
                calendarDate = LucilleCore::askQuestionAnswerAsString("calendarDate (format: YYYY-MM-DD) : ")
                calendarTime = LucilleCore::askQuestionAnswerAsString("calendarTime (format: HH:MM) : ")
                item["calendarDate"] = calendarDate
                item["calendarTime"] = calendarTime
                Librarian6Objects::commit(item) 
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                Librarian6Objects::commit(atom)
                item["atomuuid"] = atom["uuid"]
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("attachment", command) then
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
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

    # Nx47CalendarItems::processAfterCompletionArchiveOrDestroy(item)
    def self.processAfterCompletionArchiveOrDestroy(item)
        actions = ["disactivate (default)", "destroy"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action.nil? or action == "disactivate (default)" then
            item["active"] = false
            Librarian6Objects::commit(item)
        end
        if action == "destroy" then
            Nx47CalendarItems::destroy(item["uuid"])
        end
    end

    # ------------------------------------------------
    # Nx20s

    # Nx47CalendarItems::dive()
    def self.dive()
        loop {
            system("clear")
            items = Nx47CalendarItems::items()
                        .sort{|i1, i2| "#{i1["calendarDate"]} #{i1["calendarTime"]}" <=> "#{i2["calendarDate"]} #{i2["calendarTime"]}" }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("calendar item", items, lambda{|item| Nx47CalendarItems::toString(item) })
            break if item.nil?
            Nx47CalendarItems::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # Nx47CalendarItems::ns16(item)
    def self.ns16(item)
        uuid = item["uuid"]
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:Nx47CalendarItems",
            "announce" => "(calendar) [#{item["calendarDate"]}] (#{item["time"]}) #{item["description"]}#{Libriarian16SpecialCircumstances::atomTypeForToStrings(" ", item["atomuuid"])}",
            "item"     => item
        }
    end

    # Nx47CalendarItems::ns16s()
    def self.ns16s()
        Nx47CalendarItems::items()
            .select{|item| item["active"] }
            .sort{|i1, i2| "#{i1["calendarDate"]} #{i1["calendarTime"]}" <=> "#{i2["calendarDate"]} #{i2["calendarTime"]}" }
            .select{|item| item["calendarDate"] <= Utils::today() }
            .map{|item| Nx47CalendarItems::ns16(item) }
    end

    # Nx47CalendarItems::nx20s()
    def self.nx20s()
        Nx47CalendarItems::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx47CalendarItems::toString(item)}",
                "unixtime" => item["creationUnixtime"],
                "payload"  => item
            }
        }
    end
end
