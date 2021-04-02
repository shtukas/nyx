
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        TodoCoreData::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return nil if element.nil?
        quark = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"   => Time.new.to_i,
            "nereiduuid" => element["uuid"]
        }
        TodoCoreData::put(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{NereidInterface::toString(quark["nereiduuid"])}"
    end


    # Quarks::getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
    def self.getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
        quark = quarkOpt ? quarkOpt : Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        ordinal = Quarks::determineQuarkPlacingOrdinal()
        QuarksOrdinals::setQuarkOrdinal(quark, ordinal)
        Patricia::landing(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        NereidInterface::access(quark["nereiduuid"])
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if TodoCoreData::getOrNull(quark["uuid"]).nil?
            quark = TodoCoreData::getOrNull(quark["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            puts "ordinal: #{QuarksOrdinals::getQuarkOrdinalOrZero(quark)}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "recoveredDailyTimeInHours: #{BankExtended::recoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::access(quark) }
            )

            mx.item("set/update ordinal".yellow, lambda {
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ")
                return if ordinal == ""
                QuarksOrdinals::setQuarkOrdinal(quark, ordinal.to_f)
            })

            mx.item("edit".yellow, lambda {
                NereidInterface::edit(quark["nereiduuid"])
            })

            mx.item("transmute".yellow, lambda { 
                NereidInterface::transmuteOrNull(quark["nereiduuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy quark and content".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this quark and its content? ") then
                    Quarks::destroyQuarkAndNereidContent(quark)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Quarks::destroyQuark(quark)
    def self.destroyQuark(quark)
        TodoCoreData::destroy(quark)
    end

    # Quarks::destroyQuarkAndNereidContent(quark)
    def self.destroyQuarkAndNereidContent(quark)
        status = NereidInterface::destroyElement(quark["nereiduuid"])
        return if !status
        TodoCoreData::destroy(quark)
    end

    # Quarks::computeLowOrdinal()
    def self.computeLowOrdinal()
        ordinals = QuarksOrdinals::getOrdinals()
                    .sort
        if ordinals.empty? then
            return 1
        end
        ordinals = ordinals.take(20)
        t0 = DateTime.parse("2021-04-01T00:00:00").to_time.to_i
        shift = (Time.new.to_f - t0).to_f/(86400*365)
        ordinals.last + shift
    end

    # Quarks::determineQuarkPlacingOrdinal()
    def self.determineQuarkPlacingOrdinal()
        puts "Placement ordinal listing"
        command = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' #default, 'last'): ")
        if command == "low" or command == "" then
            return Quarks::computeLowOrdinal()
        end
        QuarksOrdinals::getNextOrdinal()
    end

    # Quarks::nx16s()
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
            "(ord: #{"%7.3f" % QuarksOrdinals::getQuarkOrdinalOrZero(quark)}, rt: #{"%5.3f" % BankExtended::recoveredDailyTimeInHours(quark["uuid"]).round(3)}) #{Patricia::toString(quark)}"
        }

        # Pool: Array[(quarkuuid, ratio)]

        makeNewPool = lambda {
            QuarksOrdinals::firstNVisibleQuarksInOrdinalOrder(10)
                .map
                .with_index {|quark, i| [quark["uuid"], (1.to_f/2) ** i] }
        }

        getStoredPoolOrNull = lambda {
            pool = KeyValueStore::getOrNull(nil, "d4fcf9c2-515d-4d59-8168-44f1a489d5d4")
            return nil if pool.nil?
            JSON.parse(pool)
        }

        sendPoolToDisk = lambda{|pool|
            KeyValueStore::set(nil, "d4fcf9c2-515d-4d59-8168-44f1a489d5d4", JSON.generate(pool))
        }

        liftPoolAtExpectation = lambda {|pool, expectation|
            pool
                .select{|pair| 
                    quarkuuid = pair[0]
                    TodoCoreData::getOrNull(quarkuuid)
                }
                .select{|pair| 
                    quarkuuid = pair[0]
                    ratio = pair[1]
                    BankExtended::recoveredDailyTimeInHours(quarkuuid) < (expectation * ratio)
                }
        }

        getPool = lambda {|expectation, counter|
            pool = getStoredPoolOrNull.call()
            if pool.nil? or pool.empty? then
                pool = makeNewPool.call()
                sendPoolToDisk.call(pool)
            end

            pool = liftPoolAtExpectation.call(pool, expectation)

            if !pool.empty? then
                [pool, counter]
            else
                [getPool.call(expectation + 0.5), counter]
            end
        }

        pool, counter = getPool.call(1, 0)
            
        pool
            .map{|pair| TodoCoreData::getOrNull(pair[0]) }
            .map{|quark|
                {
                    "uuid"     => quark["uuid"],
                    "announce" => "(#{counter}, #{"%5.3f" % BankExtended::recoveredDailyTimeInHours(quark["uuid"]).round(3)}) #{Quarks::toString(quark)}",
                    "commands" => "done (destroy quark and nereid element) | >nyx | landing",
                    "lambda"   => lambda{ Quarks::runQuark(quark) }
                }
            }
    end

    # Quarks::runQuark(quark)
    def self.runQuark(quark)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                CatalystUtils::onScreenNotification("Catalyst", "Quark running for more than an hour")
                sleep 60
            }
        }

        system("clear")

        if NereidInterface::getElementOrNull(quark["nereiduuid"]).nil? then
            # The quark is obviously alive but the corresponding nereid item is dead
            puts Quarks::toString(quark).green
            if LucilleCore::askQuestionAnswerAsBoolean("Should I delete this quark ? ") then
                Quarks::destroyQuarkAndNereidContent(quark)
            end
            return
        end

        puts "running: #{Quarks::toString(quark).green}"
        NereidInterface::accessTodoListingEdition(quark["nereiduuid"])

        context = {"quark" => quark}
        actions = [
            [">nyx", ">nyx", lambda{|context, command|
                quark = context["quark"]
                item = Patricia::getNyxNetworkNodeByUUIDOrNull(quark["nereiduuid"]) 
                return true if item.nil?
                Patricia::landing(item)
                Quarks::destroyQuark(quark)
            }],
            ["/", "/", lambda{|context, command|
                UIServices::servicesFront()
            }],
            ["landing", "landing", lambda{|context, command|
                quark = context["quark"]
                Quarks::landing(quark)
            }],
            ["++", "++ # Postpone quark by an hour", lambda{|context, command|
                quark = context["quark"]
                DoNotShowUntil::setUnixtime(quark["uuid"], Time.new.to_i+3600)
            }],
            ["+ *", "+ <datetime code> # Postpone quark", lambda{|context, command|
                _, input = Interpreting::tokenizer(command)
                unixtime = CatalystUtils::codeToUnixtimeOrNull(input)
                return true if unixtime.nil?
                quark = context["quark"]
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
            }],
            ["+ * *", "+ <float> <datecode unit> # Postpone top item", lambda{|context, command|
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = CatalystUtils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                quark = context["quark"]
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
            }],
            ["destroy", "destroy", lambda{|context, command|
                quark = context["quark"]
                NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                Quarks::destroyQuarkAndNereidContent(quark)
                QuarksHorizon::makeNewDataPoint()
            }],
            [";;", ";; # destroy", lambda{|context, command|
                quark = context["quark"]
                NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                Quarks::destroyQuarkAndNereidContent(quark)
                QuarksHorizon::makeNewDataPoint()
            }],
            ["", "(empty) # default # exit", lambda{|context, command|

            }]
        ]

        Interpreting::interpreter(context, actions, {
            "displayHelpInLineAtIntialization" => true
        })

        thr.exit

        puts "Time since start: #{Time.new.to_f - startUnixtime}"
        Quarks::incomingTime(quark, Time.new.to_f - startUnixtime)

        NereidInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"])
    end

    # Quarks::incomingTime(quark, timespan)
    def self.incomingTime(quark, timespan)
        timespan = [timespan, 3600*2].min
        puts "putting #{timespan} seconds to quark: #{Quarks::toString(quark)}"
        Bank::put(quark["uuid"], timespan)
    end
end
