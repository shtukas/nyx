# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class UIServices

    # UIServices::ns17sToNS16s(ns17s)
    def self.ns17sToNS16s(ns17s)
        ns17s.sort{|i1, i2| i1["ratio"] <=> i2["ratio"] }.map{|item| item["ns16s"] }.flatten
    end

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Priority1::ns16OrNull(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16sHighPriority(),
            UIServices::ns17sToNS16s(Work::ns17s() + Waves::ns17sLowPriority() + Nx50s::ns17s())
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::ns16sToTrace(ns16s)
    def self.ns16sToTrace(ns16s)
        ns16s.first(3).map{|item| item["uuid"] }.join(";")
    end

    # UIServices::programmableListingDisplay(getItems: Lambda: () -> Array[NS16], processItems: Lambda: Array[NS16] -> Status)
    def self.programmableListingDisplay(getItems, processItems)
        loop {
            items = getItems.call()
            status = processItems.call(items)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end
end
