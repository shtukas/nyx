# encoding: UTF-8

class BackupsMonitor

    # BackupsMonitor::scriptnamesToPeriodInDays()
    def self.scriptnamesToPeriodInDays()
        {
            "Earth-to-Jupiter" => 20,
            "Saturn-to-Pluto" => 40
        }
    end

    # BackupsMonitor::scriptnames()
    def self.scriptnames()
        BackupsMonitor::scriptnamesToPeriodInDays().keys
    end

    def self.scriptNameToLastUnixtime(sname)
        filepath = "/Users/pascal/Galaxy/DataBank/Backups/Logs/#{sname}.log"
        IO.read(filepath).to_i
    end

    def self.scriptNameToNextOperationUnixtime(scriptname)
        BackupsMonitor::scriptNameToLastUnixtime(scriptname) + BackupsMonitor::scriptnamesToPeriodInDays()[scriptname]*86400
    end

    def self.scriptNameToIsDueFlag(scriptname)
        Time.new.to_i > BackupsMonitor::scriptNameToNextOperationUnixtime(scriptname)
    end

    def self.scriptNameToCatalystObjectOrNull(scriptname)
        return nil if !BackupsMonitor::scriptNameToIsDueFlag(scriptname)
        uuid = Digest::SHA1.hexdigest("60507ff5-adce-4444-9e57-c533efb01136:#{scriptname}")
        {
            "uuid"     => uuid,
            "body"     => "[Backups Monitor] /Galaxy/LucilleOS/Backups-SubSystem/#{scriptname}",
            "metric"   => 0.73,
            "landing"         => lambda {},
            "nextNaturalStep" => lambda {}
        }
    end

    # BackupsMonitor::catalystObjects()
    def self.catalystObjects()
        BackupsMonitor::scriptnames()
            .map{|scriptname|
                BackupsMonitor::scriptNameToCatalystObjectOrNull(scriptname)
            }
            .compact
    end
end
