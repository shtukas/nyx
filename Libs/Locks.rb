# encoding: UTF-8

class Locks

    # Locks::lock(domain, uuid)
    def self.lock(domain, uuid)
        TodoDatabase2::set(uuid, "field8", domain)
    end

    # Locks::isLocked(uuid)
    def self.isLocked(uuid)
        TodoDatabase2::getOrNull(uuid, "field8").to_s.size > 0
    end

    # Locks::unlock(uuid)
    def self.unlock(uuid)
        TodoDatabase2::set(uuid, "field8", "")
    end
end
