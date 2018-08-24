
# encoding: UTF-8

class CyclesOperator

    # CyclesOperator::getUnixtimeOrNull(objectuuid)
    def self.getUnixtimeOrNull(objectuuid)
        unixtime = FKVStore::getOrNull ("630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}")
        return nil if unixtime.nil?
        unixtime.to_i
    end

    # CyclesOperator::setUnixtimeMark(objectuuid)
    def self.setUnixtimeMark(objectuuid)
        FKVStore::set("630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}", Time.new.to_i)
    end

    # CyclesOperator::removeUnixtimeMark(objectuuid)
    def self.removeUnixtimeMark(objectuuid)
        FKVStore::delete("630d820a-2c80-49a0-96ae-23837e13f0b0:#{objectuuid}")     
    end

    # CyclesOperator::updateObjectWithNewMetricIfNeeded(object)
    def self.updateObjectWithNewMetricIfNeeded(object)
        unixtime = CyclesOperator::getUnixtimeOrNull(object["uuid"])
        return object if unixtime.nil?
        ageInHours = (Time.new.to_f - unixtime).to_f/3600
        metric = 0.5 + 0.4*(1-Math.exp(-ageInHours))
        object["metric"] = metric
        object
    end

end
