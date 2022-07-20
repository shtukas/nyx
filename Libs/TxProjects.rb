
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
        Fx18Utils::destroyFx18EmitEvents(uuid)
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
        Listing::remove(itemuuid)
        SystemEvents::issueStargateDrop({
            "mikuType" => "(remove item from listing)",
            "objectuuid" => itemuuid
        })
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18Sets::remove2(project["uuid"], "project-items-3f154988", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18Sets::items(project["uuid"], "project-items-3f154988")
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
        count = TxProjects::elementuuids(item).count
        "(project) #{item["description"]} (#{count} items) #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxProjects::section2()
    def self.section2()
        TxProjects::items()
            .select{|project| !Ax39::itemShouldShow(project) or !DoNotShowUntil::isVisible(project["uuid"]) }
            .each{|project|
                TxProjects::elementuuids(project)
                    .each{|elementuuid|
                        next if NxBallsService::isRunning(elementuuid)
                        Listing::remove(elementuuid)
                    }
            }

        TxProjects::items()
            .select{|project| Ax39::itemShouldShow(project) }
            .sort{|p1, p2| Ax39::completionRatio(p1) <=> Ax39::completionRatio(p2) }
            .map{|project|
                items = TxProjects::elementuuids(project)
                            .reduce([]){|items, elementuuid|
                                if items.size >= 3 then
                                    items
                                else
                                    item = Fx18Utils::objectuuidToItemOrNull(elementuuid)
                                    if item then
                                        items + [item]
                                    else
                                        items
                                    end
                                end
                            }

                rt = lambda{|item| BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) }

                items
                    .sort{|i1, i2|
                        rt.call(i1) <=> rt.call(i2)
                    }

                items
            }
            .flatten
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
        elementuuids = TxProjects::elementuuids(project).take(10)
        elements = elementuuids.map{|elementuuid| Fx18Utils::objectuuidToItemOrNull(elementuuid) }
        if elements.size == 1 then
            LxAction::action("..", elements[0])
            return
        end

        element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
        return if element.nil?
        LxAction::action("..", element)
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
