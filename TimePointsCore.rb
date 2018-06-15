
# encoding: UTF-8

# TimePointsCore::getTimePoints()
# TimePointsCore::getTimePointByUUID(uuid)
# TimePointsCore::saveTimePoint(timepoint)
# TimePointsCore::startTimePoint(timepoint)
# TimePointsCore::stopTimePoint(timepoint)
# TimePointsCore::destroyTimePoint(timepoint)
# TimePointsCore::timepointToLiveTimespan(timepoint)
# TimePointsCore::garbageCollectionItems(timepoints)
# TimePointsCore::garbageCollectionGlobal()
# TimePointsCore::getUniqueDomains(timepoints)
# TimePointsCore::issueNewPoint(domain, description, hours, isGuardian)

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
    end

    def self.startTimePoint(timepoint)
        return timepoint if timepoint["is-running"]
        timepoint["is-running"] = true
        timepoint["last-start-unixtime"] = Time.new.to_i
        timepoint
    end

    def self.stopTimePoint(timepoint)
        if timepoint["is-running"] then
            timepoint["is-running"] = false
            timespanInSeconds = Time.new.to_i - timepoint["last-start-unixtime"]
            timepoint["timespans"] << timespanInSeconds
            if timepoint["0e69d463:GuardianSupport"] then
                TimePointsCore::issueNewPoint("6596d75b-a2e0-4577-b537-a2d31b156e74", "Guardian", -timespanInSeconds.to_f/3600, false)
            end
        end
        timepoint
    end

    def self.destroyTimePoint(timepoint)
        self.stopTimePoint(timepoint)
        SetsOperator::delete(CATALYST_COMMON_TIMEPOINTS_ITEMS_REPOSITORY_PATH, CATALYST_COMMON_TIMEPOINTS_ITEMS_SETUUID, timepoint["uuid"])
    end

    def self.timepointToLiveTimespan(timepoint)
        timepoint["timespans"].inject(0,:+) + ( timepoint["is-running"] ? Time.new.to_i - timepoint["last-start-unixtime"] : 0 )
    end

    def self.garbageCollectionItems(timepoints)
        return if timepoints.size < 2 
        return if timepoints.any?{|timepoint| timepoint["is-running"] }
        timepoint1 = timepoints[0]
        timepoint2 = timepoints[1]
        TimePointsCore::issueNewPoint(
            timepoint1["domain"], 
            timepoint1["description"], 
            (timepoint1["commitment-in-hours"]+timepoint2["commitment-in-hours"]) - (timepoint1["timespans"]+timepoint2["timespans"]).inject(0, :+).to_f/3600, 
            timepoint1["0e69d463:GuardianSupport"] || timepoint2["0e69d463:GuardianSupport"]
        )
        TimePointsCore::destroyTimePoint(timepoint1)
        TimePointsCore::destroyTimePoint(timepoint2)
    end

    def self.garbageCollectionGlobal()
        timepoints = TimePointsCore::getTimePoints()
        domains = TimePointsCore::getUniqueDomains(timepoints)
        domains.each{|domain|
            domainItems = timepoints.select{|timepoint| timepoint["domain"]==domain }
            TimePointsCore::garbageCollectionItems(domainItems)
        }
    end

    def self.getUniqueDomains(timepoints)
        timepoints.map{|timepoint| timepoint["domain"] }.uniq
    end

    def self.issueNewPoint(domain, description, hours, isGuardianSupport)
        item = {
            "uuid"                => SecureRandom.hex(4),
            "creation-unixtime"   => Time.new.to_i,
            "domain"              => domain,
            "description"         => description,
            "commitment-in-hours" => hours,
            "timespans"           => [],
            "last-start-unixtime" => 0,
            "0e69d463:GuardianSupport" => isGuardianSupport
        }
        TimePointsCore::saveTimePoint(item)
    end
end