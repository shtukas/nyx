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

    # DxThreadsUIUtils::nx16s()
    def self.nx16s()
        quarkRecoveredTimeX = lambda{|quark|
            rt = BankExtended::recoveredDailyTimeInHours(quark["uuid"])
            (rt == 0) ? 0.4 : rt
            # The logic here is that is an element has never been touched, we put it at 0.4
            # So that it doesn't take priority on stuff that we have in progresss
            # If all the stuff that we have in progress have a high enough recovery time, then we work on 
            # the new stuff (which from that moment takes a non zero rt)
        }

        toString = lambda {|quark|
            "[#{QuarksOrdinals::getQuarkOrdinalOrZero(quark)}] (#{"%5.2f" % quarkRecoveredTimeX.call(quark)}) #{Patricia::toString(quark)}"
        }

        QuarksOrdinals::dxThreadToFirstNVisibleQuarksInOrdinalOrder(3)
            .sort{|q1, q2| quarkRecoveredTimeX.call(q1) <=> quarkRecoveredTimeX.call(q2) }
            .map{|quark|
                {
                    "uuid"     => quark["uuid"],
                    "announce" => toString.call(quark),
                    "commands" => "done (destroy quark and nereid element) | >nyx | >dxthread | landing",
                    "lambda"   => lambda{ DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark) }
                }
            }
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

    # DxThreads::dxThreadAndQuarkToString(dxthread, quark)
    def self.dxThreadAndQuarkToString(dxthread, quark)
        "#{DxThreads::toString(dxthread)} #{Patricia::toString(quark)}"
    end

    # DxThreads::determineQuarkPlacingOrdinal()
    def self.determineQuarkPlacingOrdinal()
        puts "Placement ordinal listing"
        command = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' for 21st, empty for last): ")
        if command == "low" then
            return DxThreads::computeNew21stQuarkOrdinal()
        end
        QuarksOrdinals::getNextOrdinal()
    end

    # DxThreads::computeNew21stQuarkOrdinal()
    def self.computeNew21stQuarkOrdinal()
        ordinals = QuarksOrdinals::getOrdinals()
                    .sort
        ordinals = ordinals.drop(19).take(2)
        if ordinals.size < 2 then
            return QuarksOrdinals::getNextOrdinal()
        end
        (ordinals[0]+ordinals[1]).to_f/2
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
            puts "time commitment per day in hours @ speed of light #{(dxthread["timeCommitmentPerDayInHours"]*SpeedOfLight::getSpeedRatio())}".yellow
            puts "no display on these days: #{(dxthread["noTimeCountOnTheseDays"] || []).sort.join(", ")}".yellow
            puts "completion ratio breakdown: #{DxThreads::completionRatioBreakdownOrNull(dxthread)}".yellow

            mx = LCoreMenuItemsNX1.new()

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

