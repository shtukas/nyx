
# encoding: UTF-8

# TimePointsCore::getTimePoints()
# TimePointsCore::getTimePointByUUID(uuid)
# TimePointsCore::saveTimePoint(timepoint)
# TimePointsCore::startTimePoint(timepoint)
# TimePointsCore::stopTimePoint(timepoint)
# TimePointsCore::destroyTimePoint(timepoint)
# TimePointsCore::garbageCollection()
# TimePointsCore::getUniqueDomains(timepoints)
# TimePointsCore::issueNewPoint(domain, description, hours)
# TimePointsCore::timePointToMetric(timepoint)
# TimePointsCore::timePointToRatioDoneUpToDate(timepoint)

class TimePointsCore
    def self.getTimePoints()
        SetsOperator::values(CATALYST_COMMON_TIMEPOINTS_ITEMS_REPOSITORY_PATH, CATALYST_COMMON_TIMEPOINTS_ITEMS_SETUUID)
            .compact
    end

    def self.getTimePointByUUID(uuid)
        SetsOperator::getOrNull(CATALYST_COMMON_TIMEPOINTS_ITEMS_REPOSITORY_PATH, CATALYST_COMMON_TIMEPOINTS_ITEMS_SETUUID, uuid)
    end

    def self.saveTimePoint(timepoint)
        SetsOperator::insert(CATALYST_COMMON_TIMEPOINTS_ITEMS_REPOSITORY_PATH, CATALYST_COMMON_TIMEPOINTS_ITEMS_SETUUID, timepoint["uuid"], timepoint)
        timepoint
    end

    def self.startTimePoint(timepoint)
        return timepoint if timepoint["is-running"]
        timepoint["is-running"] = true
        timepoint["last-start-unixtime"] = Time.new.to_i
        timepoint
    end

    def self.stopTimePoint(timepoint)
        return timepoint if !timepoint["is-running"]
        timepoint["is-running"] = false
        timespanInSeconds = Time.new.to_i - timepoint["last-start-unixtime"]
        timepoint["timespans"] << timespanInSeconds
        timepoint
    end

    def self.destroyTimePoint(timepoint)
        self.stopTimePoint(timepoint)
        SetsOperator::delete(CATALYST_COMMON_TIMEPOINTS_ITEMS_REPOSITORY_PATH, CATALYST_COMMON_TIMEPOINTS_ITEMS_SETUUID, timepoint["uuid"])
    end

    def self.garbageCollection()
        TimePointsCore::getTimePoints()
            .select{|timepoint| !timepoint["is-running"] }
            .select{|timepoint| TimePointsCore::timepointToDueTimeinHoursUpToDate(timepoint) <= 0 }
            .each{|timepoint| TimePointsCore::destroyTimePoint(timepoint) }
    end

    def self.getUniqueDomains(timepoints)
        timepoints.map{|timepoint| timepoint["domain"] }.uniq
    end

    def self.issueNewPoint(domain, description, hours)
        item = {
            "uuid"                => SecureRandom.hex(4),
            "creation-unixtime"   => Time.new.to_i,
            "domain"              => domain,
            "description"         => description,
            "commitment-in-hours" => hours,
            "timespans"           => [],
            "last-start-unixtime" => 0
        }
        TimePointsCore::saveTimePoint(item)
    end

    def self.timepointToTimeDoneInHoursAtRest(timepoint)
       timepoint["timespans"].inject(0, :+).to_f/3600
    end

    def self.timePointToTimeDoneInHoursUpToDate(timepoint)
        timedone1 = timepoint["timespans"].inject(0, :+).to_f/3600
        timedone2 = ( timepoint["is-running"] ? Time.new.to_i - timepoint["last-start-unixtime"] : 0 ).to_f/3600
        timedone1+timedone2
    end

    def self.timepointToDueTimeinHoursUpToDate(timepoint)
        t1 = timepoint["commitment-in-hours"] - timepoint["timespans"].inject(0, :+).to_f/3600
        t2 = ( timepoint["is-running"] ? Time.new.to_i - timepoint["last-start-unixtime"] : 0 ).to_f/3600
        [t1-t2, 0].max
    end

    def self.timePointToRatioDoneAtRest(timepoint)
        (TimePointsCore::timepointToTimeDoneInHoursAtRest(timepoint)).to_f/timepoint["commitment-in-hours"]
    end

    def self.timePointToRatioDoneUpToDate(timepoint)
        (TimePointsCore::timePointToTimeDoneInHoursUpToDate(timepoint)).to_f/timepoint["commitment-in-hours"]
    end

    def self.timePointToMetric(timepoint)
        0.2 + 0.4*CommonsUtils::realNumbersToZeroOne(timepoint["commitment-in-hours"], 1, 1) + 0.1*Math.exp(-TimePointsCore::timePointToRatioDoneAtRest(timepoint)*3) + CommonsUtils::traceToMetricShift(timepoint["uuid"])
    end

end