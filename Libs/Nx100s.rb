
# encoding: UTF-8

class Nx101Structure

    # Nx101Structure::primitiveFileStructureFromLocationOrNull(location)
    def self.primitiveFileStructureFromLocationOrNull(location)
        data = Librarian17PrimitiveFilesAndCarriers::readPrimitiveFileOrNull(location)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "type"            => "primitive-file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end

    # Nx101Structure::interactivelyCreateNewStructureOrNull()
    def self.interactivelyCreateNewStructureOrNull()
        types = [
            "navigation",
            "atomic",
            "log",
            "primitive-file",
            "carrier-of-primitive-files"
        ]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("structure type", types)
        return nil if type.nil?
        if type == "navigation" then
            return {
                "type" => "navigation"
            }
        end
        if type == "atomic" then
            atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
            return nil if atom.nil?
            return {
                "type"     => "atomic",
                "atomuuid" => atom["uuid"]
            }
        end
        if type == "log" then
            return {
                "type" => "log"
            }
        end
        if type == "primitive-file" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Nx101Structure::primitiveFileStructureFromLocationOrNull(location)
        end
        if type == "carrier-of-primitive-files" then
            return {
                "type" => "carrier-of-primitive-files"
            }
        end
    end

    # Nx101Structure::accessStructure(item, structure)
    def self.accessStructure(item, structure)
        if structure["type"] == "navigation" then
            puts "This is a navigation node"
            LucilleCore::pressEnterToContinue()
        end
        if structure["type"] == "atomic" then
            atom = Librarian6Objects::getObjectByUUIDOrNull(structure["atomuuid"])
            if atom.nil? then
                puts "structure:"
                puts JSON.pretty_generate(structure)
                puts "Could not find the atom 😞 Do you want to run fsck or something ?"
                LucilleCore::pressEnterToContinue()
                return
            end
            Librarian5Atoms::accessWithOptionToEditOptionalAutoMutation(atom)
        end
        if structure["type"] == "primitive-file" then
            dottedExtension = structure["dottedExtension"]
            parts = structure["parts"]
            location = "/Users/pascal/Desktop"
            filepath = Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(item["uuid"], dottedExtension, parts, location)
            LucilleCore::pressEnterToContinue()
            if File.exists?(filepath) and LucilleCore::askQuestionAnswerAsBoolean("delete file ? ") then
                FileUtils.rm(filepath)
            end
        end
        if structure["type"] == "carrier-of-primitive-files" then
            Librarian17PrimitiveFilesAndCarriers::exportCarrier(item["uuid"])
        end
    end
end

class Nx102Flavor

    # Nx102Flavor::interactivelyCreateNewFlavour()
    def self.interactivelyCreateNewFlavour()
        types = [
            "encyclopedia (default)",
            "of-interest-from-the-web",
            "calendar-item",
            "public-event",
            "pascal-personal-note"
        ]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("flavor type", types)
        if type.nil? then
            return {
                "type" => "encyclopedia"
            }
        end
        if type == "encyclopedia (default)" then
            return {
                "type" => "encyclopedia"
            }
        end
        if type == "of-interest-from-the-web" then
            return {
                "type" => "of-interest-from-the-web"
            }
        end
        if type == "calendar-item" then
            calendarDate = LucilleCore::askQuestionAnswerAsString("calendarDate (format: YYYY-MM-DD) : ")
            calendarTime = LucilleCore::askQuestionAnswerAsString("calendarTime (format: HH:MM) : ")
            active = true
            return {
                "type"         => "calendar-item",
                "calendarDate" => calendarDate,
                "calendarTime" => calendarTime,
                "active"       => active
            }
        end
        if type == "public-event" then
            eventDate = LucilleCore::askQuestionAnswerAsString("eventDate (format: YYYY-MM-DD) : ")
            return {
                "type"      => "public-event",
                "eventDate" => eventDate
            }
        end
        if type == "pascal-personal-note" then
            return {
                "type" => "pascal-personal-note"
            }
        end
    end
end

class Nx100s

    # ----------------------------------------------------------------------
    # IO

    # Nx100s::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx100")
    end

    # Nx100s::getOrNull(uuid): null or Nx100
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx100s::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx100s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        structure = Nx101Structure::interactivelyCreateNewStructureOrNull()
        return nil if structure.nil?

        flavourMaker = lambda {|structure|
            if structure["type"] == "primitive-file"  then
                return {
                    "type" => "pure-data"
                }
            end
            Nx102Flavor::interactivelyCreateNewFlavour()
        }

        flavour = flavourMaker.call(structure)

        uuidMaker = lambda {|structure|
            if structure["type"] == "primitive-file" then
                return Utils::nx45()
            end
            SecureRandom.uuid
        }

        uuid       = uuidMaker.call(structure)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "structure"   => structure,
            "flavour"     => flavour
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx100s::makePrimitiveFileFromLocationOrNull(location)
    def self.makePrimitiveFileFromLocationOrNull(location)
        description = nil

        structure = Nx101Structure::primitiveFileStructureFromLocationOrNull(location)
        return nil if structure.nil?

        flavour = {
            "type" => "pure-data"
        }

        uuid       = Utils::nx45()
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx100",
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "description" => description,
          "structure"   => structure,
          "flavour"     => flavour
        }
        Librarian6Objects::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx100s::toString(item)
    def self.toString(item)
        "#{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx100s::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
        if item["structure"]["type"] != "atomic" then
            puts "I can only do that with atomic nodes"
            LucilleCore::pressEnterToContinue()
            return
        end
        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Genesis",
            "structure"   => item["structure"].clone,
            "flavour"     => {
                "type" => "encyclopedia"
            }
        }
        puts JSON.pretty_generate(item2)
        Librarian6Objects::commit(item2)
        Links::link(item["uuid"], item2["uuid"], false)
        item["structure"] = {
            "type" => "navigation"
        }
        puts JSON.pretty_generate(item)
        Librarian6Objects::commit(item)
        puts "Operation completed"
        LucilleCore::pressEnterToContinue()
    end

    # Nx100s::landing(item)
    def self.landing(item)
        loop {
            item = Nx100s::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx100s::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "structure: #{item["structure"]}".yellow
            puts "flavour: #{item["flavour"]}".yellow

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

            commands = []
            commands << "access"
            commands << "description"
            commands << "datetime"
            commands << "structure"
            commands << "flavour"
            commands << "attachment"
            commands << "link"
            commands << "relink"
            commands << "unlink"
            commands << "special circumstances"
            commands << "destroy"

            puts commands.join(" | ").yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                Nx101Structure::accessStructure(item, item["structure"])
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

            if Interpreting::match("structure", command) then
                structure = Nx101Structure::interactivelyCreateNewStructureOrNull()
                next nil if structure.nil?
                puts JSON.pretty_generate(structure)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["structure"] = structure
                    Librarian6Objects::commit(item)
                end
            end

            if Interpreting::match("flavour", command) then
                flavour = Nx102Flavor::interactivelyCreateNewFlavour()
                next nil if flavour.nil?
                puts JSON.pretty_generate(flavour)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["flavour"] = flavour
                    Librarian6Objects::commit(item) 
                end
            end

            if Interpreting::match("attachment", command) then
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOtherArchitectured(item)
            end

            if Interpreting::match("relink", command) then
                NyxNetwork::relinkToOther(item)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromLinkedInteractively(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx100s::destroy(item["uuid"])
                    break
                end
            end

            if Interpreting::match("special circumstances", command) then
                operations = [
                    "transmute to navigation node and put contents into Genesis"
                ]
                operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                next if operation.nil?
                if operation == "transmute to navigation node and put contents into Genesis" then
                    Nx100s::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
                end
            end

        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx100s::nx20s()
    def self.nx20s()
        Nx100s::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx100s::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
