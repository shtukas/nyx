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

    # BackupsMonitor::displayItemsNS16()
    def self.displayItemsNS16()
        BackupsMonitor::scriptnames()
            .select{|scriptname|
                BackupsMonitor::scriptNameToIsDueFlag(scriptname)
            }
            .map{|scriptname|
                {
                    "uuid"      => "78827442-f558-4bb4-9cb2-7b3c3803c188:#{scriptname}",
                    "announce"  => "[Backups Monitor] /Galaxy/LucilleOS/Backups-SubSystem/#{scriptname}",
                    "lambda"    => lambda {}
                }
            }
    end
end
