# encoding: UTF-8

class Locks

    # Locks::lock(domain, uuid)
    def self.lock(domain, uuid)
        TodoDatabase2::set(uuid, "field8", domain)
    end

    # Locks::isLocked(item)
    def self.isLocked(item)
        item["field8"] and item["field8"].size > 0
    end

    # Locks::unlock(uuid)
    def self.unlock(uuid)
        TodoDatabase2::set(uuid, "field8", "")
    end
end
