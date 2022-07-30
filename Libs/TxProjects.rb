
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TxProject"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "ax39"        => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "ax39")),
        }
    end

    # TxProjects::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxProject")
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxProjects::interactivelyIssueNewItemOrNull() # item
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        uuid = SecureRandom.uuid

        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "TxProject")
        Fx18Attributes::set2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "ax39",        JSON.generate(ax39))
        FileSystemCheck::fsckObject(uuid)
        TxProjects::objectuuidToItemOrNull(objectuuid)
    end

    # TxProjects::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        items = TxProjects::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| LxFunction::function("toString", item) })
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new project ? ") then
            return TxProjects::interactivelyIssueNewItemOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Elements

    # TxProjects::addElement_v1(projectuuid, itemuuid)
    def self.addElement_v1(projectuuid, itemuuid)
        Fx18Sets::add2(projectuuid, "project-items-3f154988", itemuuid, itemuuid)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{itemuuid}", true)
    end

    # TxProjects::addElement_v2(projectuuid, elementuuid, ordinal)
    def self.addElement_v2(projectuuid, elementuuid, ordinal)
        packet = {
            "elementuuid" => elementuuid,
            "ordinal" => ordinal
        }
        Fx18Sets::add2(projectuuid, "project-elements-f589942d", elementuuid, packet)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}", true)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18Sets::remove2(project["uuid"], "project-items-3f154988", uuid)
        Fx18Sets::remove2(project["uuid"], "project-elements-f589942d", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        uuids1 = Fx18Sets::items(project["uuid"], "project-elements-f589942d")
                    .sort{|p1, p2| p1["ordinal"] <=> p2["ordinal"]}
                    .map{|packet| packet["elementuuid"]}
        uuids2 = Fx18Sets::items(project["uuid"], "project-items-3f154988")
        # We return the new elementuuids in ordinal order and then the old ones
        uuids1+uuids2
    end

    # TxProjects::elements(project, count)
    def self.elements(project, count)
        TxProjects::elementuuids(project)
            .take(count)
            .map{|elementuuid|
                if Fx18::objectIsAlive(elementuuid) then
                    item = Fx18::itemOrNull(elementuuid)
                    if item.nil? then
                        TxProjects::removeElement(project, elementuuid)
                    end
                    item
                else
                    nil
                end
            }
            .compact
    end

    # TxProjects::uuidIsProjectElement(elementuuid)
    def self.uuidIsProjectElement(elementuuid)
        #TxProjects::items().any?{|project| TxProjects::elementuuids(project).include?(elementuuid) }
        XCache::getFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}")
    end

    # ----------------------------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(project) #{item["description"]} #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxProjects::section2()
    def self.section2()
        TxProjects::items()
            .map{|item|
                {
                    "item" => item,
                    "toString" => TxProjects::toString(item),
                    "metric"   => (Ax39::itemShouldShow(item) ? 0.8 : 0.1) + Catalyst::idToSmallShift(item["uuid"])
                }
            }
    end

    # TxProjects::projectDefaultVisibilityDepth()
    def self.projectDefaultVisibilityDepth()
        50
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::interactivelySelectProjectElementOrNull(project, count)
    def self.interactivelySelectProjectElementOrNull(project, count)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("element", TxProjects::elements(project, count), lambda{|item| LxFunction::function("toString", item) })
    end

    # TxProjects::landing(item)
    def self.landing(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18::itemOrNull(uuid)

            return if item.nil?

            system("clear")

            puts TxProjects::toString(item).green

            store = ItemStore.new()

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            linkeduuids  = NxLink::linkedUUIDs(uuid)

            puts "commands: description | Ax39 | json | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::set2(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::set2(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("Ax39", command) then
                ax39 = Ax39::interactivelyCreateNewAx()
                Fx18Attributes::set2(uuid, "ax39", JSON.generate(ax39))
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

    # TxProjects::runAndAccessElements(project)
    def self.runAndAccessElements(project)
        NxBallsService::issue(project["uuid"], TxProjects::toString(project), [project["uuid"]])
        loop {
            system("clear")

            puts "running: #{TxProjects::toString(project).green} #{NxBallsService::activityStringOrEmptyString("", project["uuid"], "")}"

            store = ItemStore.new()

            puts ""
            elements = TxProjects::elements(project, TxProjects::projectDefaultVisibilityDepth())
            elements.each{|element|
                indx = store.register(element, false)
                puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", element)}"
            }

            if !Ax39::itemShouldShow(project) then
                puts ""
                if !LucilleCore::askQuestionAnswerAsBoolean("You are time overflowing, do you want to continue ? ") then
                    break
                end
            end

            puts ""
            puts "commands: <n> | insert | detach element | destroy element".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                Streaming::processItem(entity)
            end

            if command == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxLines::interactivelyIssueNewLineOrNull()
                    next if element.nil?
                    TxProjects::addElement_v2(project["uuid"], element["uuid"], 0) # TODO:
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull()
                    next if element.nil?
                    TxProjects::addElement_v2(project["uuid"], element["uuid"], 0) # TODO:
                end
            end

            if command == "detach element" then
                element = TxProjects::interactivelySelectProjectElementOrNull(project, TxProjects::projectDefaultVisibilityDepth())
                next if element.nil?
                TxProjects::removeElement(project, element["uuid"])
            end

            if command == "destroy element" then
                element = TxProjects::interactivelySelectProjectElementOrNull(project, TxProjects::projectDefaultVisibilityDepth())
                next if element.nil?
                LxAction::action("destroy", element)
            end
        }
        NxBallsService::close(project["uuid"], true)
    end

    # TxProjects::dive()
    def self.dive()
        loop {
            projects = TxProjects::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            project = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", projects, lambda{|item| TxProjects::toString(item) })
            break if project.nil?
            puts TxProjects::toString(project).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["landing", "access elements"])
            next if action.nil?
            if action == "landing" then
                TxProjects::landing(project)
            end
            if action == "access elements" then
                TxProjects::runAndAccessElements(project)
            end
        }
    end

    # TxProjects::interactivelyProposeToAttachTaskToProject(item)
    def self.interactivelyProposeToAttachTaskToProject(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a project ? ") then
            project = TxProjects::architectOneOrNull()
            return if project.nil?
            TxProjects::addElement_v1(project["uuid"], item["uuid"])
        end
    end
end
