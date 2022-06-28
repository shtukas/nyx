
# encoding: UTF-8

class Nx07

    # Nx07::items()
    def self.items()
        Librarian::getObjectsByMikuType("Nx07")
    end

    # Nx07::issue(queueuuid, taskuuid)
    def self.issue(queueuuid, taskuuid)
        item = {
            "uuid"      => SecureRandom.uuid,
            "variant"   => SecureRandom.uuid,
            "mikuType"  => "Nx07",
            "unixtime"  => Time.new.to_f,
            "queueuuid" => queueuuid,
            "taskuuid"  => taskuuid
        }
        Librarian::commit(item)
        item
    end

    # Nx07::queueuuidToTaskuuids(queueuuid)
    def self.queueuuidToTaskuuids(queueuuid)
        Nx07::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| item["queueuuid"] == queueuuid }
            .map{|item| item["taskuuid"] }
    end

    # Nx07::taskuuidToQueueuuidOrNull(taskuuid)
    def self.taskuuidToQueueuuidOrNull(taskuuid)
        Nx07::items()
            .select{|item| item["taskuuid"] == taskuuid }
            .map{|item| item["queueuuid"] }
            .first
    end
end
