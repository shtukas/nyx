
# encoding: UTF-8

# -- CatalystObjectsOperator ----------------------------------------------------------

class Ordinals

    # Ordinals::setOrdinal(uuid, ordinal)
    def self.setOrdinal(uuid, ordinal)
        KeyValueStore::set(nil, "830472db-49fc-4638-94eb-0c9412907162:#{Miscellaneous::today()}:#{uuid}", ordinal)
    end

    # Ordinals::unset(uuid)
    def self.unset(uuid)
        KeyValueStore::destroy(nil, "830472db-49fc-4638-94eb-0c9412907162:#{Miscellaneous::today()}:#{uuid}")
    end

    # Ordinals::getOrdinalOrNull(uuid)
    def self.getOrdinalOrNull(uuid)
       value = KeyValueStore::getOrNull(nil, "830472db-49fc-4638-94eb-0c9412907162:#{Miscellaneous::today()}:#{uuid}")
       return nil if value.nil?
       value.to_f
    end
end

class CatalystObjectsOperator

    # CatalystObjectsOperator::computeMetric(ordinal, metric)
    def self.computeMetric(ordinal, metric)
        if ordinal then
            return 1 + Math.exp(-ordinal.to_f)
        end
        metric
    end 

    # CatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            DxThreads::catalystObjects(),
            Floats::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects(),
        ].flatten.compact
        objects = objects
                    .select{|object| object['metric'] >= 0.2 }

        objects = objects.map{|object|
            uuid = object["uuid"]
            ordinal = Ordinals::getOrdinalOrNull(uuid)
            object["::ordinal"] = ordinal
            object["metric"] = CatalystObjectsOperator::computeMetric(ordinal, object["metric"])
            object
        }

        objects = objects
                    .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
                    .sort{|o1, o2| o1["metric"] <=> o2["metric"] }
                    .reverse

        objects
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
                "name" => "DxThreads",
                "exec" => lambda { DxThreads::catalystObjects() }
            },
            {
                "name" => "Floats",
                "exec" => lambda { Floats::catalystObjects() }
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
