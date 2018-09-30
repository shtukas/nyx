
# encoding: UTF-8

class CyclesOperator
    # CyclesOperator::updateObjectWithNS1935MetricIfNeeded(object)
    def self.updateObjectWithNS1935MetricIfNeeded(object)
        unixtime = MetadataInterface::getMetricCycleUnixtimeForObjectOrNull(object["uuid"])
        return object if unixtime.nil?
        return object if object["metric"] >= 1
        object["metric"] = CommonsUtils::unixtimeToMetricNS1935(unixtime.to_i)
        object
    end
end
