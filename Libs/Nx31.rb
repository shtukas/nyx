
# encoding: UTF-8

class Nx31

    # ----------------------------------------------------------------------
    # IO

    # Nx31::mikus()
    def self.mikus()
        Librarian6Objects::getObjectsByMikuType("Nx31")
    end

    # Nx31::getOrNull(uuid): null or Nx31
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx31::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx31::interactivelyCreateNewOrNull()
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

    # Nx31::selectExistingOrNull()
    def self.selectExistingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx31::mikus(), lambda{|item| "#{Nx31::toString(item)} [#{item["uuid"][0, 4]}]" })
    end

    # Nx31::architectOrNull()
    def self.architectOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = Nx31::selectExistingOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return Nx31::interactivelyCreateNewOrNull()
        end
        if operation == "new" then
            return Nx31::interactivelyCreateNewOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx31::normaliseDescription(description)
    def self.normaliseDescription(description)
        description
            .split("::")
            .map{|fragment| fragment.strip }
            .join(" :: ")
    end

    # Nx31::toString(item)
    def self.toString(item)
        "[data] #{item["description"]}"
    end

    # Nx31::toStringWithTrace4(item)
    def self.toStringWithTrace4(item)
        "#{Nx31::toString(item)} [#{item["uuid"][0, 4]}]"
    end

    # Nx31::selectItemsByDateFragment(fragment)
    def self.selectItemsByDateFragment(fragment)
        Nx31::mikus()
            .select{|item|
                item["datetime"].start_with?(fragment)
            }
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx31::issueProjectionFile(miku)
    def self.issueProjectionFile(miku)
        projectionStyle = LucilleCore::selectEntityFromListOfEntitiesOrNull("projection style", ["point", "collection"])
        return if projectionStyle.nil?
        if projectionStyle == "point" then
            manifest = {
                "projectionStyle"     => "Nx48",
                "entity"              => miku,
                "description"         => miku["description"],
                "entityTrace"         => NyxEntitySyncUtils2::computeEntityTrace(miku),
                "exportLocationTrace" => "" # This ensures that the entity is picked up at the next sync
            }
        end
        if projectionStyle == "collection" then
            manifest = {
                "projectionStyle" => "Nx49",
                "entity"          => miku,
            }
        end
        File.open("/Users/pascal/Desktop/nyx-projection-manifest.json", "w"){|f| f.puts(JSON.pretty_generate(manifest)) }
    end

    # Nx31::atomLandingPresentation(atomuuid)
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

    # Nx31::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
    end

    # Nx31::landing(miku)
    def self.landing(miku)
        loop {
            miku = Nx31::getOrNull(miku["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if miku.nil?
            system("clear")

            puts ""

            store = ItemStore.new()

            Links::parents(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{Nx31::toString(entity)}" 
                }

            Links::related(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{Nx31::toString(entity)}" 
                }

            Links::children(miku["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{Nx31::toString(entity)}" 
                }

            puts ""

            puts Nx31::toString(miku).green
            puts "uuid: #{miku["uuid"]}".yellow
            puts "datetime: #{miku["datetime"]}".yellow
            puts "atomuuid: #{miku["atomuuid"]}".yellow
            atom = Librarian6Objects::getObjectByUUIDOrNull(miku["atomuuid"])
            puts "atom: #{atom}".yellow

            Librarian7Notes::getObjectNotes(miku["uuid"]).each{|note|
                puts "note: #{note["text"]}"
            }

            Nx31::atomLandingPresentation(miku["atomuuid"])

            #Librarian::notes(miku["uuid"]).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | description | datetime | atom | note | notes | link | unlink | deep line | projection | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Nx31::landing(entity)
            end

            if Interpreting::match("access", command) then
                Nx31::accessAtom(miku["atomuuid"])
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(miku["description"]).strip
                next if description == ""
                description = Nx31::normaliseDescription(description)
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
                    puts "- #{Nx31::toString(entity)}"
                }
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("projection", command) then
                Nx31::issueProjectionFile(miku)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx31::destroy(miku["uuid"])
                    break
                end
            end
        }
    end

    # Nx31::nx20s()
    def self.nx20s()
        Nx31::mikus().map{|nx31|
            x1 = [{
                "announce" => "#{SecureRandom.hex[0, 8]} #{Nx31::toString(nx31)} [#{nx31["uuid"][0, 4]}]",
                "type"     => "Nx31",
                "payload"  => nx31
            }]
            x1
        }
        .flatten
    end

    # Nx31::nx20s2()
    def self.nx20s2()
        Nx31::mikus().map{|nx31|
            {
                "announce" => "#{SecureRandom.hex[0, 8]} #{nx31["uuid"]}",
                "type"     => "Nx31",
                "payload"  => nx31
            }
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx31::mikuToNx20s(miku)
    def self.mikuToNx20s(miku)
        # At the moment we only transform Nx31s
        x1 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{Nx31::toStringWithTrace4(miku)}]",
            "payload"  => miku
        }]
        x4 = [{
            "announce" => "#{SecureRandom.hex[0, 8]} #{miku["uuid"]}",
            "payload"  => miku
        }]
        (x1 + x4).flatten
    end

    # Nx31::getNx20s()
    def self.getNx20s()
        Nx31::mikus().map{|miku| Nx31::mikuToNx20s(miku) }.flatten
    end

    # ------------------------------------------------
    # Fsck

    # Nx31::fsck()
    def self.fsck()
        Nx31::mikus()
            .each{|miku|
                puts "fsck: #{miku["description"]}"
                status = Nx31::fsckNx31(miku)
                if !status then
                    puts "fsck failed on:".red
                    puts JSON.pretty_generate(miku).red
                    LucilleCore::pressEnterToContinue()
                end
            }
        puts "fsck completed".green
        LucilleCore::pressEnterToContinue()
    end

    # Nx31::fsckNx31(miku)
    def self.fsckNx31(miku)
        Librarian15Fsck::fsck(miku["atom"])
    end    
end
