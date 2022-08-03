
# encoding: UTF-8

class TxThreads

    # ----------------------------------------------------------------------
    # IO

    # TxThreads::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TxThread"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "ax39"        => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "ax39")),
        }
    end

    # TxThreads::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxThread")
    end

    # TxThreads::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxThreads::interactivelyIssueNewItemOrNull() # item
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAxOrNull()

        uuid = SecureRandom.uuid

        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "TxThread")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_f)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "ax39",        JSON.generate(ax39)) if ax39
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = TxThreads::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 196d5021-a7d2-4d23-8e70-851d81c9f994) How did that happen ? 🤨"
        end
        item
    end

    # TxThreads::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        items = TxThreads::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", items, lambda{|item| LxFunction::function("toString", item) })
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new thread ? ") then
            return TxThreads::interactivelyIssueNewItemOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Elements

    # TxThreads::addElement_v1(threaduuid, itemuuid)
    def self.addElement_v1(threaduuid, itemuuid)
        Fx18Sets::add2(threaduuid, "project-items-3f154988", itemuuid, itemuuid)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{itemuuid}", true)
    end

    # TxThreads::addElement_v2(threaduuid, elementuuid, ordinal)
    def self.addElement_v2(threaduuid, elementuuid, ordinal)
        packet = {
            "elementuuid" => elementuuid,
            "ordinal" => ordinal
        }
        Fx18Sets::add2(threaduuid, "project-elements-f589942d", elementuuid, packet)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}", true)
    end

    # TxThreads::removeElement(thread, uuid)
    def self.removeElement(thread, uuid)
        Fx18Sets::remove2(thread["uuid"], "project-items-3f154988", uuid)
        Fx18Sets::remove2(thread["uuid"], "project-elements-f589942d", uuid)
    end

    # TxThreads::elementuuids(thread)
    def self.elementuuids(thread)
        uuids1 = Fx18Sets::items(thread["uuid"], "project-elements-f589942d")
                    .sort{|p1, p2| p1["ordinal"] <=> p2["ordinal"]}
                    .map{|packet| packet["elementuuid"]}
        uuids2 = Fx18Sets::items(thread["uuid"], "project-items-3f154988")
        # We return the new elementuuids in ordinal order and then the old ones
        uuids1+uuids2
    end

    # TxThreads::elements(thread, count)
    def self.elements(thread, count)
        TxThreads::elementuuids(thread)
            .take(count)
            .map{|elementuuid|
                if Fx18::objectIsAlive(elementuuid) then
                    item = Fx18::itemOrNull(elementuuid)
                    if item.nil? then
                        TxThreads::removeElement(thread, elementuuid)
                    end
                    item
                else
                    nil
                end
            }
            .compact
    end

    # TxThreads::uuidIsProjectElement(elementuuid)
    def self.uuidIsProjectElement(elementuuid)
        #TxThreads::items().any?{|thread| TxThreads::elementuuids(thread).include?(elementuuid) }
        XCache::getFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}")
    end

    # ----------------------------------------------------------------------
    # Data

    # TxThreads::toString(item)
    def self.toString(item)
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(thread) #{item["description"]} #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxThreads::section1()
    def self.section1()
        TxThreads::items()
            .select{|thread| !Ax39::itemShouldShow(thread) }
    end

    # TxThreads::section2()
    def self.section2()
        TxThreads::items()
            .map{|item|
                {
                    "item" => item,
                    "toString" => TxThreads::toString(item),
                    "metric"   => (Ax39::itemShouldShow(item) ? 0.8 : 0.1) + Catalyst::idToSmallShift(item["uuid"])
                }
            }
    end

    # TxThreads::threadDefaultVisibilityDepth()
    def self.threadDefaultVisibilityDepth()
        50
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxThreads::interactivelySelectProjectElementOrNull(thread, count)
    def self.interactivelySelectProjectElementOrNull(thread, count)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("element", TxThreads::elements(thread, count), lambda{|item| LxFunction::function("toString", item) })
    end

    # TxThreads::landing(item)
    def self.landing(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18::itemOrNull(uuid)

            return if item.nil?

            system("clear")

            puts TxThreads::toString(item).green

            store = ItemStore.new()

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            linkeduuids  = NxLink::linkedUUIDs(uuid)

            puts "commands: description | Ax39 | remove Ax39 | json | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("Ax39", command) then
                ax39 = Ax39::interactivelyCreateNewAx()
                Fx18Attributes::set_objectUpdate(uuid, "ax39", JSON.generate(ax39))
            end

            if Interpreting::match("remove Ax39", command) then
                Fx18Attributes::set_objectUpdate(uuid, "ax39", JSON.generate(nil))
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18::deleteObject(item["uuid"])
                    break
                end
            end
        }
    end

    # TxThreads::runAndAccessElements(thread)
    def self.runAndAccessElements(thread)
        NxBallsService::issue(thread["uuid"], TxThreads::toString(thread), [thread["uuid"]])
        loop {
            system("clear")

            puts "running: #{TxThreads::toString(thread).green} #{NxBallsService::activityStringOrEmptyString("", thread["uuid"], "")}"

            store = ItemStore.new()

            elements = TxThreads::elements(thread, TxThreads::threadDefaultVisibilityDepth())
            if elements.size > 0 then
                puts ""
                elements
                    .sort{|e1, e2| e1["unixtime"] <=> e2["unixtime"] }
                    .each{|element|
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            if !Ax39::itemShouldShow(thread) then
                puts ""
                puts "You are time overflowing"
            end

            puts ""
            puts "commands: <n> | insert | done (thread) | detach <n> | done <n>".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Streaming::processItem(entity)
            end

            if command == "done" then
                DoneForToday::setDoneToday(thread["uuid"])
                NxBallsService::close(thread["uuid"], true)
                break
            end

            if command == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxLines::interactivelyIssueNewLineOrNull()
                    next if element.nil?
                    TxThreads::addElement_v2(thread["uuid"], element["uuid"], 0) # TODO:
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull()
                    next if element.nil?
                    TxThreads::addElement_v2(thread["uuid"], element["uuid"], 0) # TODO:
                end
            end

            if  command.start_with?("done") and command != "done" then
                indx = command[4, 99].to_i
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("done", entity)
                next
            end

            if  command.start_with?("detach") and command != "detach" then
                indx = command[6, 99].to_i
                entity = store.get(indx)
                next if entity.nil?
                TxThreads::removeElement(thread, entity["uuid"])
                next
            end
        }
    end

    # TxThreads::dive()
    def self.dive()
        loop {
            threads = TxThreads::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| TxThreads::toString(item) })
            break if thread.nil?
            puts TxThreads::toString(thread).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["landing", "access elements"])
            next if action.nil?
            if action == "landing" then
                TxThreads::landing(thread)
            end
            if action == "access elements" then
                TxThreads::runAndAccessElements(thread)
            end
        }
    end

    # TxThreads::interactivelyProposeToAttachTaskToProject(item)
    def self.interactivelyProposeToAttachTaskToProject(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a thread ? ") then
            thread = TxThreads::architectOneOrNull()
            return if thread.nil?
            TxThreads::addElement_v1(thread["uuid"], item["uuid"])
        end
    end

    # TxThreads::entityToProject(entity)
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
            puts "The operation >thread only works on NxTasks and NxLines"
            LucilleCore::pressEnterToContinue()
            return
        end
        thread = TxThreads::architectOneOrNull()
        return if thread.nil?
        TxThreads::addElement_v1(thread["uuid"], entity["uuid"])
        NxBallsService::close(entity["uuid"], true)
    end
end
