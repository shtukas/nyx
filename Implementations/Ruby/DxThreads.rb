# encoding: UTF-8

class DxThreads

    # DxThreads::dxthreads()
    def self.dxthreads()
        NSCoreObjects::getSet("2ed4c63e-56df-4247-8f20-e8d220958226")
    end

    # DxThreads::getStream()
    def self.getStream()
        NSCoreObjects::getOrNull("791884c9cf34fcec8c2755e6cc30dac4")
    end

    # DxThreads::make(description, timeCommitmentPerDayInHours)
    def self.make(description, timeCommitmentPerDayInHours)
        {
            "uuid"        => SecureRandom.hex,
            "nyxNxSet"    => "2ed4c63e-56df-4247-8f20-e8d220958226",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "timeCommitmentPerDayInHours" => timeCommitmentPerDayInHours,
        }
    end

    # DxThreads::issue(description, timeCommitmentPerDayInHours)
    def self.issue(description, timeCommitmentPerDayInHours)
        object = DxThreads::make(description, timeCommitmentPerDayInHours)
        NSCoreObjects::put(object)
        object
    end

    # DxThreads::issueDxThreadInteractivelyOrNull()
    def self.issueDxThreadInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        timeCommitmentPerDayInHours = LucilleCore::askQuestionAnswerAsString("timeCommitmentPerDayInHours: ")
        return nil if timeCommitmentPerDayInHours == ""
        timeCommitmentPerDayInHours = timeCommitmentPerDayInHours.to_f
        return nil if timeCommitmentPerDayInHours == 0
        DxThreads::issue(description, timeCommitmentPerDayInHours)
    end

    # DxThreads::toString(object)
    def self.toString(object)
        "[DxThread] #{object["description"]}"
    end

    # DxThreads::completionRatio(dxthread)
    def self.completionRatio(dxthread)
        BankExtended::recoveredDailyTimeInHours(dxthread["uuid"]).to_f/dxthread["timeCommitmentPerDayInHours"]
    end

    # DxThreads::selectOneExistingDxThreadOrNull()
    def self.selectOneExistingDxThreadOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("DxThread", DxThreads::dxthreads(), lambda{|o| DxThreads::toString(o) })
    end

    # DxThreads::landing(dxthread)
    def self.landing(dxthread)
        loop {
            system("clear")

            return if NSCoreObjects::getOrNull(dxthread["uuid"]).nil?

            puts DxThreads::toString(dxthread).green
            puts "uuid: #{dxthread["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""

            Patricia::mxSourcing(dxthread, mx)

            puts ""

            Patricia::mxTargetting(dxthread, mx)

            puts ""

            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(dxthread["name"]).strip
                return if name1 == ""
                dxthread["name"] = name1
                NSCoreObjects::put(dxthread)
            })

            mx.item("update daily time commitment in hours".yellow, lambda { 
                time = LucilleCore::askQuestionAnswerAsString("daily time commitment in hour: ").to_f
                dxthread["timeCommitmentPerDayInHours"] = time
                NSCoreObjects::put(dxthread)
            })

            mx.item("start thread".yellow, lambda { 
                Runner::start(dxthread["uuid"])
            })

            mx.item("add time".yellow, lambda { 
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ")
                return if timeInHours == ""
                Bank::put(dxthread["uuid"], timeInHours.to_f*3600)
            })

            mx.item("add new target".yellow, lambda { 
                o1 = Patricia::makeNewObjectOrNull()
                return if o1.nil?
                Arrows::issueOrException(dxthread, o1)
            })

            mx.item("remove target".yellow, lambda { 
                targets = Arrows::getTargetsForSource(dxthread)
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda { |target| Patricia::toString(target) })
                return if target.nil?
                Arrows::unlink(dxthread, target)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(dxthread)
                LucilleCore::pressEnterToContinue()
            })
            
            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("DxThread: '#{DxThreads::toString(dxthread)}': ") then
                    NSCoreObjects::destroy(dxthread)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # DxThreads::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("DxThreads dive", lambda { 
                loop {
                    object = DxThreads::selectOneExistingDxThreadOrNull()
                    return if object.nil?
                    DxThreads::landing(object)
                }
            })

            ms.item("make new DxThread", lambda { 
                object = DxThreads::issueDxThreadInteractivelyOrNull()
                return if object.nil?
                DxThreads::landing(object)
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # --------------------------------------------------------------

    # DxThreads::receiveTime(dxthread, target, timespanInSeconds)
    def self.receiveTime(dxthread, target, timespanInSeconds)
        puts "sending #{timespanInSeconds} to thread item '#{Patricia::toString(target)}'"
        Bank::put(target["uuid"], timespanInSeconds)
        puts "sending #{timespanInSeconds} to DxThread'#{DxThreads::toString(dxthread)}'"
        Bank::put(dxthread["uuid"], timespanInSeconds)
    end

    # DxThreads::nextNaturalStepWhenStopped(dxthread, target)
    def self.nextNaturalStepWhenStopped(dxthread, target)
        uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
        return if Runner::isRunning?(uuid)
        puts "starting DxThread item: #{DxThreads::dxThreadAndTargetToString(dxthread, target)}"
        Runner::start(uuid)
        Patricia::open1(target)
        menuitems = LCoreMenuItemsNX1.new()
        menuitems.item("keep running".yellow, lambda {})
        menuitems.item("stop".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
        })
        menuitems.item("stop ; hide for n days".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
            DoNotShowUntil::setUnixtime(uuid, Time.new.to_i + n*86400)
        })
        menuitems.item("target landing".yellow, lambda { 
            Patricia::landing(target)
        })
        menuitems.item("stop ; move target".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            puts "The move per se (away from threading or to another DxThread is not yet implemented)"
            LucilleCore::pressEnterToContinue()
        })
        menuitems.item("stop ; destroy target".yellow,lambda {
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            Patricia::destroy(target)
        })
        status = menuitems.promptAndRunSandbox()
    end

    # DxThreads::nextNaturalStepWhileRunning(dxthread, target)
    def self.nextNaturalStepWhileRunning(dxthread, target)
        uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
        return if !Runner::isRunning?(uuid)
        menuitems = LCoreMenuItemsNX1.new()
        menuitems.item("".yellow, lambda {})
        menuitems.item("stop".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
        })
        menuitems.item("stop ; hide for n days".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
            DoNotShowUntil::setUnixtime(uuid, Time.new.to_i + n*86400)
        })
        menuitems.item("target landing".yellow, lambda { 
            Patricia::landing(target)
        })
        menuitems.item("stop ; move target".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            puts "The move per se (away from threading or to another DxThread is not yet implemented)"
            LucilleCore::pressEnterToContinue()
        })
        menuitems.item("stop ; destroy target".yellow, lambda {
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, target, timespan)
            Patricia::destroy(target)
        })
        status = menuitems.promptAndRunSandbox()
    end

    # DxThreads::nextNaturalStep(dxthread, target)
    def self.nextNaturalStep(dxthread, target)
        # The thing to start is the combined uuid, but the time will be given separately to the thread and the item
        uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
        if Runner::isRunning?(uuid) then
            DxThreads::nextNaturalStepWhileRunning(dxthread, target)
        else
            DxThreads::nextNaturalStepWhenStopped(dxthread, target)
        end
    end

    # DxThreads::dxThreadAndTargetToString(dxthread, target)
    def self.dxThreadAndTargetToString(dxthread, target)
        uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
        runningString = 
            if Runner::isRunning?(uuid) then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "#{DxThreads::toString(dxthread)} #{Patricia::toString(target)}#{runningString}"
    end

    # DxThreads::dxThreadBaseMetric(dxthread)
    def self.dxThreadBaseMetric(dxthread)
        ratio = DxThreads::completionRatio(dxthread)
        if ratio <= 1 then
            0.6 - 0.2*ratio # from 0.6 to 0.4 as ratio from 0 to 1
        else
            0.4 - 0.2*(1 - Math.exp(-(ratio-1))) # from 0.4 to 0.2 as ration from 1 t infinity
        end
    end

    # DxThreads::dxThreadCatalystObjectOrNull(dxthread)
    def self.dxThreadCatalystObjectOrNull(dxthread)
        uuid = dxthread["uuid"]
        return nil if !Runner::isRunning?(uuid)
        {
            "uuid"             => uuid,
            "body"             => DxThreads::toString(dxthread)+Runner::runTimeAsString(uuid, " "),
            "metric"           => 1,
            "landing"          => lambda {
                DxThreads::landing(dxthread)
            },
            "nextNaturalStep"  => lambda {
                timespan = Runner::stop(uuid)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                puts "sending #{timespan} to DxThread'#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespan)
            },
            "isRunning"        => Runner::isRunning?(uuid),
            "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
        }
    end

    # DxThreads::dxThreadChildrenCatalystObjects(dxthread)
    def self.dxThreadChildrenCatalystObjects(dxthread)
        basemetric = DxThreads::dxThreadBaseMetric(dxthread)
        (KeyValueStore::getOrNull(nil, "3199a49f-3d71-4a02-83b2-d01473664473:#{dxthread["uuid"]}") || "")
            .split("|")
            .map{|uuid| NSCoreObjects::getOrNull(uuid) }
            .map{|target|
                uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
                metric = basemetric - BankExtended::recoveredDailyTimeInHours(target["uuid"]).to_f/1000
                metric = 1 if Runner::isRunning?(uuid)
                {
                    "uuid"             => uuid,
                    "body"             => DxThreads::dxThreadAndTargetToString(dxthread, target),
                    "metric"           => metric,
                    "landing"          => lambda { Patricia::landing(target) },
                    "nextNaturalStep"  => lambda { DxThreads::nextNaturalStep(dxthread, target) },
                    "isRunning"        => Runner::isRunning?(uuid),
                    "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
                }
            }
    end

    # DxThreads::catalystObjectsForDxThread(dxthread)
    def self.catalystObjectsForDxThread(dxthread)
        (DxThreads::dxThreadChildrenCatalystObjects(dxthread) + [DxThreads::dxThreadCatalystObjectOrNull(dxthread)]).compact
    end

    # DxThreads::catalystObjects()
    def self.catalystObjects()
        topThread = DxThreads::dxthreads()
            .select{|dx| DxThreads::completionRatio(dx) < 1 }
            .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
            .first

        DxThreads::catalystObjectsForDxThread(topThread || DxThreads::getStream())
    end

    # DxThreads::toStringWithAnalytics(dxthread)
    def self.toStringWithAnalytics(dxthread)
        ratio = DxThreads::completionRatio(dxthread)
        "[DxThread] [#{"%4.2f" % dxthread["timeCommitmentPerDayInHours"]} hours, #{"%6.2f" % (100*ratio)} % completed] #{dxthread["description"]}"
    end
end

Thread.new {
    sleep 120
    loop {
        DxThreads::dxthreads()
            .each{|dxthread|
                targets = Arrows::getTargetsForSource(dxthread)
                    .sort{|t1,t2| Ordinals::getOrdinalForUUID(t1["uuid"]) <=> Ordinals::getOrdinalForUUID(t2["uuid"]) }
                    .first(10)
                KeyValueStore::set(nil, "3199a49f-3d71-4a02-83b2-d01473664473:#{dxthread["uuid"]}", targets.map{|t| t["uuid"] }.join("|"))
            }
        sleep 1200
    }
}

