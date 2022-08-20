class Owners

    # --------------------------------
    # Data

    # Owners::owners()
    def self.owners()
        NxTasks::items()
            .select{|item| Owners::itemIsOwner(item) }
    end

    # Owners::elements(owner, count)
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

    # Owners::toString(item)
    def self.toString(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        ax39str2 = Ax39::toString(item)
        "(#{item["mikuType"]}) #{item["description"]} #{ax39str2}#{doneForTodayStr}#{dnsustr}"
    end

    # Owners::toStringForSection1(item)
    def self.toStringForSection1(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        ax39str2 = Ax39forSections::toStringElements(item)
        ax39str2_2 = ax39str2[1] ? "#{"%6.2f" % ax39str2[1]} %" : ""
        "#{item["description"].ljust(50)} #{ax39str2[0].ljust(30)}#{ax39str2_2.rjust(10)}#{doneForTodayStr.rjust(18)}#{dnsustr.ljust(20)}"
    end

    # Owners::section2StringPrefix(item)
    def self.section2StringPrefix(item)
        item["description"]
    end

    # Owners::section1()
    def self.section1()
        Owners::owners()
            .select{|owner| Ax39forSections::itemShouldShow(owner) }
            .map{|item|
                {
                    "item" => item,
                    "ratio" => Ax39forSections::orderingValue(item)
                }
            }
            .sort{|p1, p2| p1["ratio"] <=> p2["ratio"]}
            .map{|px| px["item"] }
    end

    # Owners::section2()
    def self.section2()
        Owners::owners()
            .select{|owner| Ax39forSections::itemShouldShow(owner) }
            .map{|owner|
                {
                    "owner" => owner,
                    "ratio" => Ax39forSections::completionRatio(owner)
                }
            }
            .sort{|p1, p2| p1["ratio"] <=> p2["ratio"]}
            .map{|px| px["owner"] }
            .map{|owner|
                elements = Owners::elements(owner, 6)
                            .map{|element|
                                {
                                    "element" => element,
                                    "rt"      => BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])
                                }
                            }
                            .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                            .map{|px| px["element"] }

                if !elements.empty? then
                    elements.each{|element|
                        XCache::set("a95b9b32-cfc4-4896-b52b-e3c58b72f3ae:#{element["uuid"]}", "[#{Owners::section2StringPrefix(owner).white}] #{LxFunction::function("toString", element)}")
                    }
                    elements
                else
                    owner
                end
            }
    end
    # --------------------------------
    # Operations

    # Owners::interactivelyProposeToAttachThisElementToOwner(element)
    def self.interactivelyProposeToAttachThisElementToOwner(element)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to an owner ? ") then
            owner = Owners::architectOneOrNull()
            return if owner.nil?
            OwnerMapping::issue(owner["uuid"], element["uuid"])
        end
    end

    # Owners::addElementToOwner(element)
    def self.addElementToOwner(element)
        puts "Owners::addElementToOwner(#{element})"
        if !["NxTask", "NxLine"].include?(element["mikuType"]) then
            puts "The operation Owners::addElementToOwner only works on NxLines or NxTasks"
            LucilleCore::pressEnterToContinue()
            return
        end
        owner = Owners::architectOneOrNull()
        return if owner.nil?
        OwnerMapping::issue(owner["uuid"], element["uuid"])
        NxBallsService::close(element["uuid"], true)
    end

    # Owners::elementsLanding(owner)
    def self.elementsLanding(owner)
        loop {
            system("clear")

            puts Owners::toString(owner).green

            store = ItemStore.new()

            packets = Owners::elements(owner, 50)
            if packets.size > 0 then
                puts ""
                packets
                    .each{|element|
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            if Ax39::completionRatio(owner) >= 1 then
                puts ""
                puts "You are time overflowing"
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
                    element = NxTasks::interactivelyCreateNewOrNull()
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
                owner2 = Owners::architectOneOrNull()
                return if owner2.nil?
                OwnerMapping::issue(owner2["uuid"], entity["uuid"])
                OwnerMapping::detach(owner["uuid"], entity["uuid"])
                next
            end
        }
    end

    # Owners::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        items = Owners::owners()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("owner", items, lambda{|item| LxFunction::function("toString", item) })
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new owner ? ") then
            item = NxTasks::interactivelyCreateNewOrNull()
            return nil if item.nil?
            return item if item["ax39"]
            puts "You need to provide a Ax39 to this task to be a valid owner"
            LucilleCore::pressEnterToContinue()
            Fx18Attributes::setJsonEncoded(uuid, "ax39", Ax39::interactivelyCreateNewAx())
            return Fx256::getProtoItemOrNull(item["uuid"])
        end
        nil
    end

    # Owners::itemIsOwner(item)
    def self.itemIsOwner(item)
        item["mikuType"] == "NxTask" and item["ax39"]
    end

    # Owners::dive()
    def self.dive()
        loop {
            owners = Owners::owners().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            owner = LucilleCore::selectEntityFromListOfEntitiesOrNull("owner", owners, lambda{|item| Owners::toString(item) })
            break if owner.nil?
            Owners::elementsLanding(owner)
        }
    end
end