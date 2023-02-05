# encoding: UTF-8

class Locks

    # Locks::lock(uuid, domain)
    def self.lock(uuid, domain)
        Lookups::commit("Locks", uuid, domain)
    end

    # Locks::isLocked(uuid)
    def self.isLocked(uuid)
        !Lookups::getValueOrNull("Locks", uuid).nil?
    end

    # Locks::locknameOrNull(uuid)
    def self.locknameOrNull(uuid)
        Lookups::getValueOrNull("Locks", uuid)
    end

    # Locks::unlock(uuid)
    def self.unlock(uuid)
        Lookups::destroy("Locks", uuid)
    end
end
