
# encoding: UTF-8

# -- SingleExecutionContext ----------------------------------------------------------


class ExecutionContexts

    # ExecutionContexts::contextRealisationRatio(contextId, dailyExpectationInHours)
    def self.contextRealisationRatio(contextId, dailyExpectationInHours)
        recovered = BankExtended::recoveredDailyTimeInHours(contextId)
        recovered.to_f/dailyExpectationInHours
    end

    # ExecutionContexts::metric2(contextId, dailyExpectationInHours, itemBankAccountId)
    def self.metric2(contextId, dailyExpectationInHours, itemBankAccountId)
        recovered = BankExtended::recoveredDailyTimeInHours(contextId)
        ratio = recovered.to_f/dailyExpectationInHours
        if ratio < 1 then
            0.6 - 0.2*ratio - 0.001*BankExtended::recoveredDailyTimeInHours(itemBankAccountId)
        else
            0.3 - 0.1*(1-Math.exp(-(ratio-1)))
        end
    end
end

# -- CatalystObjectsOperator ----------------------------------------------------------

class CatalystObjectsOperator

    # CatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            Curation::catalystObjects(),
            DxThreads::catalystObjects(),
            VideoStream::catalystObjects(),
            Waves::catalystObjects(),
        ].flatten.compact
        objects = objects
                    .select{|object| object['metric'] >= 0.2 }

        objects = objects
                    .select{|object| DoNotShowUntil::isVisible(object["uuid"]) or object["isRunning"] }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
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
                "name" => "Curation",
                "exec" => lambda { Curation::catalystObjects() }
            },
            {
                "name" => "VideoStream",
                "exec" => lambda { VideoStream::catalystObjects() }
            },
            {
                "name" => "Waves",
                "exec" => lambda { Waves::catalystObjects() }
            },
            {
                "name" => "DxThreads",
                "exec" => lambda { DxThreads::catalystObjects() }
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
