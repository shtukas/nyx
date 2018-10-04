
# encoding: UTF-8

=begin
    NSXCanary exists because TimeProtons are not notified of an object having been discarded.
    TimeProtons will know whether or not an object has not been seen for a while using NSXCanary. 
=end

class NSXCanary
    # NSXCanary::mark(objectuuid)
    def self.mark(objectuuid)
        unixtime = Time.new.to_i
        NSXSystemDataOperator::set("7b748ba4-6ef1-463c-97fc-19186bbeb1d0:#{objectuuid}", Time.new.to_i)
        unixtime
    end
    # NSXCanary::getLastSeenUnixtimeOrNull(objectuuid)
    def self.getLastSeenUnixtimeOrNull(objectuuid)
        unixtime = NSXSystemDataOperator::getOrNull("7b748ba4-6ef1-463c-97fc-19186bbeb1d0:#{objectuuid}")
        return nil if unixtime.nil?
        unixtime.to_i
    end
    # NSXCanary::isAlive(objectuuid)
    def self.isAlive(objectuuid)
        unixtime = NSXCanary::getLastSeenUnixtimeOrNull(objectuuid)
        if unixtime.nil? then
            unixtime = NSXCanary::mark(objectuuid)
        end
        (Time.new.to_i - unixtime) < 86400*7 
    end
end
