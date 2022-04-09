
# encoding: UTF-8

class Nx48PublicEvents

    # ----------------------------------------------------------------------
    # IO

    # Nx48PublicEvents::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx48PublicEvent")
    end

    # Nx48PublicEvents::getOrNull(uuid): null or Nx48PublicEvent
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx48PublicEvents::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx48PublicEvents::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid = SecureRandom.uuid
        creationUnixtime = Time.new.to_i

        eventDate = LucilleCore::askQuestionAnswerAsString("eventDate (format: YYYY-MM-DD) : ")

        item = {
          "uuid"         => uuid,
          "mikuType"     => "Nx48PublicEvent",
          "description"  => description,
          "creationUnixtime" => creationUnixtime,
          "eventDate"    => eventDate,
          "atomuuid"     => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx48PublicEvents::selectExistingOrNull()
    def self.selectExistingOrNull()
        items = Nx48PublicEvents::items()
                    .sort{|i1, i2| "#{i1["eventDate"]}" <=> "#{i2["eventDate"]}" }
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx48PublicEvents::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx48PublicEvents::toString(item)
    def self.toString(item)
        "(public event) (#{item["eventDate"]}) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx48PublicEvents::landing(item)
    def self.landing(item)
        loop {
            item = Nx48PublicEvents::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx48PublicEvents::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "eventDate: #{item["eventDate"]}".yellow
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
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{LxFunction::function("toString", entity)}" 
                }

            Links::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{LxFunction::function("toString", entity)}" 
                }

            Links::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{LxFunction::function("toString", entity)}" 
                }

            Libriarian16SpecialCircumstances::atomLandingPresentation(item["atomuuid"])

            puts "access | description | event date | atom | attachment | link | unlink | destroy".yellow

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

            if Interpreting::match("event date", command) then
                date = LucilleCore::askQuestionAnswerAsString("date (format: YYYY-MM-DD) : ")
                item["eventDate"] = date
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
                    Nx48PublicEvents::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # Nx48PublicEvents::processAfterCompletionArchiveOrDestroy(item)
    def self.processAfterCompletionArchiveOrDestroy(item)
        actions = ["disactivate (default)", "destroy"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action.nil? or action == "disactivate (default)" then
            item["active"] = false
            Librarian6Objects::commit(item)
        end
        if action == "destroy" then
            Nx48PublicEvents::destroy(item["uuid"])
        end
    end

    # ------------------------------------------------
    # Nx20s

    # Nx48PublicEvents::dive()
    def self.dive()
        loop {
            system("clear")
            items = Nx48PublicEvents::items()
                        .sort{|i1, i2| "#{i1["eventDate"]}" <=> "#{i2["eventDate"]}" }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("public event", items, lambda{|item| Nx48PublicEvents::toString(item) })
            break if item.nil?
            Nx48PublicEvents::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # Nx48PublicEvents::nx20s()
    def self.nx20s()
        Nx48PublicEvents::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx48PublicEvents::toString(item)}",
                "unixtime" => item["creationUnixtime"],
                "payload"  => item
            }
        }
    end
end
