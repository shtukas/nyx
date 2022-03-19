
# encoding: UTF-8

class Nx31s

    # ----------------------------------------------------------------------
    # IO

    # Nx31s::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx31")
    end

    # Nx31s::getOrNull(uuid): null or Nx31
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx31s::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx31s::interactivelyCreateNewOrNull()
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

    # Nx31s::selectExistingOrNull()
    def self.selectExistingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx31s::items(), lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx31s::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx31s::toString(item)
    def self.toString(item)
        "[data] #{item["description"]}"
    end

    # Nx31s::selectItemsByDateFragment(fragment)
    def self.selectItemsByDateFragment(fragment)
        Nx31s::items()
            .select{|item|
                item["datetime"].start_with?(fragment)
            }
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx31s::landing(miku)
    def self.landing(miku)
        loop {
            miku = Nx31s::getOrNull(miku["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if miku.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx31s::toString(entity)}" 
                }

            Links::related(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx31s::toString(entity)}" 
                }

            Links::children(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx31s::toString(entity)}" 
                }

            puts ""

            puts Nx31s::toString(miku).green
            puts "uuid: #{miku["uuid"]}".yellow
            puts "datetime: #{miku["datetime"]}".yellow
            puts "atomuuid: #{miku["atomuuid"]}".yellow
            atom = Librarian6Objects::getObjectByUUIDOrNull(miku["atomuuid"])
            puts "atom: #{atom}".yellow

            Librarian7Notes::getObjectNotes(miku["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            Libriarian16SpecialCircumstances::atomLandingPresentation(miku["atomuuid"])

            #Librarian::notes(miku["uuid"]).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | description | datetime | atom | note | notes | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Nx31s::landing(entity)
            end

            if Interpreting::match("access", command) then
                Libriarian16SpecialCircumstances::accessAtom(miku["atomuuid"])
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(miku["description"]).strip
                next if description == ""
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
                NyxNetwork::disconnectFromLinkedInteractively(miku)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx31s::destroy(miku["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx31s::nx20s()
    def self.nx20s()
        Nx31s::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx31s::toString(item)}",
                "payload"  => item
            }
        }
    end
end
