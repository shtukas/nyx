
# encoding: UTF-8

class Nx100s

    # ----------------------------------------------------------------------
    # IO

    # Nx100s::items()
    def self.items()
        Librarian::getObjectsByMikuType("Nx100")
    end

    # Nx100s::getOrNull(uuid): null or Nx100
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # Nx100s::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # Nx100s::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMaking(), uuid)
        return nil if nx111.nil?

        flavour = Nx102Flavor::interactivelyCreateNewFlavour()

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "i1as"        => [nx111],
            "flavour"     => flavour
        }
        Librarian::commit(item)
        item
    end

    # Nx100s::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        objectuuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(objectuuid, location)
        flavour = {
            "type" => "encyclopedia"
        }
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "i1as"        => [nx111],
            "flavour"     => flavour
        }
        Librarian::commit(item)
        item
    end

    # Nx100s::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil

        uuid = SecureRandom.uuid

        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, SecureRandom.uuid, location)
        return nil if nx111.nil?

        flavour = {
            "type" => "pure-data"
        }

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx100",
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "description" => description,
          "i1as"        => [nx111],
          "flavour"     => flavour
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx100s::toString(item)
    def self.toString(item)
        "(node) #{item["description"]}"
    end

    # Nx100s::selectItemsByYear(year)
    def self.selectItemsByYear(year)
        Nx100s::items().select{|item| item["datetime"][0, 4] == year }
    end

    # Nx100s::selectItemsByYearMonth(yearMonth)
    def self.selectItemsByYearMonth(yearMonth)
        Nx100s::items().select{|item| item["datetime"][0, 7] == yearMonth }
    end

    # Nx100s::selectItemsByFlavours(flavourType)
    def self.selectItemsByFlavours(flavourType)
        Nx100s::items().select{|item| item["flavour"]["type"] == flavourType }
    end

    # Nx100s::getDistictYearMonthsFromItems()
    def self.getDistictYearMonthsFromItems()
        Nx100s::items().map{|item| item["datetime"][0, 7] }.uniq.sort
    end

    # Nx100s::getItemsFromTheBiggestYearMonth()
    def self.getItemsFromTheBiggestYearMonth()
        last = Nx100s::getDistictYearMonthsFromItems()
            .map{|yearMonth|  
                {
                    "yearMonth" => yearMonth,
                    "items" => Nx100s::selectItemsByYearMonth(yearMonth)
                }
            }
            .sort{|p1, p2| p1["items"].size <=> p2["items"].size }
            .last
        last["items"].sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end

    # Nx100s::getItemsFromTheBiggestYearMonthGame1Edition()
    def self.getItemsFromTheBiggestYearMonthGame1Edition()
        last = Nx100s::getDistictYearMonthsFromItems()
            .map{|yearMonth|
                items = Nx100s::selectItemsByYearMonth(yearMonth)
                items = items.select{|item| !XCache::flagIsTrue("4636773d-6aa6-4835-b740-0415e4f9149e:#{item["uuid"]}") }
                {
                    "yearMonth" => yearMonth,
                    "items" => items
                }
            }
            .sort{|p1, p2| p1["items"].size <=> p2["items"].size }
            .last
        last["items"].sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx100s::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
        if I1as::toStringShort(item["i1as"]) != "aion-point" then
            puts "I can only do that with aion-points"
            LucilleCore::pressEnterToContinue()
            return
        end
        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Genesis",
            "i1as"        => item["i1as"].clone,
            "flavour"     => {
                "type" => "encyclopedia"
            }
        }
        puts JSON.pretty_generate(item2)
        Librarian::commit(item2)
        Links::link(item["uuid"], item2["uuid"], false)
        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "navigation"
        }
        item["i1as"] = [nx111] 
        puts JSON.pretty_generate(item)
        Librarian::commit(item)
        puts "Operation completed"
        LucilleCore::pressEnterToContinue()
    end

    # Nx100s::uploadAllLocationsOfAFolderAsAionPointChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPointChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = Nx100s::issueNewItemAionPointFromLocation(location)
            Links::link(item["uuid"], child["uuid"], false)
        }
    end

    # Nx100s::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = Nx100s::issuePrimitiveFileFromLocationOrNull(location)
            next if child.nil?
            Links::link(item["uuid"], child["uuid"], false)
        }
    end

    # Nx100s::landing(item)
    def self.landing(item)
        loop {
            return if item.nil?

            system("clear")

            if $NavigationSandboxState then
                puts "!! Selection sandbox, type `found` when found, or exit".green
            end

            uuid = item["uuid"]

            store = ItemStore.new()

            stack = TheNetworkStack::getStack()
            stack.each{|i| puts "(stack) #{LxFunction::function("toString", i)}" }
            if stack.size > 0 then
                puts ""
            end

            puts item["description"]
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            puts "i1as:"
            item["i1as"].each{|nx111|
                puts "    #{Nx111::toString(nx111)}"
            } 

            puts "flavour: #{item["flavour"]}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            linked = Links::linked(item["uuid"])
            if linked.size > 0 then
                puts "linked:"
                linked
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity| 
                        indx = store.register(entity, false)
                        linkType = Links::linkTypeOrNull(item["uuid"], entity["uuid"])
                        puts "    [#{indx.to_s.ljust(3)}] [#{linkType.ljust(7)}] #{LxFunction::function("toString", entity)}"
                    }
            end

            commands = []
            commands << "access"
            commands << "description"
            commands << "datetime"
            commands << "iam"
            commands << "flavour"
            commands << "note"
            commands << "link"
            commands << "relink"
            commands << "unlink"
            commands << "special ops"
            commands << "json"
            commands << "destroy"
            commands << "stack: add [this]"
            commands << "stack: add [from linked]"
            commands << "stack: clear"

            puts commands.join(" | ").yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if $NavigationSandboxState and command == "found" then
                $NavigationSandboxState = ["found", item.clone]
                return
            end

            if $NavigationSandboxState and command == "exit" then
                $NavigationSandboxState = ["exit"]
                return
            end

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItem(item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian::commit(item)
            end

            if Interpreting::match("iam", command) then
                item = I1as::manageI1as(item, item["i1as"])
            end

            if Interpreting::match("flavour", command) then
                flavour = Nx102Flavor::interactivelyCreateNewFlavour()
                next nil if flavour.nil?
                puts JSON.pretty_generate(flavour)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["flavour"] = flavour
                    Librarian::commit(item) 
                end
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOneOrMoreOthersArchitectured(item)
            end

            if Interpreting::match("relink", command) then
                NyxNetwork::relinkToOneOrMoreLinked(item)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromLinkedInteractively(item)
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("special ops", command) then
                operations = [
                    "transmute to navigation node and put contents into Genesis",
                    "upload all locations of a folder as aion-point children",
                    "upload all locations of a folder as primitive files children",
                    "select linked subset and move to one of the linked",
                    "select target node, select subset from linked and move subset to that node as children"
                ]
                operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                next if operation.nil?
                if operation == "transmute to navigation node and put contents into Genesis" then
                    Nx100s::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
                end
                if operation == "upload all locations of a folder as aion-point children" then
                    Nx100s::uploadAllLocationsOfAFolderAsAionPointChildren(item)
                end
                if operation == "upload all locations of a folder as primitive files children" then
                    Nx100s::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
                end
                if operation == "select linked subset and move to one of the linked" then
                    subset = NyxNetwork::selectSubsetOfLinked(item["uuid"])
                    target = NyxNetwork::selectOneLinkedOrNull(item["uuid"])
                    if target["uuid"] == item["uuid"] then
                        puts "The target node cannot be the node we are landed on"
                        LucilleCore::pressEnterToContinue()
                        next
                    end
                    subset.each{|i1|
                        puts "relocating: #{LxFunction::function("toString", i1)}"
                        Links::unlink(item["uuid"], i1["uuid"])
                        Links::link(target["uuid"], i1["uuid"], false)
                    }
                end
                if operation == "select target node, select subset from linked and move subset to that node as children" then
                    target = NyxNetwork::architectOneOrNull()
                    if target["uuid"] == item["uuid"] then
                        puts "The target node cannot be the node we are landed on"
                        LucilleCore::pressEnterToContinue()
                        next
                    end
                    NyxNetwork::selectSubsetOfLinked(item["uuid"])
                        .each{|i1|
                            puts "relocating: #{LxFunction::function("toString", i1)}"
                            Links::link(target["uuid"], i1["uuid"], false)
                            Links::unlink(item["uuid"], i1["uuid"])
                        }
                end
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx100s::destroy(item["uuid"])
                    break
                end
            end

            if command == "stack: add [this]" then
                TheNetworkStack::queue(item["uuid"])
            end

            if command == "stack: add [from linked]" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], Links::linked(item["uuid"]), lambda{ |i| LxFunction::function("toString", i) })
                selected.each{|ix|
                    TheNetworkStack::queue(ix["uuid"])
                }
            end

            if command == "stack: clear" then
                TheNetworkStack::clear()
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
