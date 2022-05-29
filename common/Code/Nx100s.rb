
# encoding: UTF-8

class Nx100s

    # ----------------------------------------------------------------------
    # IO

    # Nx100s::items()
    def self.items()
        LocalObjectsStore::getObjectsByMikuType("Nx100")
    end

    # Nx100s::getOrNull(uuid): null or Nx100
    def self.getOrNull(uuid)
        LocalObjectsStore::getObjectByUUIDOrNull(uuid)
    end

    # Nx100s::destroy(uuid)
    def self.destroy(uuid)
        LocalObjectsStore::logicaldelete(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # Nx100s::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodes())
        return nil if nx111.nil?

        flavour = Nx102Flavor::interactivelyCreateNewFlavour()

        uuidMaker = lambda {|nx111|
            if nx111["type"] == "primitive-file" then
                return DidactUtils::nx45()
            end
            SecureRandom.uuid
        }

        uuid       = uuidMaker.call(nx111)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "iam"        => nx111,
            "flavour"     => flavour
        }
        LocalObjectsStore::commit(item)
        item
    end

    # Nx100s::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        nx111 = Nx111::locationToAionPointNx111OrNull(location)
        flavour = {
            "type" => "encyclopedia"
        }
        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "iam"        => nx111,
            "flavour"     => flavour
        }
        LocalObjectsStore::commit(item)
        item
    end

    # Nx100s::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil

        uuid = DidactUtils::nx45()

        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)
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
          "iam"         => nx111,
          "flavour"     => flavour
        }
        LocalObjectsStore::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx100s::toString(item)
    def self.toString(item)
        "#{item["description"]}"
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
        if item["iam"]["type"] != "aion-point" then
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
            "iam"        => item["iam"].clone,
            "flavour"     => {
                "type" => "encyclopedia"
            }
        }
        puts JSON.pretty_generate(item2)
        LocalObjectsStore::commit(item2)
        Links::link(item["uuid"], item2["uuid"], false)
        item["iam"] = {
            "uuid" => SecureRandom.uuid,
            "type" => "navigation"
        }
        puts JSON.pretty_generate(item)
        LocalObjectsStore::commit(item)
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

            if !item["isSnapshot"] then
                item = Nx100s::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            end

            system("clear")

            if $NavigationSandboxState then
                puts "!! Selection sandbox, type `found` or `exit` !!".green
            end

            uuid = item["uuid"]

            store = ItemStore.new()

            stack = TheNetworkStack::getStack()
            stack.each{|i| puts "(stack) #{LxFunction::function("toString", i)}" }
            if stack.size > 0 then
                puts ""
            end

            snapshotString = item["isSnapshot"] ? "[!! SNAPSHOT !!] ".white : ""

            puts snapshotString + "(Nx100, Nyx Node) #{Nx100s::toString(item)}".green
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "flavour: #{item["flavour"]}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }
            Ax1Text::itemsForOwner(uuid).each{|note|
                indx = store.register(note, false)
                puts "[#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
            }

            Links::linked(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    linkType = Links::linkTypeOrNull(item["uuid"], entity["uuid"])
                    puts "[#{indx.to_s.ljust(3)}] [#{linkType.ljust(7)}] #{LxFunction::function("toString", entity)}" 
                }

            commands = []
            commands << "access"
            commands << "description"

            if item["iam"]["type"] == "carrier-of-primitive-files" then
                commands << "upload (primitive files)"
            end

            commands << "datetime"
            commands << "iam"
            commands << "flavour"
            commands << "note"
            commands << "attachment"
            commands << "link"
            commands << "relink"
            commands << "unlink"
            commands << "network transforms"
            commands << "json"
            commands << "special circumstances"
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
                description = DidactUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                LocalObjectsStore::commit(item)
                next
            end

            if Interpreting::match("upload", command) then
                if item["iam"]["type"] != "carrier-of-primitive-files" then
                    puts "(this should not have happened)"
                    puts "I can only upload a carrier-of-primitive-files"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                Carriers::addPrimitiveFilesToCarrierOrNothing(item["uuid"])
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = DidactUtils::editTextSynchronously(item["datetime"]).strip
                next if !DidactUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                LocalObjectsStore::commit(item)
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodes())
                next if nx111.nil?
                puts JSON.pretty_generate(nx111)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = nx111
                    LocalObjectsStore::commit(item)
                end
            end

            if Interpreting::match("flavour", command) then
                flavour = Nx102Flavor::interactivelyCreateNewFlavour()
                next nil if flavour.nil?
                puts JSON.pretty_generate(flavour)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["flavour"] = flavour
                    LocalObjectsStore::commit(item) 
                end
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("attachment", command) then
                ox = TxAttachments::interactivelyIssueNewOrNullForOwner(item["uuid"])
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

            if Interpreting::match("special circumstances", command) then
                operations = [
                    "transmute to navigation node and put contents into Genesis",
                    "upload all locations of a folder as aion-point children",
                    "upload all locations of a folder as primitive files children"
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
            end

            if Interpreting::match("network transforms", command) then
                operations = [
                    "select linked subset and move to one of the linked",
                    "select target node, select subset from linked and move subset to that node as children"
                ]
                operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                next if operation.nil?
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

    # Nx100s::nx20sAddition1()
    def self.nx20sAddition1()
        Nx100s::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{item["uuid"]} #{Nx100s::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end