# encoding: UTF-8

class BackupsMonitor

    # BackupsMonitor::scriptnames()
    def self.scriptnames()
        [ # Here we assume that they are all in the Backups-SubSystem folder
            "EnergyGrid-to-Venus",
            "Earth-to-Jupiter",
            "Saturn-to-Pluto"
        ]
    end

    # BackupsMonitor::scriptnamesToPeriodInDays()
    def self.scriptnamesToPeriodInDays()
        {
            "EnergyGrid-to-Venus" => 7,
            "Earth-to-Jupiter" => 20,
            "Saturn-to-Pluto" => 40
        }
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
            "execute"  => lambda {|command|}
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
