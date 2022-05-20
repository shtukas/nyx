# encoding: UTF-8

class ADayOfWork

    # ADayOfWork::getNS16sForUniverse(universe)
    def self.getNS16sForUniverse(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16sHighPriority(universe),
            Inbox::ns16s(),
            Waves::ns16sLowerPriority(universe),
            TxFyres::ns16s(universe),
            TxTodos::ns16s(universe).first(5)
        ].flatten
    end

    # ADayOfWork::getHighPriorityNS16sForUniverse(universe)
    def self.getHighPriorityNS16sForUniverse(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16sHighPriority(universe),
            Inbox::ns16s(),
            TxFyres::ns16s(universe)
        ].flatten
    end

    # ADayOfWork::removeRedundancy(items)
    def self.removeRedundancy(items)
        items
            .reduce([]){|selected, item|
                if selected.none?{|x| x["uuid"] == item["uuid"] } then
                    selected + [ item ]
                else
                    selected
                end
            }
    end

    # ADayOfWork::getCoreUUIDs(date)
    def self.getCoreUUIDs(date)
        uuids = XCache::getOrNull("276dc0b9-222c-4dd7-ba8f-88561678ab49:#{date}")
        return JSON.parse(uuids) if uuids
        ns16s = ADayOfWork::getNS16sForUniverse("backlog") + ADayOfWork::getNS16sForUniverse("work")
        ns16s = ADayOfWork::removeRedundancy(ns16s)
        uuids = ns16s.map{|ns16| ns16["uuid"] }
        XCache::set("276dc0b9-222c-4dd7-ba8f-88561678ab49:#{date}", JSON.generate(uuids))
        uuids
    end

    # ADayOfWork::getNS16s()
    def self.getNS16s()
        coreuuids = ADayOfWork::getCoreUUIDs(Utils::today())
        ns16s1 = (ADayOfWork::getNS16sForUniverse("backlog") + ADayOfWork::getNS16sForUniverse("work"))
                    .select{|ns16| coreuuids.include?(ns16["uuid"]) }
        ns16s2 = (ADayOfWork::getHighPriorityNS16sForUniverse("backlog") + ADayOfWork::getHighPriorityNS16sForUniverse("work"))
        ADayOfWork::removeRedundancy(ns16s1+ns16s2)
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

end


