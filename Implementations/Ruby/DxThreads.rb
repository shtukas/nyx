# encoding: UTF-8

class DxThreads

    # DxThreads::focusDoingDepth()
    def self.focusDoingDepth()
        10
    end

    # DxThreads::visualisationDepth()
    def self.visualisationDepth()
        30
    end

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

    # DxThreads::dxThreadAndTargetToString(dxthread, quark)
    def self.dxThreadAndTargetToString(dxthread, quark)
        uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
        runningString = 
            if Runner::isRunning?(uuid) then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "#{DxThreads::toString(dxthread)} (#{"%6.3f" % BankExtended::recoveredDailyTimeInHours(quark["uuid"])}) #{Patricia::toString(quark)}#{runningString}"
    end

    # DxThreads::toStringWithAnalytics(dxthread)
    def self.toStringWithAnalytics(dxthread)
        ratio = DxThreads::completionRatio(dxthread)
        "[DxThread] [#{"%4.2f" % dxthread["timeCommitmentPerDayInHours"]} hours, #{"%6.2f" % (100*ratio)} % completed] #{dxthread["description"]}"
    end

    # DxThreads::completionRatio(dxthread)
    def self.completionRatio(dxthread)
        BankExtended::recoveredDailyTimeInHours(dxthread["uuid"]).to_f/dxthread["timeCommitmentPerDayInHours"]
    end

    # DxThreads::determinePlacingOrdinalForThread(dxthread)
    def self.determinePlacingOrdinalForThread(dxthread)
        puts "Placement ordinal listing"
        quarks = Arrows::getTargetsForSource(dxthread)
                    .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                    .first(DxThreads::visualisationDepth())
        quarks.each{|quark|
            puts "[#{"%8.3f" % Ordinals::getObjectOrdinal(quark)}] #{Patricia::toString(quark)}"
        }
        ordinal = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' for 21st, empty for last): ")
        if ordinal == "" then
            return Ordinals::computeNextOrdinal()
        end
        if ordinal == "low" then
            return Patricia::computeNew21stOrdinalForDxThread(dxthread)
        end
        ordinal.to_f
    end

    # DxThreads::selectOneExistingDxThreadOrNull()
    def self.selectOneExistingDxThreadOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("DxThread", DxThreads::dxthreads(), lambda{|o| DxThreads::toString(o) })
    end

    # DxThreads::landing(dxthread, showAllTargets)
    def self.landing(dxthread, showAllTargets = false)
        loop {
            system("clear")

            return if NSCoreObjects::getOrNull(dxthread["uuid"]).nil?

            puts DxThreads::toString(dxthread).green
            puts "uuid: #{dxthread["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""

            quarks = Arrows::getTargetsForSource(dxthread)

            quarks
                .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                .first(showAllTargets ? quarks.size : DxThreads::visualisationDepth())
                .each{|quark|
                    mx.item("[quark] [#{"%8.3f" % Ordinals::getObjectOrdinal(quark)}] #{Patricia::toString(quark)}", lambda { 
                        Patricia::landing(quark) 
                    })
                }

            puts ""

            mx.item("relanding on all quarks".yellow, lambda { 
                DxThreads::landing(dxthread, true)
            })

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

            mx.item("add new quark".yellow, lambda {
                Patricia::possiblyNewQuarkToPossiblyUnspecifiedDxThread(nil, dxthread)
            })

            mx.item("select and move quark".yellow, lambda { 
                quarks = Arrows::getTargetsForSource(dxthread)
                            .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                            .first(DxThreads::visualisationDepth())
                quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", quarks, lambda { |quark| Patricia::toString(quark) })
                return if quark.nil?
                Patricia::moveTargetToNewDxThread(quark, dxthread)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(dxthread)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("flush focus uuids".yellow, lambda { 
                KeyValueStore::destroy(nil, "3199a49f-3d71-4a02-83b2-d01473664473:#{dxthread["uuid"]}")
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

            DxThreads::dxthreads().each{|dxthread|
                ms.item(DxThreads::toStringWithAnalytics(dxthread), lambda { 
                    DxThreads::landing(dxthread)
                })
            }

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

    # DxThreads::receiveTime(dxthread, quark, timespanInSeconds)
    def self.receiveTime(dxthread, quark, timespanInSeconds)
        puts "sending #{timespanInSeconds} to thread item '#{Patricia::toString(quark)}'"
        Bank::put(quark["uuid"], timespanInSeconds)
        puts "sending #{timespanInSeconds} to DxThread'#{DxThreads::toString(dxthread)}'"
        Bank::put(dxthread["uuid"], timespanInSeconds)
    end

    # DxThreads::nextNaturalStepWhenStopped(dxthread, quark)
    def self.nextNaturalStepWhenStopped(dxthread, quark)
        uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
        return if Runner::isRunning?(uuid)
        puts "starting DxThread item: #{DxThreads::dxThreadAndTargetToString(dxthread, quark)}"
        Runner::start(uuid)
        Patricia::open1(quark)
        menuitems = LCoreMenuItemsNX1.new()
        menuitems.item("keep running".yellow, lambda {})
        menuitems.item("stop".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
        })
        menuitems.item("stop ; hide for n days".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
            DoNotShowUntil::setUnixtime(uuid, Time.new.to_i + n*86400)
        })
        menuitems.item("quark landing".yellow, lambda { 
            Patricia::landing(quark)
        })
        menuitems.item("stop ; move quark".yellow, lambda { 
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            Patricia::moveTargetToNewDxThread(quark, dxthread)
        })
        menuitems.item("stop ; destroy quark".yellow,lambda {
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            Patricia::destroy(quark)
        })
        status = menuitems.promptAndRunSandbox()
    end

    # DxThreads::nextNaturalStepWhileRunning(dxthread, quark)
    def self.nextNaturalStepWhileRunning(dxthread, quark)
        uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
        return if !Runner::isRunning?(uuid)
        menuitems = LCoreMenuItemsNX1.new()
        menuitems.item("".yellow, lambda {})
        menuitems.item("stop".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
        })
        menuitems.item("stop ; hide for n days".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
            DoNotShowUntil::setUnixtime(uuid, Time.new.to_i + n*86400)
        })
        menuitems.item("quark landing".yellow, lambda { 
            Patricia::landing(quark)
        })
        menuitems.item("stop ; move quark".yellow, lambda {
            uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            Patricia::moveTargetToNewDxThread(quark, dxthread)
        })
        menuitems.item("stop ; destroy quark".yellow, lambda {
            timespan = Runner::stop(uuid)
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            DxThreads::receiveTime(dxthread, quark, timespan)
            Patricia::destroy(quark)
        })
        status = menuitems.promptAndRunSandbox()
    end

    # DxThreads::nextNaturalStep(dxthread, quark)
    def self.nextNaturalStep(dxthread, quark)
        # The thing to start is the combined uuid, but the time will be given separately to the thread and the item
        uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
        if Runner::isRunning?(uuid) then
            DxThreads::nextNaturalStepWhileRunning(dxthread, quark)
        else
            DxThreads::nextNaturalStepWhenStopped(dxthread, quark)
        end
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
        DxThreads::getTheFocusDoingUUIDsForDxThread(dxthread)
            .map{|uuid| NSCoreObjects::getOrNull(uuid) }
            .compact
            .sort{|t1, t2| BankExtended::recoveredDailyTimeInHours(t1["uuid"]) <=> BankExtended::recoveredDailyTimeInHours(t2["uuid"]) }
            .map{|quark|
                uuid = "#{dxthread["uuid"]}-#{quark["uuid"]}"
                metric = basemetric - BankExtended::recoveredDailyTimeInHours(quark["uuid"]).to_f/1000
                metric = 1 if Runner::isRunning?(uuid)
                {
                    "uuid"             => uuid,
                    "body"             => DxThreads::dxThreadAndTargetToString(dxthread, quark),
                    "metric"           => metric,
                    "landing"          => lambda { Patricia::landing(quark) },
                    "nextNaturalStep"  => lambda { DxThreads::nextNaturalStep(dxthread, quark) },
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

    # --------------------------------------------------------------

    # DxThreads::recomputeFocusUUIDsForDxThread(dxthread)
    def self.recomputeFocusUUIDsForDxThread(dxthread)
        Arrows::getTargetsForSource(dxthread)
            .select{|quark| DoNotShowUntil::isVisible("#{dxthread["uuid"]}-#{quark["uuid"]}") } # we need to use the uuid of the catalyst object
            .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
            .first(DxThreads::focusDoingDepth())
            .map{|t| t["uuid"] }
    end

    # DxThreads::getTheFocusDoingUUIDsForDxThread(dxthread)
    def self.getTheFocusDoingUUIDsForDxThread(dxthread)
        # Getting what is stored
        uuids = (KeyValueStore::getOrNull(nil, "3199a49f-3d71-4a02-83b2-d01473664473:#{dxthread["uuid"]}") || "").split("|")

        # Selecting what is still alive                   
        uuids = uuids.select{|uuid| NSCoreObjects::getOrNull(uuid) }

        # Selecting what is visible
        uuids = uuids.select{|uuid| DoNotShowUntil::isVisible("#{dxthread["uuid"]}-#{uuid}") } # we need to use the uuid of the catalyst object

        b1 = uuids.size < DxThreads::focusDoingDepth().to_f/2
        b2 = (uuids.size == 0) or (uuids.map{|uuid| BankExtended::recoveredDailyTimeInHours(uuid) }.inject(0, :+) >= 2)

        if b1 and b2 then
            puts "recomputing TheFocusDoingUUIDs for DxThread: #{DxThreads::toString(dxthread)}"
            # Recomputing uuids
            uuids = DxThreads::recomputeFocusUUIDsForDxThread(dxthread)
            KeyValueStore::set(nil, "3199a49f-3d71-4a02-83b2-d01473664473:#{dxthread["uuid"]}", uuids.join("|"))
        end

        uuids
    end
end

