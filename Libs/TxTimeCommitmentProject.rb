# encoding: UTF-8

class TxTimeCommitmentProjects

    # --------------------------------------------------
    # IO

    # TxTimeCommitmentProjects::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("TxTimeCommitmentProject")
    end

    # TxTimeCommitmentProjects::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxTimeCommitmentProjects::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
        return nil if datetime.nil?
        uuid = SecureRandom.uuid

        if LucilleCore::askQuestionAnswerAsBoolean("Singleton item ? ") then
            nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        else
            puts "You have chosen to build an owner, not asking for contents"
            nx111 = nil
        end

        ax39 = Ax39::interactivelyCreateNewAx()

        unixtime   = Time.new.to_i
        DxF1s::setJsonEncoded(uuid, "uuid",         uuid)
        DxF1s::setJsonEncoded(uuid, "mikuType",     "TxTimeCommitmentProject")
        DxF1s::setJsonEncoded(uuid, "unixtime",     unixtime)
        DxF1s::setJsonEncoded(uuid, "datetime",     datetime)
        DxF1s::setJsonEncoded(uuid, "description",  description)
        DxF1s::setJsonEncoded(uuid, "nx111",        nx111)
        DxF1s::setJsonEncoded(uuid, "elementuuids", [])
        DxF1s::setJsonEncoded(uuid, "ax39",         ax39)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObject(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 058e5a67-7fbe-4922-b638-2533428ee019) How did that happen ? 🤨"
        end
        item
    end

    # TxTimeCommitmentProjects::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        item = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new TxTimeCommitmentProject ? ") then
            return TxTimeCommitmentProjects::interactivelyCreateNewOrNull()
        end
        nil
    end

    # --------------------------------------------------
    # Data

    # TxTimeCommitmentProjects::toString(item)
    def self.toString(item)
        ax39str2 = Ax39::toString(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(tcpt) #{item["description"]} #{ax39str2}#{doneForTodayStr}#{dnsustr}"
    end

    # TxTimeCommitmentProjects::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(tcpt) #{item["description"]}"
    end

    # TxTimeCommitmentProjects::listingItems()
    def self.listingItems()
        TxTimeCommitmentProjects::items()
            .select{|item| Ax39forSections::itemShouldShow(item) }
            .sort{|i1, i2| Ax39forSections::orderingValue(i1) <=> Ax39forSections::orderingValue(i2) }
    end

    # TxTimeCommitmentProjects::elements(owner, count)
    def self.elements(owner, count)
        OwnerMapping::owneruuidToElementsuuids(owner["uuid"]).uniq
            .first(count)
            .map{|elementuuid|  
                element = Fx256::getAliveProtoItemOrNull(elementuuid)
                if element.nil? then
                    OwnerMapping::detach(owner["uuid"], elementuuid)
                end
                element
            }
            .compact
            .sort{|e1, e2| e1["unixtime"] <=> e2["unixtime"] }
    end

    # --------------------------------------------------
    # Operations

    # TxTimeCommitmentProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = TxTimeCommitmentProjects::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("TxTimeCommitmentProject", items, lambda{|item| TxTimeCommitmentProjects::toString(item) })
    end

    # TxTimeCommitmentProjects::landing(item)
    def self.landing(item)
        Landing::implementsNx111Landing(item, false)
    end

    # TxTimeCommitmentProjects::access(item)
    def self.access(item)
        system("clear")
        elements = TxTimeCommitmentProjects::elements(item, 50)

        if item["nx111"] and elements.size > 0 then
            puts "Accessing '#{TxTimeCommitmentProjects::toString(item).green}}'"
            aspect = LucilleCore::selectEntityFromListOfEntitiesOrNull("aspect", ["access own Nx111", "elements listing"])
            return if aspect.nil?
            if aspect == "access own Nx111" then
                LxAction::action("start", item)
                Nx111::access(item, item["nx111"])
            end
            if aspect == "elements listing" then
                Catalyst::printListingLoop("Time Commitment Project: #{TxTimeCommitmentProjects::toString(item).green}", elements)
            end
        end

        if item["nx111"].nil? and elements.size > 0 then
            Catalyst::printListingLoop("Time Commitment Project: #{TxTimeCommitmentProjects::toString(item).green}", elements)
        end

        if item["nx111"] and elements.size == 0 then
            LxAction::action("start", item)
            Nx111::access(item, item["nx111"])
        end

        if item["nx111"].nil? and elements.size == 0 then
            LxAction::action("start", item)
        end
    end

    # TxTimeCommitmentProjects::doubleDot(item)
    def self.doubleDot(item)
        TxTimeCommitmentProjects::access(item)
    end

    # TxTimeCommitmentProjects::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxTimeCommitmentProjects::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxTimeCommitmentProjects::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item, isSearchAndSelect = false)
        }
    end

    # TxTimeCommitmentProjects::elementsInventory(owner)
    def self.elementsInventory(owner)
        loop {
            system("clear")

            puts TxTimeCommitmentProjects::toString(owner).green

            store = ItemStore.new()

            items = TxTimeCommitmentProjects::elements(owner, 6)
            if items.size > 0 then
                puts ""
                puts "Managed Items:"
                items
                    .map{|element|
                        {
                            "element" => element,
                            "rt"      => BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                    .map{|px| px["element"] }
                    .each{|element|
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            items = TxTimeCommitmentProjects::elements(owner, 50)
            if items.size > 0 then
                puts ""
                puts "50 Elements:"
                TxTimeCommitmentProjects::elements(owner, 50)
                    .each{|element|
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            puts ""
            puts "commands: <n> | insert | done (owner) | done <n> | detach <n> | transfer <n>".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Streaming::processItem(entity)
            end

            if command == "done" then
                DoneForToday::setDoneToday(owner["uuid"])
                NxBallsService::close(owner["uuid"], true)
                break
            end

            if command == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxLines::interactivelyIssueNewLineOrNull()
                    next if element.nil?
                    OwnerMapping::issue(owner["uuid"], element["uuid"])
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull(false)
                    next if element.nil?
                    OwnerMapping::issue(owner["uuid"], element["uuid"])
                end
            end

            if  command.start_with?("done") and command != "done" then
                indx = command[4, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("done", entity)
                next
            end

            if  command.start_with?("detach") and command != "detach" then
                indx = command[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                OwnerMapping::detach(owner["uuid"], entity["uuid"])
                next
            end

            if  command.start_with?("transfer") and command != "transfer" then
                indx = command[8, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                owner2 = TxTimeCommitmentProjects::architectOneOrNull()
                return if owner2.nil?
                OwnerMapping::issue(owner2["uuid"], entity["uuid"])
                OwnerMapping::detach(owner["uuid"], entity["uuid"])
                next
            end
        }
    end

    # TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(element)
    def self.interactivelyAddThisElementToOwner(element)
        puts "TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(#{JSON.pretty_generate(element)})"
        if element["mikuType"] == "TxIncoming" then
            DxF1s::setJsonEncoded(element["uuid"], "mikuType", "NxLine")
            element = Fx256::getProtoItemOrNull(element["uuid"])
        end
        if !["NxTask", "NxLine"].include?(element["mikuType"]) then
            puts "The operation TxTimeCommitmentProjects::interactivelyAddThisElementToOwner only works on NxLines or NxTasks"
            LucilleCore::pressEnterToContinue()
            return
        end
        owner = TxTimeCommitmentProjects::architectOneOrNull()
        return if owner.nil?
        OwnerMapping::issue(owner["uuid"], element["uuid"])
        NxBallsService::close(element["uuid"], true)
    end

    # TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(element)
    def self.interactivelyProposeToAttachThisElementToOwner(element)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to an owner ? ") then
            owner = TxTimeCommitmentProjects::architectOneOrNull()
            return if owner.nil?
            OwnerMapping::issue(owner["uuid"], element["uuid"])
        end
    end
end
