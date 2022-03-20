
# encoding: UTF-8

class Nx48TimedPublicEvents

    # ----------------------------------------------------------------------
    # IO

    # Nx48TimedPublicEvents::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx48TimedPublicEvent")
    end

    # Nx48TimedPublicEvents::getOrNull(uuid): null or Nx48TimedPublicEvent
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx48TimedPublicEvents::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx48TimedPublicEvents::interactivelyCreateNewOrNull()
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
          "mikuType"     => "Nx48TimedPublicEvent",
          "description"  => description,
          "creationUnixtime" => creationUnixtime,
          "eventDate"    => eventDate,
          "atomuuid"     => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx48TimedPublicEvents::selectExistingOrNull()
    def self.selectExistingOrNull()
        items = Nx48TimedPublicEvents::items()
                    .sort{|i1, i2| "#{i1["eventDate"]}" <=> "#{i2["eventDate"]}" }
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx48TimedPublicEvents::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx48TimedPublicEvents::toString(item)
    def self.toString(item)
        "(public event) (#{item["eventDate"]}) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx48TimedPublicEvents::landing(item)
    def self.landing(item)
        loop {
            item = Nx48TimedPublicEvents::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx48TimedPublicEvents::toString(entity)}" 
                }

            Links::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx48TimedPublicEvents::toString(entity)}" 
                }

            Links::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx48TimedPublicEvents::toString(entity)}" 
                }

            puts ""

            puts Nx48TimedPublicEvents::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "eventDate: #{item["eventDate"]}".yellow
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

            puts "access | description | event date | atom | note | notes | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Nx48TimedPublicEvents::landing(entity)
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
                    Nx48TimedPublicEvents::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # Nx48TimedPublicEvents::processAfterCompletionArchiveOrDestroy(item)
    def self.processAfterCompletionArchiveOrDestroy(item)
        actions = ["disactivate (default)", "destroy"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action.nil? or action == "disactivate (default)" then
            item["active"] = false
            Librarian6Objects::commit(item)
        end
        if action == "destroy" then
            Nx48TimedPublicEvents::destroy(item["uuid"])
        end
    end

    # ------------------------------------------------
    # Nx20s

    # Nx48TimedPublicEvents::dive()
    def self.dive()
        loop {
            system("clear")
            items = Nx48TimedPublicEvents::items()
                        .sort{|i1, i2| "#{i1["eventDate"]}" <=> "#{i2["eventDate"]}" }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("public event", items, lambda{|item| Nx48TimedPublicEvents::toString(item) })
            break if item.nil?
            Nx48TimedPublicEvents::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # Nx48TimedPublicEvents::nx20s()
    def self.nx20s()
        Nx48TimedPublicEvents::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx48TimedPublicEvents::toString(item)}",
                "unixtime" => item["creationUnixtime"],
                "payload"  => item
            }
        }
    end
end
