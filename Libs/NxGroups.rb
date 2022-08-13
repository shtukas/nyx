
# encoding: UTF-8

class NxGroups

    # ----------------------------------------------------------------------
    # IO

    # NxGroups::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxGroup"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "ax39"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "ax39")
        }
    end

    # NxGroups::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxGroup")
    end

    # NxGroups::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxGroups::interactivelyIssueNewItemOrNull() # item
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAxOrNull()

        uuid = SecureRandom.uuid
        Fx18s::makeNewLocalFx18FileForObjectuuid(uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "NxGroup")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    Time.new.to_f)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "ax39",        ax39) if ax39

        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxGroups::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 196d5021-a7d2-4d23-8e70-851d81c9f994) How did that happen ? 🤨"
        end
        item
    end

    # NxGroups::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        items = NxGroups::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", items, lambda{|item| LxFunction::function("toString", item) })
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new thread ? ") then
            return NxGroups::interactivelyIssueNewItemOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Elements

    # NxGroups::elementuuids(thread)
    def self.elementuuids(thread)
        ItemToGroupMapping::groupuuidToItemuuids(thread["uuid"])
    end

    # NxGroups::elements(thread, count)
    def self.elements(thread, count)
        NxGroups::elementuuids(thread)
            .first(count)
            .map{|elementuuid|  
                element = Fx18s::getItemAliveOrNull(elementuuid)
                if element.nil? then
                    ItemToGroupMapping::detach(thread, elementuuid)
                end
                element
            }
            .compact
            .sort{|e1, e2| e1["unixtime"] <=> e2["unixtime"] }
    end

    # ----------------------------------------------------------------------
    # Data

    # NxGroups::toString(item)
    def self.toString(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        ax39str2 = Ax39::toString(item)
        "(group) #{item["description"]} #{Ax39::toString(item)}#{doneForTodayStr}#{dnsustr}"
    end

    # NxGroups::toStringAdjusted(item)
    def self.toStringAdjusted(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        ax39str2 = Ax39::toString2(item)
        ax39str2_2 = ax39str2[1] ? "#{"%6.2f" % ax39str2[1]} %" : ""
        "(group) #{item["description"].ljust(50)} #{ax39str2[0].ljust(30)}#{ax39str2_2.rjust(10)}#{doneForTodayStr.rjust(18)}#{dnsustr.ljust(20)}"
    end

    # NxGroups::section1()
    def self.section1()
        NxGroups::items()
            .sort{|t1, t2| Ax39::completionRatio(t1) <=> Ax39::completionRatio(t2)}
    end

    # NxGroups::section2()
    def self.section2()
        threads = NxGroups::items()
            .select{|thread| Ax39::itemShouldShow(thread) }
            .sort{|t1, t2| Ax39::completionRatio(t1) <=> Ax39::completionRatio(t2)}
        return [] if threads.empty?
        thread1 = threads.shift
        elements = NxGroups::elements(thread1, 6)
        elements.each{|element|
            XCache::set("a95b9b32-cfc4-4896-b52b-e3c58b72f3ae:#{element["uuid"]}", "[#{NxGroups::toString(thread1)}]".yellow + " #{LxFunction::function("toString", element)}")
        }
        elements
    end

    # ----------------------------------------------------------------------
    # Operations

    # NxGroups::metadataLanding(item)
    def self.metadataLanding(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18s::getItemAliveOrNull(uuid)

            return if item.nil?

            system("clear")

            puts NxGroups::toString(item).green

            store = ItemStore.new()

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            linkeduuids  = NetworkLinks::linkeduuids(uuid)

            puts "commands: description | Ax39 | remove Ax39 | json | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::setJsonEncodeUpdate(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::setJsonEncodeUpdate(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("Ax39", command) then
                ax39 = Ax39::interactivelyCreateNewAx()
                Fx18Attributes::setJsonEncodeUpdate(uuid, "ax39", JSON.generate(ax39))
            end

            if Interpreting::match("remove Ax39", command) then
                Fx18Attributes::setJsonEncodeUpdate(uuid, "ax39", JSON.generate(nil))
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18s::deleteObjectLogically(item["uuid"])
                    break
                end
            end
        }
    end

    # NxGroups::elementsLanding(group)
    def self.elementsLanding(group)
        NxBallsService::issue(group["uuid"], NxGroups::toString(group), [group["uuid"]])
        loop {
            system("clear")

            puts "running: #{NxGroups::toString(group).green} #{NxBallsService::activityStringOrEmptyString("", group["uuid"], "")}"

            store = ItemStore.new()

            packets = NxGroups::elements(group, 50)
            if packets.size > 0 then
                puts ""
                packets
                    .each{|element|
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            if Ax39::completionRatio(group) > 1 then
                puts ""
                puts "You are time overflowing"
            end

            puts ""
            puts "commands: <n> | insert | done (group) | done <n> | detach <n> | transfer <n>".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Streaming::processItem(entity)
            end

            if command == "done" then
                DoneForToday::setDoneToday(group["uuid"])
                NxBallsService::close(group["uuid"], true)
                break
            end

            if command == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxLines::interactivelyIssueNewLineOrNull()
                    next if element.nil?
                    ItemToGroupMapping::issue(group["uuid"], element["uuid"])
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull()
                    next if element.nil?
                    ItemToGroupMapping::issue(group["uuid"], element["uuid"])
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
                ItemToGroupMapping::detach(group, entity["uuid"])
                next
            end

            if  command.start_with?("transfer") and command != "transfer" then
                indx = command[8, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                group2 = NxGroups::architectOneOrNull()
                return if group2.nil?
                ItemToGroupMapping::issue(group2["uuid"], entity["uuid"])
                ItemToGroupMapping::detach(group, entity["uuid"])
                next
            end
        }
    end

    # NxGroups::dive()
    def self.dive()
        loop {
            threads = NxGroups::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| NxGroups::toString(item) })
            break if thread.nil?
            puts NxGroups::toString(thread).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["landing", "access elements"])
            next if action.nil?
            if action == "landing" then
                NxGroups::metadataLanding(thread)
            end
            if action == "access elements" then
                NxGroups::elementsLanding(thread)
            end
        }
    end

    # NxGroups::interactivelyProposeToAttachTaskToProject(item)
    def self.interactivelyProposeToAttachTaskToProject(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a thread ? ") then
            thread = NxGroups::architectOneOrNull()
            return if thread.nil?
            ItemToGroupMapping::issue(thread["uuid"], item["uuid"])
        end
    end

    # NxGroups::entityToProject(entity)
    def self.entityToProject(entity)
        if entity["mikuType"] == "TxDated" then
            return if !LucilleCore::askQuestionAnswerAsBoolean("Going to convert the TxDated into a NxTask ", true)
            Transmutation::transmutation1(entity, "TxDated", "NxTask")
            # This transmutation already put the newly created NxTask into a thread
            # So we can return
            return
        end
        if entity["mikuType"] == "NxFrame" then
            return if !LucilleCore::askQuestionAnswerAsBoolean("Going to convert the NxFrame into a NxTask ", true)
            Transmutation::transmutation1(entity, "NxFrame", "NxTask")
            # This transmutation already put the newly created NxTask into a thread
            # So we can return
            return
        end
        if !["NxTask", "NxLine"].include?(entity["mikuType"]) then
            puts "The operation >group only works on NxTasks and NxLines"
            LucilleCore::pressEnterToContinue()
            return
        end
        thread = NxGroups::architectOneOrNull()
        return if thread.nil?
        ItemToGroupMapping::issue(thread["uuid"], entity["uuid"])
        NxBallsService::close(entity["uuid"], true)
    end
end
