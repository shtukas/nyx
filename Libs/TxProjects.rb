
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::items()
    def self.items()
        Librarian::mikuTypeUUIDs("TxProject").map{|objectuuid|
            {
                "uuid"        => objectuuid,
                "mikuType"    => "TxProject",
                "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
                "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
                "ax39"        => JSON.parse(Fx18s::getAttributeOrNull(objectuuid, "ax39")),
            }
        }
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxProjects::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        uuid = SecureRandom.uuid

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid2)
        Fx18s::setAttribute2(uuid, "mikuType",    "TxProject")
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "ax39",        JSON.generate(ax39))

        uuid
    end

    # TxProjects::architectOneOrNull() # objectuuid or null
    def self.architectOneOrNull()
        items = TxProjects::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| LxFunction::function("toString", item) })
        return item["uuid"] if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new project ? ") then
            return TxProjects::interactivelyIssueNewItemOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Elements

    # TxProjects::addElement(projectuuid, itemuuid)
    def self.addElement(projectuuid, itemuuid)
        Fx18s::ensureFile(projectuuid)
        Fx18s::setsAdd2(projectuuid, "project-items-3f154988", itemuuid, itemuuid)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18s::ensureFile(project["uuid"])
        Fx18s::setsRemove2(project["uuid"], "project-items-3f154988", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18s::ensureFile(project["uuid"])
        Fx18s::setsItems(project["uuid"], "project-items-3f154988")
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

    # TxProjects::nx20s()
    def self.nx20s()
        TxProjects::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxProjects::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
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
                            itemsToDelistIfPresentInListing << item["uuid"]
                        end   
                    }
            }
        [itemsToKeepOrReInject, itemsToDelistIfPresentInListing]
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::dive()
    def self.dive()
        loop {
            project = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", TxProjects::items(), lambda{|item| TxProjects::toString(item) })
            break if project.nil?
            Landing::landing(project)
        }
    end

    # TxProjects::startAccessProject(project)
    def self.startAccessProject(project)
        elementuuids = TxProjects::elementuuids(project).take(TxProjects::elementsDepth())
        if elementuuids.size == 1 then
            LxAction::action("..2", elementuuids[0])
            return
        end
        elementuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("elementuuid", elementuuids, lambda{|itemuuid| LxFunction::function("toString2", itemuuid) } )
        return if elementuuid.nil?
        LxAction::action("..2", elementuuid)
    end
end
