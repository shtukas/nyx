
# encoding: UTF-8

class Nx07

    # Nx07::items()
    def self.items()
        Librarian::getObjectsByMikuType("Nx07")
    end

    # Nx07::issue(principaluuid, targetuuid)
    def self.issue(principaluuid, targetuuid)
        item = {
            "uuid"          => SecureRandom.uuid,
            "variant"       => SecureRandom.uuid,
            "mikuType"      => "Nx07",
            "unixtime"      => Time.new.to_f,
            "principaluuid" => principaluuid,
            "targetuuid"    => targetuuid
        }
        Librarian::commit(item)
        EventsInternal::broadcast({
            "mikuType" => "(tasks modified)"
        })
        EventsInternal::broadcast({
            "mikuType"      => "(target is getting a new principal)",
            "principaluuid" => principaluuid,
            "targetuuid"    => targetuuid
        })
        item
    end

    # Nx07::unlink(principaluuid, targetuuid)
    def self.unlink(principaluuid, targetuuid)
        Nx07::items()
            .select{|item| item["principaluuid"] == principaluuid and item["targetuuid"] == targetuuid }
            .each{|item| Librarian::destroyClique(item["uuid"]) }

    end

    # Nx07::principaluuidToTaskuuids(principaluuid)
    def self.principaluuidToTaskuuids(principaluuid)
        Nx07::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| item["principaluuid"] == principaluuid }
            .map{|item| item["targetuuid"] }
            .uniq
    end

    # Nx07::targetUuidToPrincipalUuidOrNull(targetuuid)
    def self.targetUuidToPrincipalUuidOrNull(targetuuid)
        principaluuid = XCache::getOrNull("a2f66362-9959-424a-ae64-759998f1119b:#{targetuuid}")
        if principaluuid == "nothing" then
            return nil
        end
        if principaluuid then
            return principaluuid
        end
        databuilder = lambda{
            Nx07::items()
                .select{|item| item["targetuuid"] == targetuuid }
                .map{|item| item["principaluuid"] }
                .first
        }
        principaluuid = databuilder.call()
        if principaluuid then
            XCache::set("a2f66362-9959-424a-ae64-759998f1119b:#{targetuuid}", principaluuid)
            principaluuid
        else
            XCache::set("a2f66362-9959-424a-ae64-759998f1119b:#{targetuuid}", "nothing")
            nil
        end
    end

    # Nx07::getOwnerForTaskOrNull(task)
    def self.getOwnerForTaskOrNull(task)
        principaluuid = Nx07::targetUuidToPrincipalUuidOrNull(task["uuid"])
        return nil if principaluuid.nil?
        Librarian::getObjectByUUIDOrNullEnforceUnique(principaluuid)
    end

    # Nx07::itemHasPrincipal(item)
    def self.itemHasPrincipal(item)
        !Nx07::getOwnerForTaskOrNull(item).nil?
    end

    # Nx07::architectOwnerOrNull()
    def self.architectOwnerOrNull()
        items = (TxQueues::items()+TxProjects::items())
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("owner", items, lambda{|item| LxFunction::function("toString", item) })
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new owner (queue or project) ? ") then
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["project", "queue"])
            return nil if action.nil
            if action == "project" then
                return TxProjects::interactivelyIssueNewItemOrNull()
            end
            if action == "queue" then
                return TxQueues::interactivelyIssueNewItemOrNull()
            end
        end
    end
end
