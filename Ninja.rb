#!/usr/bin/ruby

# encoding: UTF-8

# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"

class Ninja
    # Ninja::getCatalystObjects()
    def self.getCatalystObjects()
        objects = []
        pendingcount = `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:pendingcount`.to_i
        dayactivitycount = `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:last-24-hours-activity-count`.to_i
        metric = pendingcount==0 ? 0 : 0.2 + 0.1*Math.exp(-dayactivitycount.to_f/20)
            # The second term raise the metric from 0 to 1 as the pending count increases
            # The third term collapse from 1 to 0 as the last-24-hours-activity-count raises
        objects << {
            "uuid" => "44a372b9-32d4-4fb7-884d-efba45616961",
            "metric" => metric,
            "announce" => "           (#{"%.3f" % metric}) ninja play",
            "commands" => [],
            "default-commands" => ['play'],
            "command-interpreter" => lambda{|object, command|  
                system('ninja play')
            }
        } 
        objects
    end
end
