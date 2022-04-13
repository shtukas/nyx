
# encoding: UTF-8

class Nx101Structure

    # Nx101Structure::interactivelyCreateNewStructureOrNull()
    def self.interactivelyCreateNewStructureOrNull()
        types = [
            "navigation",
            "atomic",
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
        if type == "primitive-file" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            data = Nx45s::readPrimitiveFileOrNull(location)
            return nil if data.nil?
            dottedExtension, nhash, parts = data
            return {
                "type"            => "primitive-file",
                "dottedExtension" => dottedExtension,
                "nhash"           => nhash,
                "parts"           => parts
            }
        end
        if type == "carrier-of-primitive-files" then
            return {
                "type" => "carrier-of-primitive-files"
            }
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

class Nx100Nodes

    # ----------------------------------------------------------------------
    # IO

    # Nx100Nodes::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx100Node")
    end

    # Nx100Nodes::getOrNull(uuid): null or Nx100Node
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx100Nodes::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx100Nodes::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        structure = Nx101Structure::interactivelyCreateNewStructureOrNull()
        return nil if structure.nil?

        flavour = Nx102Flavor::interactivelyCreateNewFlavour()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx100Node",
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

    # Nx100Nodes::toString(item)
    def self.toString(item)
        "#{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx100Nodes::landing(item)
    def self.landing(item)
        loop {
            item = Nx100Nodes::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx100Nodes::toString(item).green
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

            puts "access | description | datetime | attachment | link | unlink | destroy".yellow

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
                datetime = Utils::editTextSynchronously(item["datetime"]).strip
                next if !Utils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian6Objects::commit(item) 
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
                    Nx100Nodes::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx100Nodes::nx20s()
    def self.nx20s()
        Nx100Nodes::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx100Nodes::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
