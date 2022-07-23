
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TxProject"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "ax39"        => Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "ax39")),
        }
    end

    # TxProjects::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("TxProject")
            .map{|objectuuid| TxProjects::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyLocalFx18EmitEvents(uuid)
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

        Fx18Utils::makeNewFile(uuid)
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "TxProject")
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        Fx18Attributes::setAttribute2(uuid, "ax39",        JSON.generate(ax39))
        FileSystemCheck::fsckLocalObjectuuid(uuid)
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

    # TxProjects::addElement(projectuuid, itemuuid)
    def self.addElement(projectuuid, itemuuid)
        Fx18Sets::add2(projectuuid, "project-items-3f154988", itemuuid, itemuuid)
        XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{itemuuid}", true)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18Sets::remove2(project["uuid"], "project-items-3f154988", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18Sets::items(project["uuid"], "project-items-3f154988")
    end

    # TxProjects::elements(project, count)
    def self.elements(project, count)
        TxProjects::elementuuids(project)
            .take(count)
            .map{|elementuuid| Fx18Utils::objectuuidToItemOrNull(elementuuid)}
            .compact
    end

    # TxProjects::uuidIsProjectElement(elementuuid)
    def self.uuidIsProjectElement(elementuuid)
        #TxProjects::items().any?{|project| TxProjects::elementuuids(project).include?(elementuuid) }
        XCache::getFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}")
    end

    # TxProjects::getProjectPerElementUUIDOrNull(uuid)
    def self.getProjectPerElementUUIDOrNull(uuid)
        TxProjects::items()
            .select{|project| TxProjects::elementuuids(project).include?(uuid) }
            .first
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

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::landing(item)
    def self.landing(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18Utils::objectuuidToItemOrNull(uuid)

            return if item.nil?

            if item.nil? then
                Fx18Index1::removeEntry(uuid)
            end

            system("clear")

            puts TxProjects::toString(item).green

            store = ItemStore.new()

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            linkeduuids  = NxLink::linkedUUIDs(uuid)

            puts "commands: description | json | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::setAttribute2(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::setAttribute2(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18Utils::destroyLocalFx18EmitEvents(item["uuid"])
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
            puts "running: #{TxProjects::toString(project).green}"
            elements = TxProjects::elements(project, 50)
            if elements.empty? then
                if LucilleCore::askQuestionAnswerAsBoolean("Project '#{TxProjects::toString(project).green}' doesn't have elements. Keep running ? ") then
                    return
                else
                    NxBallsService::close(project["uuid"], true)
                    return
                end
            end
            element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
            break if element.nil?
            Streaming::processItem(element)
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
            TxProjects::addElement(project["uuid"], item["uuid"])
        end
    end
end
