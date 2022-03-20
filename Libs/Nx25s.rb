
# encoding: UTF-8

class Nx25s

    # ----------------------------------------------------------------------
    # IO

    # Nx25s::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx25")
    end

    # Nx25s::getOrNull(uuid): null or Nx25
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx25s::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx25s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx25",
          "unixtime"    => unixtime,
          "description" => description
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx25s::selectExistingOrNull()
    def self.selectExistingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx25s::items(), lambda{|item| "(#{item["uuid"][0, 4]}) #{Nx25s::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx25s::toString(item)
    def self.toString(item)
        "[nav ] #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx25s::landing(miku)
    def self.landing(miku)
        loop {
            miku = Nx25s::getOrNull(miku["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if miku.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx25s::toString(entity)}" 
                }

            Links::related(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx25s::toString(entity)}" 
                }

            Links::children(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx25s::toString(entity)}" 
                }

            puts ""

            puts Nx25s::toString(miku).green
            puts "uuid: #{miku["uuid"]}".yellow

            Librarian7Notes::getObjectNotes(miku["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            puts "access | description | note | notes | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Nx25s::landing(entity)
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
                    Nx25s::destroy(miku["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx25s::nx20s()
    def self.nx20s()
        Nx25s::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx25s::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
