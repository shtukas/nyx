# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class UIServices

    # UIServices::ns16s()
    def self.ns16s()
        items1 = [
            DetachedRunning::ns16s(),
            Calendar::ns16s(),
            Priority1::ns16OrNull(),
            Anniversaries::ns16s(),
            Waves::ns16sHighPriority(),
            Work::ns16(),
            Endless::ns16s(),
            Nx31s::ns16s(),
            Nx50s::ns16()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| Metrics::metricDataToFloat(item["metric"]) > 0 }
            .sort{|item1, item2| Metrics::metricDataToFloat(item1["metric"]) <=> Metrics::metricDataToFloat(item2["metric"]) }
            .reverse
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
