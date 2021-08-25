# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Fitness::ns16s(),
            NxOnDate::ns16s(),
            Waves::ns16s(),
            DrivesBackups::ns16s(),
            Nx50s::ns16s(),
            Nx25s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end

$TaskServerElementsUUIDs = []

class TaskServer

    # TaskServer::getServerUUIDs()
    def self.getServerUUIDs()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "109fe3ef-a21b-4746-9851-f1ead5992693", "[]"))
    end

    # TaskServer::setServerUUIDs(uuids)
    def self.setServerUUIDs(uuids)
        KeyValueStore::set(nil, "109fe3ef-a21b-4746-9851-f1ead5992693", JSON.generate(uuids))
    end

    # TaskServer::removeFirstElement()
    def self.removeFirstElement()
        uuids = TaskServer::getServerUUIDs()
        uuids = uuids.drop(1)
        TaskServer::setServerUUIDs(uuids)
    end

    # TaskServer::extends(existing, ns16s)
    def self.extends(existing, ns16s)
        ns16s.reduce(existing){|elements, ns16|
            if elements.none?{|e| e["uuid"] == ns16["uuid"] } then
                elements + [ns16]
            else
                elements
            end
        }
    end

    # TaskServer::getNS16ByUUIDOrNull(ns16s, uuid)
    def self.getNS16ByUUIDOrNull(ns16s, uuid)
        ns16s.select{|ns16| ns16["uuid"] == uuid }.first
    end

    # TaskServer::ns16s()
    def self.ns16s()
        ns16s = NS16sOperator::ns16s()
        elements = TaskServer::getServerUUIDs()
                        .map{|uuid| TaskServer::getNS16ByUUIDOrNull(ns16s, uuid) }
                        .compact
                        .flatten
        elements = TaskServer::extends(elements, ns16s)
        TaskServer::setServerUUIDs(elements.map{|e| e["uuid"] })
        DetachedRunning::ns16s() + Nx51s::ns16s() + elements
    end
end
