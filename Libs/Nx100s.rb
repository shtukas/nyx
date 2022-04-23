
# encoding: UTF-8

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
    # Objects Makers

    # Nx100s::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodes())
        return nil if iAmValue.nil?

        flavourMaker = lambda {|iAmValue|
            if iAmValue[0] == "primitive-file"  then
                return {
                    "type" => "pure-data"
                }
            end
            Nx102Flavor::interactivelyCreateNewFlavour()
        }

        flavour = flavourMaker.call(iAmValue)

        uuidMaker = lambda {|iAmValue|
            if iAmValue[0] == "primitive-file" then
                return Utils::nx45()
            end
            SecureRandom.uuid
        }

        uuid       = uuidMaker.call(iAmValue)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "iam"         => iAmValue,
            "flavour"     => flavour
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx100s::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        iAmValue = Nx111::aionPointIamValueFromLocationOrNull(location)
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
            "iam"         => iAmValue,
            "flavour"     => flavour
        }
        Librarian6Objects::commit(item)
        item
    end

    # Nx100s::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil

        iAmValue = Nx111::primitiveFileIamValueFromLocationOrNull(location)
        return nil if iAmValue.nil?

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
          "iam"         => iAmValue,
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
        if item["iam"][0] != "aion-point" then
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
            "iam"         => item["iam"].clone,
            "flavour"     => {
                "type" => "encyclopedia"
            }
        }
        puts JSON.pretty_generate(item2)
        Librarian6Objects::commit(item2)
        Links::link(item["uuid"], item2["uuid"], false)
        item["iam"] = ["navigation"]
        puts JSON.pretty_generate(item)
        Librarian6Objects::commit(item)
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
            Librarian21Fsck::fsckExitAtFirstFailureLibrarianMikuObject(item)
            Links::link(item["uuid"], child["uuid"], false)
        }
    end

    # Nx100s::landing(item)
    def self.landing(item)
        loop {
            item = Nx100s::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            stack = TheNetworkStack::getStack()
            stack.each{|i| puts "(stack) #{LxFunction::function("toString", i)}" }
            if stack.size > 0 then
                puts ""
            end

            puts Nx100s::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "flavour: #{item["flavour"]}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
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

            if item["iam"][0] == "carrier-of-primitive-files" then
                commands << "upload (primitive files)"
            end

            commands << "datetime"
            commands << "iam"
            commands << "flavour"
            commands << "attachment"
            commands << "link"
            commands << "relink"
            commands << "unlink"
            commands << "json"
            commands << "special circumstances"
            commands << "destroy"
            commands << "stack: add [this]"
            commands << "stack: add [from children]"
            commands << "stack: clear"

            puts commands.join(" | ").yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("upload", command) then
                if item["iam"][0] != "carrier-of-primitive-files" then
                    puts "(this should not have happened)"
                    puts "I can only upload a carrier-of-primitive-files"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                Librarian17PrimitiveFilesAndCarriers::uploadCarrierOrNothing(item["uuid"])
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = Utils::editTextSynchronously(item["datetime"]).strip
                next if !Utils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian6Objects::commit(item)
            end

            if Interpreting::match("iam", command) then
                iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodes())
                next if iAmValue.nil?
                puts JSON.pretty_generate(iAmValue)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = iAmValue
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
                NyxNetwork::connectToOneOrMoreOthersArchitectured(item)
            end

            if Interpreting::match("relink", command) then
                NyxNetwork::relinkToOther(item)
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
                    "upload all locations of a folder as aion-point children"
                ]
                operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                next if operation.nil?
                if operation == "transmute to navigation node and put contents into Genesis" then
                    Nx100s::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
                end
                if operation == "upload all locations of a folder as aion-point children" then
                    Nx100s::uploadAllLocationsOfAFolderAsAionPointChildren(item)
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

            if command == "stack: add [from children]" then
                children = Links::children(item["uuid"])
                selected, _ = LucilleCore::selectZeroOrMore("item", [], children, lambda{ |i| LxFunction::function("toString", i) })
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
