
# encoding: UTF-8

class Nx49PascalPersonalEvents

    # ----------------------------------------------------------------------
    # IO

    # Nx49PascalPersonalEvents::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx49PascalPrivateLog")
    end

    # Nx49PascalPersonalEvents::getOrNull(uuid): null or Nx49PascalPrivateLog
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx49PascalPersonalEvents::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx49PascalPersonalEvents::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid = SecureRandom.uuid
        creationUnixtime = Time.new.to_i

        date = LucilleCore::askQuestionAnswerAsString("date (format: YYYY-MM-DD) : ")

        item = {
          "uuid"         => uuid,
          "mikuType"     => "Nx49PascalPrivateLog",
          "description"  => description,
          "creationUnixtime" => creationUnixtime,
          "date"         => date,
          "atomuuid"     => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx49PascalPersonalEvents::selectExistingOrNull()
    def self.selectExistingOrNull()
        items = Nx49PascalPersonalEvents::items()
                    .sort{|i1, i2| "#{i1["date"]}" <=> "#{i2["date"]}" }
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx49PascalPersonalEvents::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx49PascalPersonalEvents::toString(item)
    def self.toString(item)
        "(private log) (#{item["date"]}) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx49PascalPersonalEvents::landing(item)
    def self.landing(item)
        loop {
            item = Nx49PascalPersonalEvents::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx49PascalPersonalEvents::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "date: #{item["date"]}".yellow
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
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx49PascalPersonalEvents::toString(entity)}" 
                }

            Links::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx49PascalPersonalEvents::toString(entity)}" 
                }

            Links::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx49PascalPersonalEvents::toString(entity)}" 
                }

            Librarian7Notes::getObjectNotes(item["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            Libriarian16SpecialCircumstances::atomLandingPresentation(item["atomuuid"])

            #Librarian::notes(item["uuid"]).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | description | date | atom | note | attachment | notes | link | unlink | destroy".yellow

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

            if Interpreting::match("date", command) then
                date = LucilleCore::askQuestionAnswerAsString("date (format: YYYY-MM-DD) : ")
                item["date"] = date
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
                    Nx49PascalPersonalEvents::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # Nx49PascalPersonalEvents::processAfterCompletionArchiveOrDestroy(item)
    def self.processAfterCompletionArchiveOrDestroy(item)
        actions = ["disactivate (default)", "destroy"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action.nil? or action == "disactivate (default)" then
            item["active"] = false
            Librarian6Objects::commit(item)
        end
        if action == "destroy" then
            Nx49PascalPersonalEvents::destroy(item["uuid"])
        end
    end

    # ------------------------------------------------
    # Nx20s

    # Nx49PascalPersonalEvents::dive()
    def self.dive()
        loop {
            system("clear")
            items = Nx49PascalPersonalEvents::items()
                        .sort{|i1, i2| "#{i1["date"]}" <=> "#{i2["date"]}" }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("private log", items, lambda{|item| Nx49PascalPersonalEvents::toString(item) })
            break if item.nil?
            Nx49PascalPersonalEvents::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # Nx49PascalPersonalEvents::nx20s()
    def self.nx20s()
        Nx49PascalPersonalEvents::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx49PascalPersonalEvents::toString(item)}",
                "unixtime" => item["creationUnixtime"],
                "payload"  => item
            }
        }
    end
end
