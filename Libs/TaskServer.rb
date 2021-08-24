# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Fitness::ns16s(),
            NxOnDate::ns16s(),
            Waves::ns16s(),
            Inbox::ns16s(),
            DrivesBackups::ns16s(),
            Nx50s::ns16s(),
            Nx51s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end

$TaskServerElements = []

class TaskServer

    # TaskServer::removeFirstElement()
    def self.removeFirstElement()
        $TaskServerElements = $TaskServerElements.drop(1)
    end

    # TaskServer::addElementsIfNotPresentYet(existingQueue, ns16s)
    def self.addElementsIfNotPresentYet(existingQueue, ns16s)
        ns16s.reduce(existingQueue){|elements, ns16|
            if elements.none?{|e| e["uuid"] == ns16["uuid"] } then
                elements + [ns16]
            else
                elements
            end
        }
    end

    # TaskServer::ns16s()
    def self.ns16s()
        $TaskServerElements = TaskServer::addElementsIfNotPresentYet($TaskServerElements.clone, NS16sOperator::ns16s())
        $TaskServerElements.clone
    end
end
