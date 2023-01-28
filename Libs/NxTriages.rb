# encoding: UTF-8

class NxTriages

    # --------------------------------------------------
    # Makers

    # NxTriages::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx113 = Nx113Make::aionpoint(location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        TodoDatabase2::commitItem(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTriages::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(triage) #{item["description"]}#{nx113str}"
    end

    # --------------------------------------------------
    # Operations

    # NxTriages::access(item)
    def self.access(item)
        puts NxTriages::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTriages::probe(item)
    def self.probe(item)
        loop {
            actions = ["access", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTriages::access(item)
            end
            if action == "destroy" then
                TodoDatabase2::destroy(item["uuid"])
                return
            end
        }
    end
end
