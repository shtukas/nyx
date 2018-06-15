
# encoding: UTF-8

# TimePointsCore::issueNewPoint(domain, description, hours, isGuardian)

class TimePointsCore
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
        AgentTimePoints::saveTimePoint(item)
    end
end