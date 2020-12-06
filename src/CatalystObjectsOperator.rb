
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

# -- NG12TimeReports ----------------------------------------------------------

=begin

NG12TimeReport {
    "description"                     : Float
    "dailyTimeExpectationInHours"     : Float
    "currentExpectationRealisedRatio" : Float
    "landing"                         : Lambda
}

=end

class NG12TimeReports

    # NG12TimeReports::reports()
    def self.reports()

        objects1 = [ 
            {
                "description"                     => "waves, asteroids: execution-context-fbc-837c-88a007b3cad0-837, video stream and curation",
                "dailyTimeExpectationInHours"     => 2,
                "currentExpectationRealisedRatio" => ExecutionContexts::contextRealisationRatio("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", 2),
                "landing"                         => lambda {
                    loop {
                        options = [
                            "asteroids: execution-context-fbc-837c-88a007b3cad0-837",
                            "VideoStream",
                            "curation"
                        ]
                        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
                        break if option.nil?
                        if option == "asteroids: execution-context-fbc-837c-88a007b3cad0-837" then
                            Asteroids::diveAsteroidOrbitalType("asteroids: execution-context-fbc-837c-88a007b3cad0-837")
                        end
                        if option == "VideoStream" then
                            objects = VideoStream::catalystObjects()
                            object = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", objects, lambda{|o| o["body"] })
                            if object then
                                object["landing"].call()
                            end
                        end
                        if option == "curation" then
                            Curation::runOnce()
                        end
                    }
                }
            },
            {
                "description"                     => "All asteroid burners",
                "dailyTimeExpectationInHours"     => 1,
                "currentExpectationRealisedRatio" => ExecutionContexts::contextRealisationRatio("ExecutionContext-47C73AE6-D40B-4099-B79C-3373E5070204", 1),
                "landing"                         => lambda {
                    Asteroids::diveAsteroidOrbitalType("burner-5d333e86-230d-4fab-aaee-a5548ec4b955")
                }
            },
            {
                "description"                     => "All asteroid streams",
                "dailyTimeExpectationInHours"     => 1,
                "currentExpectationRealisedRatio" => ExecutionContexts::contextRealisationRatio("ExecutionContext-2943891F-27BC-4C82-B29E-4254389A86BC", 1),
                "landing"                         => lambda {
                    puts "There currently is no particular implementation for ExecutionContext-2943891F-27BC-4C82-B29E-4254389A86BC"
                    LucilleCore::pressEnterToContinue()
                }
            },
        ]

        objects2 = Asteroids::asteroidsDailyTimeCommitments()
                        .map{|asteroid|
                            {
                                "description"                     => Asteroids::toString(asteroid),
                                "dailyTimeExpectationInHours"     => asteroid["orbital"]["time-commitment-in-hours"],
                                "currentExpectationRealisedRatio" => ExecutionContexts::contextRealisationRatio(asteroid["uuid"], asteroid["orbital"]["time-commitment-in-hours"]),
                                "landing"                         => lambda { Asteroids::landing(asteroid) }
                            }
                        }

        objects1 + objects2
    end

end


# -- CatalystObjectsOperator ----------------------------------------------------------

class CatalystObjectsOperator

    # CatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = [
            Asteroids::catalystObjects(),
            BackupsMonitor::catalystObjects(),
            Calendar::catalystObjects(),
            Curation::catalystObjects(),
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
                "name" => "Asteroids",
                "exec" => lambda{ Asteroids::catalystObjects() }
            },
            {
                "name" => "BackupsMonitor",
                "exec" => lambda{ BackupsMonitor::catalystObjects() }
            },
            {
                "name" => "Calendar",
                "exec" => lambda{ Calendar::catalystObjects() }
            },
            {
                "name" => "Curation",
                "exec" => lambda{ Curation::catalystObjects() }
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
