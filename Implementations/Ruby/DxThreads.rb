
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

    # DxThreads::catalystObjectsForDxThread(dxthread)
    def self.catalystObjectsForDxThread(dxthread)
        indexing = -1
        TargetOrdinals::getTargetsForSourceInOrdinalOrder(dxthread).map{|target|
            indexing = indexing + 1
            uuid = "#{dxthread["uuid"]}-#{target["uuid"]}"
            {
                "uuid"             => uuid,
                "body"             => "#{DxThreads::toString(dxthread).ljust(35)} #{Patricia::toString(target)}",
                "metric"           => 0.9 - indexing.to_f/1000,
                "landing"          => lambda {
                    Patricia::landing(target)
                },
                "nextNaturalStep"  => lambda {
                    puts "not implemented yet"
                },
                "isRunning"        => false,
                "isRunningForLong" => false
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
