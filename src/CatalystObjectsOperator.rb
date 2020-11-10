
# encoding: UTF-8

# specialOrder = Array[uuid: String]

class SpecialUIListingOrder

    # SpecialUIListingOrder::getCurrentSpecialOrder()
    def self.getCurrentSpecialOrder()
        uuids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "8c4c13d9-d398-4834-96fd-a2e05705ad35:#{Miscellaneous::today()}", "[]"))
    end

    # SpecialUIListingOrder::setSpecialOrder(specialOrder)
    def self.setSpecialOrder(specialOrder)
        KeyValueStore::set(nil, "8c4c13d9-d398-4834-96fd-a2e05705ad35:#{Miscellaneous::today()}", JSON.generate(specialOrder))
    end

    # SpecialUIListingOrder::applySpecialOrderCore(specialOrder, objects)
    def self.applySpecialOrderCore(specialOrder, objects)
        objects2 = specialOrder.map{|uuid| objects.select{|o| o["uuid"] == uuid }.first }.compact
        objects3 = objects.select{|o| objects2.none?{|o2| o2["uuid"] == o["uuid"] } }
        objects4 = objects2 + objects3
        specialOrder = objects4.map{|o| o["uuid"] }
        SpecialUIListingOrder::setSpecialOrder(specialOrder)
        objects4
    end

    # SpecialUIListingOrder::applySpecialOrder(objects)
    def self.applySpecialOrder(objects)
        above1Objects, below1Objects = objects.partition {|object| object["metric"] >= 1 }
        above06Objects, below06Objects = below1Objects.partition {|object| object["metric"] >= 0.6 }
        above1Objects + SpecialUIListingOrder::applySpecialOrderCore(SpecialUIListingOrder::getCurrentSpecialOrder(), above06Objects) + below06Objects
    end
end

class CatalystObjectsOperator

    # CatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            Asteroids::catalystObjects(),
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects(),
        ].flatten.compact
        objects = objects
                    .select{|object| object['metric'] >= 0.2 }

        objects = objects
                    .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse

        # SpecialUIListingOrder::applySpecialOrder(objects)

        objects
    end

    # CatalystObjectsOperator::generationSpeedReport()
    def self.generationSpeedReport()
        generators = [
            {
                "name" => "BackupsMonitor",
                "exec" => lambda{ BackupsMonitor::catalystObjects() }
            },
            {
                "name" => "Calendar",
                "exec" => lambda{ Calendar::catalystObjects() }
            },
            {
                "name" => "Asteroids",
                "exec" => lambda{ Asteroids::catalystObjects() }
            },
            {
                "name" => "VideoStream",
                "exec" => lambda{ VideoStream::catalystObjects() }
            },
            {
                "name" => "Waves",
                "exec" => lambda{ Waves::catalystObjects() }
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
