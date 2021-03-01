# encoding: UTF-8

class DxThreadsUIUtils

    # DxThreadsUIUtils::incomingTime(dxthread, quark, timespan)
    def self.incomingTime(dxthread, quark, timespan)
        timespan = [timespan, 3600*2].min
        puts "putting #{timespan} seconds to quark: #{Quarks::toString(quark)}"
        Bank::put(quark["uuid"], timespan)
        puts "putting #{timespan} seconds to dxthread: #{DxThreads::toString(dxthread)}"
        Bank::put(dxthread["uuid"], timespan)
    end

    # DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
    def self.runDxThreadQuarkPair(dxthread, quark)

        startUnixtime = Time.new.to_f
        pausedTimespanCumulated = 0

        thr = Thread.new {
            sleep 3600
            loop {
                CatalystUtils::onScreenNotification("Catalyst", "Item running for more than an hour")
                sleep 60
            }
        }

        system("clear")

        loop {

            if NereidInterface::getElementOrNull(quark["nereiduuid"]).nil? then
                # The quark is obviously alive but the corresponding nereid item is dead
                puts DxThreads::dxThreadAndQuarkToString(dxthread, quark).green
                if LucilleCore::askQuestionAnswerAsBoolean("Should I delete this quark ? ") then
                    Quarks::destroyQuarkAndNereidContent(quark)
                end
                break
            end

            puts "running: #{DxThreads::dxThreadAndQuarkToString(dxthread, quark).green}"
            NereidInterface::accessTodoListingEdition(quark["nereiduuid"])

            context = {"dxthread" => dxthread, "quark" => quark}
            actions = [
                [">nyx", ">nyx", lambda{|context, command|
                    quark = context["quark"]
                    item = Patricia::getNyxNetworkNodeByUUIDOrNull(quark["nereiduuid"]) 
                    return true if item.nil?
                    Patricia::landing(item)
                    Quarks::destroyQuark(quark)
                    "3:d9e2b6d5-exit-domain"
                }],
                [">dxthread", ">dxthread", lambda{|context, command|
                    quark = context["quark"]
                    dxthread = context["dxthread"]
                    DxThreads::moveTargetToNewDxThread(quark, dxthread)
                    "3:d9e2b6d5-exit-domain"
                }],
                ["/", "/", lambda{|context, command|
                    UIServices::servicesFront()
                    "2:565a0e56-reloop-domain"
                }],
                ["landing", "landing", lambda{|context, command|
                    quark = context["quark"]
                    Quarks::landing(quark)
                    "2:565a0e56-reloop-domain"
                }],
                ["++", "++ # Postpone quark by an hour", lambda{|context, command|
                    quark = context["quark"]
                    DoNotShowUntil::setUnixtime(quark["uuid"], Time.new.to_i+3600)
                    "3:d9e2b6d5-exit-domain"
                }],
                ["+ *", "+ <datetime code> # Postpone quark", lambda{|context, command|
                    _, input = Interpreting::tokenizer(command)
                    unixtime = CatalystUtils::codeToUnixtimeOrNull(input)
                    return true if unixtime.nil?
                    quark = context["quark"]
                    DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                    "3:d9e2b6d5-exit-domain"
                }],
                ["destroy", "destroy", lambda{|context, command|
                    quark = context["quark"]
                    NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                    Quarks::destroyQuarkAndNereidContent(quark)
                    "3:d9e2b6d5-exit-domain"
                }],
                [";;", ";; # destroy", lambda{|context, command|
                    quark = context["quark"]
                    NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                    Quarks::destroyQuarkAndNereidContent(quark)
                    "3:d9e2b6d5-exit-domain"
                }],
                ["keep alive", "keep alive", lambda{|context, command|
                    quark = context["quark"]
                    dxthread = context["dxthread"]
                    RunningItems::start(Quarks::toString(quark), [quark["uuid"], dxthread["uuid"]])
                    "3:d9e2b6d5-exit-domain"
                }],
                ["", "(empty) # default # exit", lambda{|context, command|
                    quark = context["quark"]
                    dxthread = context["dxthread"]
                    RunningItems::start(Quarks::toString(quark), [quark["uuid"], dxthread["uuid"]])
                    "3:d9e2b6d5-exit-domain"
                }]
            ]
            exitcode = Interpreting::interpreter(context, actions, {
                "displayHelpInLineAtIntialization" => true
            })

            if exitcode == "3:d9e2b6d5-exit-domain" then
                break
            end
        }

        thr.exit

        puts "Time since start: #{Time.new.to_f - startUnixtime}"
        puts "Cumulated pause time: #{pausedTimespanCumulated}"
        DxThreadsUIUtils::incomingTime(dxthread, quark, (Time.new.to_f - startUnixtime) - pausedTimespanCumulated)

        NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"])
    end

    # DxThreadsUIUtils::dxThreadToDisplayGroupComponentsOrNull(dxthread)
    def self.dxThreadToDisplayGroupComponentsOrNull(dxthread)
        return nil if (Time.new.hour >= 22)
        return nil if DxThreads::completionRatioOrNull(dxthread).nil?
        return nil if DxThreads::completionRatioBreakdownOrNull(dxthread)["completionRatio"] >= 1.5

        dxThreadCompletionRatioX = lambda{|dxthread|
            completionRatio = (DxThreads::completionRatioOrNull(dxthread) || 0)
            if dxthread["uuid"] == "d0c8857574a1e570a27f6f6b879acc83" then # Guardian Work
                completionRatio = completionRatio*completionRatio
            end
            completionRatio
        }

        sizeOfManagedPool = lambda{|dxthread|
            if dxthread["uuid"] == "791884c9cf34fcec8c2755e6cc30dac4" then # Stream
                return 5
            end
            return 3
        }

        quarkRecoveredTimeX = lambda{|quark|
            rt = BankExtended::recoveredDailyTimeInHours(quark["uuid"])
            (rt == 0) ? 0.4 : rt
            # The logic here is that is an element has never been touched, we put it at 0.4
            # So that it doesn't take priority on stuff that we have in progresss
            # If all the stuff that we have in progress have a high enough recovery time, then we work on 
            # the new stuff (which from that moment takes a non zero rt)
        }

        toString = lambda {|dxthread, quark|
            "#{DxThreads::toString(dxthread)} (#{"%8.3f" % DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark)}, #{"%5.2f" % quarkRecoveredTimeX.call(quark)}) #{Patricia::toString(quark)}"
        }

        ns16s = DxThreadQuarkMapping::dxThreadToFirstNVisibleQuarksInOrdinalOrder(dxthread, sizeOfManagedPool.call(dxthread))
            .sort{|q1, q2| quarkRecoveredTimeX.call(q1) <=> quarkRecoveredTimeX.call(q2) }
            .map{|quark|
                {
                    "uuid"     => quark["uuid"],
                    "display"  => "⛵️ #{DxThreads::toStringWithAnalytics(dxthread).yellow}".yellow,
                    "announce" => toString.call(dxthread, quark),
                    "commands" => "done (destroy quark and nereid element) | >nyx | >dxthread | landing",
                    "lambda"   => lambda{ DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark) }
                }
            }
        [dxThreadCompletionRatioX.call(dxthread), ns16s]
    end

    # DxThreadsUIUtils::displayGroups()
    def self.displayGroups()

        dg31s = DxThreads::dxthreads()
                .select{|dxthread| Runner::isRunning?(dxthread["uuid"])}
                .map{|dxthread|
                    {
                        "uuid"             => dxthread["uuid"],
                        "completionRatio"  => 0,
                        "DisplayItemsNS16" => [
                            {
                                "uuid"        => dxthread["uuid"],
                                "announce"    => "running: #{DxThreads::toStringWithAnalytics(dxthread)}".green,
                                "lambda"      => lambda {
                                    thr = Thread.new {
                                        sleep 3600
                                        loop {
                                            Miscellaneous::onScreenNotification("Catalyst", "Item running for more than an hour")
                                            sleep 60
                                        }
                                    }
                                    if LucilleCore::askQuestionAnswerAsBoolean("We are running. Stop ? : ", true) then
                                        timespan = Runner::stop(dxthread["uuid"])
                                        timespan = [timespan, 3600*2].min
                                        puts "Adding #{timespan} seconds to #{DxThreads::toStringWithAnalytics(dxthread)}"
                                        Bank::put(dxthread["uuid"], timespan)
                                    end
                                    thr.exit
                                }
                            }
                        ]
                    } 
                }

        dg32s = DxThreads::dxthreads()
                .map{|dxthread|
                    elements = DxThreadsUIUtils::dxThreadToDisplayGroupComponentsOrNull(dxthread)
                    if elements then
                        completionRatio, ns16 = elements
                        {
                            "uuid"             => dxthread["uuid"],
                            "completionRatio"  => completionRatio,
                            "DisplayItemsNS16" => ns16
                        } 
                    else
                        nil
                    end
                }
                .compact

        dg31s + dg32s
    end

    # DxThreadsUIUtils::neodiff() # positive = good
    def self.neodiff()
        cardinal1 = 3765
        cardinal2 = 100
        t1 = DateTime.parse("2021-02-22T00:20:48Z").to_time.to_i
        t2 = DateTime.parse("2021-08-22T00:20:48Z").to_time.to_i
        slope = (cardinal2-cardinal1).to_f/(t2-t1)
        ideal = (Time.new.to_i-t1) * slope + cardinal1
        ideal - DxThreadQuarkMapping::getQuarkUUIDsForDxThreadInOrder(TodoCoreData::getOrNull("791884c9cf34fcec8c2755e6cc30dac4")).size
    end

    # DxThreadsUIUtils::neo()
    def self.neo()
        dxthread = TodoCoreData::getOrNull("791884c9cf34fcec8c2755e6cc30dac4") # Stream
        t1 = Time.new.to_f
        DxThreadQuarkMapping::dxThreadToFirstNVisibleQuarksInOrdinalOrder(dxthread, 100)
            .shuffle
            .each{|quark|
                DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
                break if DxThreadsUIUtils::neodiff() >= 0
                break if (Time.new.to_i - t1) > 1200
            }
        true
    end

end

class DxThreads

    # DxThreads::dxthreads()
    def self.dxthreads()
        TodoCoreData::getSet("2ed4c63e-56df-4247-8f20-e8d220958226")
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
        TodoCoreData::put(object)
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

    # DxThreads::toStringWithAnalytics(dxthread)
    def self.toStringWithAnalytics(dxthread)
        ratio = (DxThreads::completionRatioOrNull(dxthread) || 0)
        "[DxThread] [#{"%4.2f" % dxthread["timeCommitmentPerDayInHours"]} hours, #{"%6.2f" % (100*ratio)} % completed] #{dxthread["description"]}"
    end

    # DxThreads::dxThreadAndQuarkToString(dxthread, quark)
    def self.dxThreadAndQuarkToString(dxthread, quark)
        "#{DxThreads::toString(dxthread)} (#{"%8.3f" % DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark)}) #{Patricia::toString(quark)}"
    end

    # DxThreads::completionRatioBreakdownOrNull(dxthread)
    def self.completionRatioBreakdownOrNull(dxthread)

        recoveredDailyTimeInHours = BankExtended::recoveredDailyTimeInHours(dxthread["uuid"])

        activeDaysOverThePastWeek = lambda{|dxthread|
            week = (-6..0).map{|i| CatalystUtils::nDaysInTheFuture(i)} 
            if dxthread["uuid"] == "d0c8857574a1e570a27f6f6b879acc83" then # Guardian Work
                week = week.reject{|day| CatalystUtils::dateIsWeekEnd(day) }
            end

            week - (dxthread["noTimeCountOnTheseDays"] || [])
        }

        activeDays = activeDaysOverThePastWeek.call(dxthread)
        return nil if activeDays.empty?
        correctionFactor = activeDays.size.to_f/7
        timeCommitmentPerDayInHoursCorrected = dxthread["timeCommitmentPerDayInHours"] * correctionFactor
        completionRatio = recoveredDailyTimeInHours.to_f/timeCommitmentPerDayInHoursCorrected
        
        {
            "recoveredDailyTimeInHours"            => recoveredDailyTimeInHours,
            "timeCommitmentPerDayInHours"          => dxthread["timeCommitmentPerDayInHours"],
            "activeDaysOverThePastWeek"            => activeDays,
            "correctionFactor"                     => correctionFactor,
            "timeCommitmentPerDayInHoursCorrected" => timeCommitmentPerDayInHoursCorrected,
            "completionRatio"                      => completionRatio
        }
    end

    # DxThreads::completionRatioOrNull(dxthread)
    def self.completionRatioOrNull(dxthread)
        completionRatio = DxThreads::completionRatioBreakdownOrNull(dxthread)
        return nil if completionRatio.nil?
        completionRatio["completionRatio"]
    end

    # DxThreads::determinePlacingOrdinalForThread(dxthread)
    def self.determinePlacingOrdinalForThread(dxthread)
        puts "Placement ordinal listing"
        quarks = DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, 30)
        quarks.each{|quark|
            puts "[#{"%8.3f" % DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark)}] #{Patricia::toString(quark)}"
        }
        ordinal = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' for 21st, empty for last): ")
        if ordinal == "" then
            return DxThreadQuarkMapping::getNextOrdinal()
        end
        if ordinal == "low" then
            return DxThreads::computeNew21stOrdinalForDxThread(dxthread)
        end
        ordinal.to_f
    end

    # DxThreads::computeNew21stOrdinalForDxThread(dxthread)
    def self.computeNew21stOrdinalForDxThread(dxthread)
        ordinals = DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, 22)
                    .map{|quark| DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark) }
                    .sort
        ordinals = ordinals.drop(19).take(2)
        if ordinals.size < 2 then
            return DxThreadQuarkMapping::getNextOrdinal()
        end
        (ordinals[0]+ordinals[1]).to_f/2
    end

    # DxThreads::moveTargetToNewDxThread(quark, dxParentOpt or null)
    def self.moveTargetToNewDxThread(quark, dxParentOpt)
        dx2 = DxThreads::selectOneExistingDxThreadOrNull()
        return if dx2.nil?
        DxThreadQuarkMapping::deleteRecordsByQuarkUUID(quark["uuid"])
        ordinal = DxThreads::determinePlacingOrdinalForThread(dx2)
        DxThreadQuarkMapping::insertRecord(dx2, quark, ordinal)
    end

    # DxThreads::selectOneExistingDxThreadOrNull()
    def self.selectOneExistingDxThreadOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("DxThread", DxThreads::dxthreads(), lambda{|o| DxThreads::toString(o) })
    end

    # DxThreads::landing(dxthread)
    def self.landing(dxthread)
        loop {
            system("clear")

            return if TodoCoreData::getOrNull(dxthread["uuid"]).nil?

            puts DxThreads::toString(dxthread).green
            puts "uuid: #{dxthread["uuid"]}".yellow
            puts "time commitment per day in hours: #{dxthread["timeCommitmentPerDayInHours"]}".yellow
            puts "no display on these days: #{(dxthread["noTimeCountOnTheseDays"] || []).sort.join(", ")}".yellow
            puts "completion ratio breakdown: #{DxThreads::completionRatioBreakdownOrNull(dxthread)}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""

            DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, CatalystUtils::screenHeight()-25)
                .each{|quark|
                    mx.item("[quark] [#{"%8.3f" % DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark)}] #{Patricia::toString(quark)}", lambda { 
                        Patricia::landing(quark) 
                    })
                }

            puts ""

            mx.item("no display on this day".yellow, lambda { 
                dxthread["noTimeCountOnTheseDays"] = ((dxthread["noTimeCountOnTheseDays"] || []) + [CatalystUtils::today()]).uniq.sort
                TodoCoreData::put(dxthread)
            })

            mx.item("rename".yellow, lambda { 
                name1 = CatalystUtils::editTextSynchronously(dxthread["name"]).strip
                return if name1 == ""
                dxthread["name"] = name1
                TodoCoreData::put(dxthread)
            })

            mx.item("update daily time commitment".yellow, lambda { 
                time = LucilleCore::askQuestionAnswerAsString("daily time commitment in hour: ").to_f
                dxthread["timeCommitmentPerDayInHours"] = time
                TodoCoreData::put(dxthread)
            })

            mx.item("start thread".yellow, lambda { 
                RunningItems::start(DxThreads::toString(dxthread), [dxthread["uuid"]])
                puts "Started"
                LucilleCore::pressEnterToContinue()
            })

            mx.item("add time".yellow, lambda { 
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ")
                return if timeInHours == ""
                Bank::put(dxthread["uuid"], timeInHours.to_f*3600)
            })

            mx.item("add new quark".yellow, lambda {
                Quarks::getQuarkPossiblyArchitectedOrNull(nil, dxthread)
            })

            mx.item("select and move quark".yellow, lambda { 
                quarks = DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, 20)
                quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", quarks, lambda { |quark| Patricia::toString(quark) })
                return if quark.nil?
                DxThreads::moveTargetToNewDxThread(quark, dxthread)
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
                    TodoCoreData::destroy(dxthread)
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

            DxThreads::dxthreads()
                .sort{|dx1, dx2| dx1["description"] <=> dx2["description"] }
                .each{|dxthread|
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
end

