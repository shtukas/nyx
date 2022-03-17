
# encoding: UTF-8

class NyxNetworkNodes

    # ----------------------------------------------------------------------
    # IO

    # NyxNetworkNodes::nodes()
    def self.nodes()
        Librarian6Objects::getObjectsByMikuType("Nx31")
    end

    # NyxNetworkNodes::getOrNull(uuid): null or Nx31
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # NyxNetworkNodes::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # NyxNetworkNodes::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx31",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # NyxNetworkNodes::selectExistingOrNull()
    def self.selectExistingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NyxNetworkNodes::nodes(), lambda{|item| "#{NyxNetworkNodes::toString(item)} [#{item["uuid"][0, 4]}]" })
    end

    # NyxNetworkNodes::architectOrNull()
    def self.architectOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetworkNodes::selectExistingOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NyxNetworkNodes::interactivelyCreateNewOrNull()
        end
        if operation == "new" then
            return NyxNetworkNodes::interactivelyCreateNewOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNetworkNodes::normaliseDescription(description)
    def self.normaliseDescription(description)
        description
            .split("::")
            .map{|fragment| fragment.strip }
            .join(" :: ")
    end

    # NyxNetworkNodes::toString(item)
    def self.toString(item)
        "[data] #{item["description"]}"
    end

    # NyxNetworkNodes::toStringWithTrace4(item)
    def self.toStringWithTrace4(item)
        "#{NyxNetworkNodes::toString(item)} [#{item["uuid"][0, 4]}]"
    end

    # NyxNetworkNodes::selectItemsByDateFragment(fragment)
    def self.selectItemsByDateFragment(fragment)
        NyxNetworkNodes::nodes()
            .select{|item|
                item["datetime"].start_with?(fragment)
            }
    end

    # ----------------------------------------------------------------------
    # Operations

    # NyxNetworkNodes::atomLandingPresentation(atomuuid)
    def self.atomLandingPresentation(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "warning: I could not find the atom for this item (atomuuid: #{atomuuid})"
            LucilleCore::pressEnterToContinue()
        else
            if text = Librarian5Atoms::atomPayloadToTextOrNull(atom) then
                puts "text:\n#{text}"
            end
        end
    end

    # NyxNetworkNodes::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
    end

    # NyxNetworkNodes::landing(miku)
    def self.landing(miku)
        loop {
            miku = NyxNetworkNodes::getOrNull(miku["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if miku.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{NyxNetworkNodes::toString(entity)}" 
                }

            Links::related(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{NyxNetworkNodes::toString(entity)}" 
                }

            Links::children(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{NyxNetworkNodes::toString(entity)}" 
                }

            puts ""

            puts NyxNetworkNodes::toString(miku).green
            puts "uuid: #{miku["uuid"]}".yellow
            puts "datetime: #{miku["datetime"]}".yellow
            puts "atomuuid: #{miku["atomuuid"]}".yellow
            atom = Librarian6Objects::getObjectByUUIDOrNull(miku["atomuuid"])
            puts "atom: #{atom}".yellow

            Librarian7Notes::getObjectNotes(miku["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            NyxNetworkNodes::atomLandingPresentation(miku["atomuuid"])

            #Librarian::notes(miku["uuid"]).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | description | datetime | atom | note | notes | link | unlink | deep line | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                NyxNetworkNodes::landing(entity)
            end

            if Interpreting::match("access", command) then
                NyxNetworkNodes::accessAtom(miku["atomuuid"])
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(miku["description"]).strip
                next if description == ""
                description = NyxNetworkNodes::normaliseDescription(description)
                miku["description"] = description
                Librarian6Objects::commit(miku)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = Utils::editTextSynchronously(miku["datetime"]).strip
                next if !Utils::isDateTime_UTC_ISO8601(datetime)
                miku["datetime"] = datetime
                Librarian6Objects::commit(miku) 
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = miku["atomuuid"]
                Librarian6Objects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian7Notes::addNote(miku["uuid"], text)
                next
            end

            if Interpreting::match("notes", command) then
                Librarian7Notes::notesLanding(miku["uuid"])
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOtherArchitectured(miku)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromOtherInteractively(miku)
            end

            if Interpreting::match("deep line", command) then
                NyxNetwork::computeDeepLineConnectedEntities(miku).each{|entity|
                    puts "- #{NyxNetworkNodes::toString(entity)}"
                }
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    NyxNetworkNodes::destroy(miku["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # NyxNetworkNodes::mikuToNx20s(miku)
    def self.mikuToNx20s(miku)
        # At the moment we only transform Nx31s
        x1 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{NyxNetworkNodes::toStringWithTrace4(miku)}]",
            "payload"  => miku
        }]
        x4 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{miku["uuid"]}",
            "payload"  => miku
        }]
        (x1 + x4).flatten
    end

    # NyxNetworkNodes::getNx20s()
    def self.getNx20s()
        NyxNetworkNodes::nodes().map{|miku| NyxNetworkNodes::mikuToNx20s(miku) }.flatten
    end
end
