
# encoding: UTF-8

class CyclesOperator

    # CyclesOperator::getUnixtimeOrNull(objectuuid)
    def self.getUnixtimeOrNull(objectuuid)
        unixtime = KeyValueStore::getOrNull(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}")
        return nil if unixtime.nil?
        unixtime.to_i
    end

    # CyclesOperator::setUnixtimeMark(objectuuid)
    def self.setUnixtimeMark(objectuuid)
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}", Time.new.to_i)
    end

    # CyclesOperator::removeUnixtimeMark(objectuuid)
    def self.removeUnixtimeMark(objectuuid)
        KeyValueStore::delete(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}")     
    end

    # CyclesOperator::updateObjectWithNS1935MetricIfNeeded(object)
    def self.updateObjectWithNS1935MetricIfNeeded(object)
        unixtime = CyclesOperator::getUnixtimeOrNull(object["uuid"])
        return object if unixtime.nil?
        return object if object["metric"] >= 1
        object["metric"] = CommonsUtils::unixtimeToMetricNS1935(unixtime.to_i)
        object
    end

end
