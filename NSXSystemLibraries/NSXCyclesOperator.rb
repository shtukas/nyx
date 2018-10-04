
# encoding: UTF-8

class NSXCyclesOperator
    # NSXCyclesOperator::updateObjectWithNS1935MetricIfNeeded(object)
    def self.updateObjectWithNS1935MetricIfNeeded(object)
        return object if object["is-running"]
        return object if object["metric"] >= 1
        unixtime = NSXCatalystMetadataInterface::getMetricCycleUnixtimeForObjectOrNull(object["uuid"])
        return object if unixtime.nil?
        object["metric"] = CommonsUtils::unixtimeToMetricNS1935(unixtime.to_i)
        object[":metric-updated-by:NSXCyclesOperator::updateObjectWithNS1935MetricIfNeeded:"] = true
        object
    end
end
