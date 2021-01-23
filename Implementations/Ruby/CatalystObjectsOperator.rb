
# encoding: UTF-8

# -- CatalystObjectsOperator ----------------------------------------------------------

class CatalystObjectsOperator

    # CatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects(),
        ]
        .flatten
        .compact
        .select{|object| DoNotShowUntil::isVisible(object["uuid"]) }
    end

    # CatalystObjectsOperator::generationSpeedReport()
    def self.generationSpeedReport()
        generators = [
            {
                "name" => "BackupsMonitor",
                "exec" => lambda { BackupsMonitor::catalystObjects() }
            },
            {
                "name" => "Calendar",
                "exec" => lambda { Calendar::catalystObjects() }
            },
            {
                "name" => "VideoStream",
                "exec" => lambda { VideoStream::catalystObjects() }
            },
            {
                "name" => "Waves",
                "exec" => lambda { Waves::catalystObjects() }
            }
        ]

        generators = generators
                        .map{|item|
                            time1 = Time.new.to_f
                            item["exec"].call()
                            item["runtime"] = Time.new.to_f - time1
                            item
                        }
        generators = generators.sort{|item1, item2| item1["runtime"] <=> item2["runtime"] }.reverse
        generators.each{|item|
            puts "#{item["name"].ljust(20)} : #{item["runtime"].round(2)}"
        }
        LucilleCore::pressEnterToContinue()
    end
end
