
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxProject")
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxProjects::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx("TxProject")

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "ax39"        => ax39
        }
        Librarian::commit(item)
        item
    end

    # TxProjects::architectOneOrNull()
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

    # TxProjects::addElement(project, item)
    def self.addElement(project, item)
        Fx18s::ensureFile(project["uuid"])
        Fx18s::setsAdd2(project["uuid"], "project-items-3f154988", item["uuid"], item["uuid"], false)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18s::ensureFile(project["uuid"])
        Fx18s::setsRemove2(project["uuid"], "project-items-3f154988", uuid, false)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18s::ensureFile(project["uuid"])
        Fx18s::setsItems(project["uuid"], "project-items-3f154988", false)
    end

    # TxProjects::elements(project)
    def self.elements(project)
        TxProjects::elementuuids(project)
            .map{|elementuuid| Librarian::getObjectByUUIDOrNullEnforceUnique(elementuuid)}
            .compact
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
        Librarian::getObjectsByMikuType("TxProject")
    end

    # TxProjects::itemsForMainListing()
    def self.itemsForMainListing()
        projects = Librarian::getObjectsByMikuType("TxProject")
                    .select{|project|
                        b1 = Ax39::itemShouldShow(project) 
                        if !b1 then
                            Stratification::removeItemByUUID(project["uuid"])
                            TxProjects::elementuuids(project)
                                .select{|elementuuid| !NxBallsService::isRunning(elementuuid) }
                                .each{|elementuuid| Stratification::removeItemByUUID(elementuuid) }
                        end
                        b2 = TxProjects::elementuuids(project).none?{|elementuuid| NxBallsService::isRunning(elementuuid) }
                        b1 and b2
                    }
        tasks = Librarian::getObjectsByMikuType("TxProject")
                    .map{|project|
                        runningElements = TxProjects::elementuuids(project)
                                            .select{|elementuuid| NxBallsService::isRunning(elementuuid) }
                                            .map{|elementuuid| Librarian::getObjectByUUIDOrNullEnforceUnique(elementuuid) }
                                            .compact
                        if runningElements.size > 0 then
                            Stratification::removeItemByUUID(project["uuid"])
                        end
                        runningElements
                    }
                    .flatten
        projects+tasks
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
        elements = TxProjects::elements(project)
        if elements.size == 1 then
            LxAction::action("..", elements[0])
            return
        end
        element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
        return if element.nil?
        LxAction::action("..", element)
    end

end
