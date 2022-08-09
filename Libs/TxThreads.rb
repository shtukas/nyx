
# encoding: UTF-8

class TxThreads

    # ----------------------------------------------------------------------
    # IO

    # TxThreads::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "TxThread"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "ax39"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "ax39")
        }
    end

    # TxThreads::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxThread")
    end

    # TxThreads::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObjectLogically(uuid)
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
        Fx18s::makeNewLocalFx18FileForObjectuuid(uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "TxThread")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    Time.new.to_f)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "ax39",        JSON.generate(ax39)) if ax39

        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
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

    # TxThreads::addElement(threaduuid, elementuuid)
    def self.addElement(threaduuid, elementuuid)
        Fx18Sets::add2(threaduuid, "project-items-3f154988", elementuuid, elementuuid)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}", true)
    end

    # TxThreads::removeElement(thread, uuid)
    def self.removeElement(thread, uuid)
        Fx18Sets::remove2(thread["uuid"], "project-items-3f154988", uuid)
    end

    # TxThreads::elementuuids(thread)
    def self.elementuuids(thread)
        Fx18Sets::items(thread["uuid"], "project-items-3f154988")
    end

    # TxThreads::extendedPacketsInOrder(thread, count)
    def self.extendedPacketsInOrder(thread, count)
        Fx18Sets::items(thread["uuid"], "project-items-3f154988")
            .first(count)
            .map{|elementuuid|
                {
                    "elementuuid" => elementuuid,
                    "element"     => Fx18s::getItemAliveOrNull(elementuuid),
                }
            }
            .select{|packet| !packet["element"].nil? }
            .sort{|p1, p2| p1["element"]["unixtime"] <=> p2["element"]["unixtime"] }
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
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"]}
    end

    # TxThreads::section2(priority)
    def self.section2(priority)
        TxThreads::items()
            .select{|thread| Ax39::itemShouldShow(thread) }
            .sort{|t1, t2| Ax39::completionRatio(t1) <=> Ax39::completionRatio(t2)}
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxThreads::landingOnThread(item)
    def self.landingOnThread(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18s::getItemAliveOrNull(uuid)

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

    # TxThreads::runAndLandingOnElements(thread)
    def self.runAndLandingOnElements(thread)
        NxBallsService::issue(thread["uuid"], TxThreads::toString(thread), [thread["uuid"]])
        loop {
            system("clear")

            puts "running: #{TxThreads::toString(thread).green} #{NxBallsService::activityStringOrEmptyString("", thread["uuid"], "")}"

            store = ItemStore.new()

            packets = TxThreads::extendedPacketsInOrder(thread, 50)
            if packets.size > 0 then
                puts ""
                packets
                    .each{|packet|
                        element = packet["element"]
                        indx = store.register(element, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
                    }
            end

            if !Ax39::itemShouldShow(thread) then
                puts ""
                puts "You are time overflowing"
            end

            puts ""
            puts "commands: <n> | insert | done (thread) | done <n> | detach <n> | transfer <n>".yellow

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
                    TxThreads::addElement(thread["uuid"], element["uuid"])
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull()
                    next if element.nil?
                    TxThreads::addElement(thread["uuid"], element["uuid"])
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
                TxThreads::removeElement(thread, entity["uuid"])
                next
            end

            if  command.start_with?("transfer") and command != "transfer" then
                indx = command[8, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                thread2 = TxThreads::architectOneOrNull()
                return if thread2.nil?
                TxThreads::addElement(thread2["uuid"], entity["uuid"])
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
                TxThreads::landingOnThread(thread)
            end
            if action == "access elements" then
                TxThreads::runAndLandingOnElements(thread)
            end
        }
    end

    # TxThreads::interactivelyProposeToAttachTaskToProject(item)
    def self.interactivelyProposeToAttachTaskToProject(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a thread ? ") then
            thread = TxThreads::architectOneOrNull()
            return if thread.nil?
            TxThreads::addElement(thread["uuid"], item["uuid"])
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
        TxThreads::addElement(thread["uuid"], entity["uuid"])
        NxBallsService::close(entity["uuid"], true)
    end
end
