
# encoding: UTF-8

class Cx

    # Cx::interactivelyCreateNewCxForOwnerOrNull(owneruuid)
    def self.interactivelyCreateNewCxForOwnerOrNull(owneruuid)

    end

    # Cx::uuidToString(uuid)
    def self.uuidToString(uuid)

    end

    # Cx::access(uuid)
    def self.access(uuid)
        return if uuid.nil?
        puts "Cx::access(uuid)"
        LucilleCore::pressEnterToContinue()
    end
end
