
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "TxProject"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description"),
            "ax39"        => Fx18Utils::jsonParseIfNotNull(Fx18File::getAttributeOrNull(objectuuid, "ax39")),
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
        Fx18Utils::destroyFx18(uuid)
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
        Fx18File::setAttribute2(uuid, "uuid",        uuid2)
        Fx18File::setAttribute2(uuid, "mikuType",    "TxProject")
        Fx18File::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "ax39",        JSON.generate(ax39))

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
        Fx18File::setsAdd2(projectuuid, "project-items-3f154988", itemuuid, itemuuid)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18File::setsRemove2(project["uuid"], "project-items-3f154988", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18File::setsItems(project["uuid"], "project-items-3f154988")
    end

    # TxProjects::uuidIsProjectElement(uuid)
    def self.uuidIsProjectElement(uuid)
        TxProjects::items().any?{|project| TxProjects::elementuuids(project).include?(uuid) }
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

    # TxProjects::itemsForSection1()
    def self.itemsForSection1()
        TxProjects::items()
    end

    # TxProjects::elementsDepth()
    def self.elementsDepth()
        10
    end

    # TxProjects::section2Xp()
    def self.section2Xp()
        itemsToKeepOrReInject = []
        itemsToDelistIfPresentInListing = []

        TxProjects::items()
            .each{|project|
                if Ax39::itemShouldShow(project) or NxBallsService::isRunning(project["uuid"]) then
                    # itemsToKeepOrReInject << project
                    # TODO:
                else
                    itemsToDelistIfPresentInListing << project["uuid"]
                end
            }

        TxProjects::items()
            .each{|project|
                TxProjects::elementuuids(project)
                    .first(TxProjects::elementsDepth())
                    .select{|elementuuid|  
                        if NxBallsService::isRunning(elementuuid) then
                            # itemsToKeepOrReInject << item
                            # TODO:
                        else
                            itemsToDelistIfPresentInListing << elementuuid
                        end   
                    }
            }
        [itemsToKeepOrReInject, itemsToDelistIfPresentInListing]
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

    # TxProjects::startAccessProject(project)
    def self.startAccessProject(project)
        elementuuids = TxProjects::elementuuids(project).take(TxProjects::elementsDepth())
        elements = elementuuids.map{|elementuuid| Fx18Utils::objectuuidToItemOrNull(elementuuid) }
        if elements.size == 1 then
            LxAction::action("..", elements[0])
            return
        end

        element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
        return if element.nil?
        LxAction::action("..", element)
    end

    # TxProjects::interactivelyProposeToAttachTaskToProject(itemuuid)
    def self.interactivelyProposeToAttachTaskToProject(itemuuid)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a project ? ") then
            project = TxProjects::architectOneOrNull()
            return if project.nil?
            TxProjects::addElement(project["uuid"], itemuuid)
        end
    end
end
