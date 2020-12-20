
# encoding: UTF-8

class DxThreads

    # DxThreads::objects()
    def self.objects()
        NyxObjects2::getSet("2ed4c63e-56df-4247-8f20-e8d220958226")
    end

    # DxThreads::make(description, timeCommitmentPerDayInHours)
    def self.make(description, timeCommitmentPerDayInHours)
        {
            "uuid"        => SecureRandom.hex,
            "nyxNxSet"    => "2ed4c63e-56df-4247-8f20-e8d220958226",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "timeCommitmentPerDayInHours" => timeCommitmentPerDayInHours
        }
    end

    # DxThreads::issue(description, timeCommitmentPerDayInHours)
    def self.issue(description, timeCommitmentPerDayInHours)
        object = DxThreads::make(description, timeCommitmentPerDayInHours)
        NyxObjects2::put(object)
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

    # DxThreads::selectOneExistingNodeOrNull()
    def self.selectOneExistingNodeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("DxThread", DxThreads::objects(), lambda{|o| DxThreads::toString(o) })
    end

    # DxThreads::landing(object)
    def self.landing(object)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(object["uuid"]).nil?

            puts DxThreads::toString(object).green
            puts "uuid: #{object["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""

            Patricia::mxSourcing(object, mx)

            puts ""

            Patricia::mxTargetting(object, mx)

            puts ""

            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(object["name"]).strip
                return if name1 == ""
                object["name"] = name1
                NyxObjects2::put(object)
            })

            Patricia::mxParentsManagement(object, mx)

            Patricia::mxMoveToNewParent(object, mx)

            Patricia::mxTargetsManagement(object, mx)

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
            })
            
            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("DxThread: '#{DxThreads::toString(object)}': ") then
                    NyxObjects2::destroy(object)
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
                    object = DxThreads::selectOneExistingNodeOrNull()
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

    # DxThreads::nextNaturalStepStart(dxthread, target)
    def self.nextNaturalStepStart(dxthread, target)
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

    # DxThreads::nextNaturalStepStop(dxthread, target)
    def self.nextNaturalStepStop(dxthread, target)
        uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
        return if !Runner::isRunning?(uuid)
        puts "stopping DxThread item: #{DxThreads::dxThreadAndTargetToString(dxthread, target)}"
        timespan = Runner::stop(uuid)
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        DxThreads::receiveTime(dxthread, target, timespan)
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
            DxThreads::nextNaturalStepStop(dxthread, target)
        else
            DxThreads::nextNaturalStepStart(dxthread, target)
        end
    end

    # DxThreads::dxThreadAndTargetToString(dxthread, target)
    def self.dxThreadAndTargetToString(dxthread, target)
        "#{DxThreads::toString(dxthread).ljust(35)} #{Patricia::toString(target)}"
    end

    # DxThreads::dxThreadBaseMetric(dxthread)
    def self.dxThreadBaseMetric(dxthread)
        ratio = BankExtended::recoveredDailyTimeInHours(dxthread["uuid"]).to_f/dxthread["timeCommitmentPerDayInHours"]
        if ratio <= 1 then
            0.6 - 0.2*ratio # from 0.6 to 0.4 as ratio from 0 to 1
        else
            0.4 - 0.2*(1 - Math.exp(-(ratio-1))) # from 0.4 to 0.2 as ration from 1 t infinity
        end
        
    end

    # DxThreads::catalystObjectsForDxThread(dxthread)
    def self.catalystObjectsForDxThread(dxthread)
        indexing = -1
        basemetric = DxThreads::dxThreadBaseMetric(dxthread)
        TargetOrdinals::getTargetsForSourceInOrdinalOrder(dxthread)
        .first(1)
        .map{|target|
            indexing = indexing + 1
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            {
                "uuid"             => uuid,
                "body"             => DxThreads::dxThreadAndTargetToString(dxthread, target),
                "metric"           => basemetric - indexing.to_f/1000,
                "landing"          => lambda { Patricia::landing(target) },
                "nextNaturalStep"  => lambda { DxThreads::nextNaturalStep(dxthread, target) },
                "isRunning"        => Runner::isRunning?(uuid),
                "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
            }
        }
    end

    # DxThreads::catalystObjects()
    def self.catalystObjects()
        DxThreads::objects().map{|dxthread|
            DxThreads::catalystObjectsForDxThread(dxthread)
        }
        .flatten
    end
    
end
