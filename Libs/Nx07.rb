
# encoding: UTF-8

class Nx07

    # Nx07::items()
    def self.items()
        Librarian::getObjectsByMikuType("Nx07")
    end

    # Nx07::issue(owneruuid, taskuuid)
    def self.issue(owneruuid, taskuuid)
        item = {
            "uuid"      => SecureRandom.uuid,
            "variant"   => SecureRandom.uuid,
            "mikuType"  => "Nx07",
            "unixtime"  => Time.new.to_f,
            "owneruuid" => owneruuid,
            "taskuuid"  => taskuuid
        }
        Librarian::commit(item)
        item
    end

    # Nx07::unlink(owneruuid, targetuuid)
    def self.unlink(owneruuid, targetuuid)
        Nx07::items()
            .select{|item| item["owneruuid"] == owneruuid and item["taskuuid"] == targetuuid }
            .each{|item| Librarian::destroyClique(item["uuid"]) }

    end

    # Nx07::owneruuidToTaskuuids(owneruuid)
    def self.owneruuidToTaskuuids(owneruuid)
        Nx07::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| item["owneruuid"] == owneruuid }
            .map{|item| item["taskuuid"] }
            .uniq
    end

    # Nx07::taskuuidToOwneruuidOrNull(taskuuid)
    def self.taskuuidToOwneruuidOrNull(taskuuid)
        Nx07::items()
            .select{|item| item["taskuuid"] == taskuuid }
            .map{|item| item["owneruuid"] }
            .first
    end

    # Nx07::getOwnerForTaskOrNull(task)
    def self.getOwnerForTaskOrNull(task)
        owneruuid = Nx07::taskuuidToOwneruuidOrNull(task["uuid"])
        return nil if owneruuid.nil?
        Librarian::getObjectByUUIDOrNullEnforceUnique(owneruuid)
    end

    # Nx07::taskHasOwner(item)
    def self.taskHasOwner(item)
        !Nx07::getOwnerForTaskOrNull(item).nil?
    end

    # Nx07::architectOwnerOrNull()
    def self.architectOwnerOrNull()
        items = (TxTaskQueues::items()+TxProjects::items())
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
                return TxTaskQueues::interactivelyIssueNewItemOrNull()
            end
        end
    end
end
