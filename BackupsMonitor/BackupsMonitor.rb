
# encoding: UTF-8
require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

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
            "uuid"         => uuid,
            "application"  => "BackupsMonitor",
            "body"         => "[Backups Monitor] /Galaxy/LucilleOS/Backups-SubSystem/#{scriptname}",
            "metric"       => 0.50,
            "commands"     => []
        }
    end

    # BackupsMonitor::getCatalystObjects()
    def self.getCatalystObjects()
        BackupsMonitor::scriptnames()
            .map{|scriptname|
                BackupsMonitor::scriptNameToCatalystObjectOrNull(scriptname)
            }
            .compact
    end
end
