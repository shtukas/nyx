
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

    # TxProjects::section1()
    def self.section1()
        TxProjects::items()
            .select{|project| !Ax39::itemShouldShow(project) }
    end

    # TxProjects::section2()
    def self.section2()
        TxProjects::items()
            .select{|project| Ax39::itemShouldShow(project) }
            .sort{|p1, p2| Ax39::completionRatio(p1) <=> Ax39::completionRatio(p2) }
            .map{|item|
                {
                    "item" => item,
                    "toString" => TxProjects::toString(item)
                }
            }
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::landing(project)
    def self.landing(project)
        system("clear")
        puts TxProjects::toString(project).green
        elementuuids = TxProjects::elementuuids(project)
        elements = elementuuids.map{|elementuuid| Fx18Utils::objectuuidToItemOrNull(elementuuid) }
        if elements.size == 1 then
            LxAction::action("..", elements[0])
            return
        end

        element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
        return if element.nil?
        LxAction::action("..", element)
    end

    # TxProjects::dive()
    def self.dive()
        loop {
            projects = TxProjects::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            project = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", projects, lambda{|item| TxProjects::toString(item) })
            break if project.nil?
            TxProjects::landing(project)
        }
    end

    # TxProjects::accessProject(project)
    def self.accessProject(project)
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

    # TxProjects::interactivelyProposeToAttachTaskToProject(item)
    def self.interactivelyProposeToAttachTaskToProject(item)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a project ? ") then
            project = TxProjects::architectOneOrNull()
            return if project.nil?
            TxProjects::addElement(project["uuid"], item["uuid"])
        end
    end
end
