
# encoding: UTF-8

class Waves

    # --------------------------------------------------
    # IO

    # Waves::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/waves"
    end

    # Waves::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Waves::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Waves::items()
    def self.items()
        LucilleCore::locationsAtFolder(Waves::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
    end

    # Waves::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Waves::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Waves::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Waves::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Making

    # Waves::makeScheduleParametersInteractivelyOrNull() # [type, value]
    def self.makeScheduleParametersInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return ["sticky", fromHour]
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return [type, value]
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return [type, value]
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::waveToDoNotShowUnixtime(wave)
    def self.waveToDoNotShowUnixtime(wave)
        if wave["repeatType"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 86400) + wave["repeatValue"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + wave["repeatValue"].to_i*3600
        end
        if wave["repeatType"] == 'every-n-hours' then
            return Time.new.to_i+3600 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-n-days' then
            return Time.new.to_i+86400 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != wave["repeatValue"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if wave["repeatType"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != wave["repeatValue"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(wave)
    def self.scheduleString(wave)
        if wave["repeatType"] == 'sticky' then
            return "sticky, from: #{wave["repeatValue"]}"
        end
        "#{wave["repeatType"]}: #{wave["repeatValue"]}"
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_i

        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""

        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        repeatType   = schedule[0]
        repeatValue  = schedule[1]
        lastDoneDateTime = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        wave = {
          "uuid"             => uuid,
          "unixtime"         => unixtime,
          "description"      => description,
          "coreDataId"       => coreDataId,
          "repeatType"       => repeatType,
          "repeatValue"      => repeatValue,
          "lastDoneDateTime" => lastDoneDateTime,
          "domain"           => "(eva)"
        }
        Waves::commitItemToDisk(wave)
        wave
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::toString(wave)
    def self.toString(wave)
        ago = "#{((Time.new.to_i - DateTime.parse(wave["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] #{wave["description"]} (#{Waves::scheduleString(wave)}) (#{ago})"
    end

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::items().sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        Waves::commitItemToDisk(wave)

        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)

        Bank::put("WAVE-CIRCUIT-BREAKER-A-B8-4774-A416F", 1)
    end

    # Waves::main()
    def self.main()
        loop {
            puts "Waves 🌊 (main)"
            options = [
                "wave",
                "waves dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "wave" then
                Waves::issueNewWaveInteractivelyOrNull()
            end
            if option == "waves dive" then
                loop {
                    system("clear")
                    wave = Waves::selectWaveOrNull()
                    return if wave.nil?
                    Waves::landing(wave)
                }
            end
        }
    end

    # Waves::accessContent(wave)
    def self.accessContent(wave)
        CoreData::accessWithOptionToEdit(wave["coreDataId"])
    end

    # Waves::landing(wave)
    def self.landing(wave)
        uuid = wave["uuid"]

        nxball = NxBalls::makeNxBall([uuid])

        loop {
            system("clear")

            puts "#{Waves::toString(wave)}".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(wave["uuid"])}".green

            puts ""

            puts "uuid: #{wave["uuid"]}".yellow
            puts "schedule: #{Waves::scheduleString(wave)}".yellow
            puts "last done: #{wave["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(wave["uuid"])}".yellow

            puts ""

            puts "[item   ] access | done | <datecode> | note | [] | detach running | update description | update contents | recast schedule | >vector | destroy".yellow

            puts Interpreters::makersAndDiversCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "access" then
                Waves::accessContent(wave)
                next
            end

            if command == "done" then
                Waves::performDone(wave)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(wave["uuid"]) || "")
                StructuredTodoTexts::setNote(wave["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(wave["uuid"])
                next
            end

            if command == "detach running" then
                DetachedRunning::issueNew2(Waves::toString(wave), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("update description", command) then
                wave["description"] = Utils::editTextSynchronously(wave["description"])
                Waves::performDone(wave)
                next
            end

            if Interpreting::match("update contents", command) then
                puts "update contents against NxAxiom library has not been implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("recast schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                Waves::commitItemToDisk(wave)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    Waves::destroy(wave)
                    break
                end
            end

            Interpreters::makersAndDiversInterpreter(command)
        }

        NxBalls::closeNxBall(nxball, true)
    end

    # -------------------------------------------------------------------------
    # NS16

    # Waves::run(wave)
    def self.run(wave)
        system("clear")
        uuid = wave["uuid"]
        puts Waves::toString(wave)
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, "WAVES-TIME-75-42E8-85E2-F17E869DF4D3"])
        Waves::accessContent(wave)

        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "detach running; will done", "exit"])

        NxBalls::closeNxBall(nxball, true)

        if operation.nil? then
            operation = "done (default)"
        end

        if operation == "done (default)" then
            Waves::performDone(wave)
        end

        if operation == "detach running; will done" then
            Waves::performDone(wave)
            DetachedRunning::issueNew2(Waves::toString(wave), Time.new.to_i, [uuid])
        end

        if operation == "exit" then

        end
    end

    # Waves::toNS16(wave)
    def self.toNS16(wave)
        uuid = wave["uuid"]
        {
            "uuid"        => uuid,
            "announce"    => Waves::toString(wave),
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda{|command|
                if command == ".." then
                    Waves::run(wave)
                end
                if command == "landing" then
                    Waves::landing(wave)
                end
                if command == "done" then
                    Waves::performDone(wave)
                end
            },
            "run" => lambda {
                Waves::run(wave)
            },
            "wave" => wave,
        }
    end

    # Waves::waveOrderingPriority(wave)
    def self.waveOrderingPriority(wave)
        mapping = {
            "sticky"                      => 5,
            "every-this-day-of-the-month" => 4,
            "every-this-day-of-the-week"  => 3,
            "every-n-hours"               => 2,
            "every-n-days"                => 1
        }
        mapping[wave["repeatType"]]
    end

    # Waves::ns16ToOrderingWeight(ns16)
    def self.ns16ToOrderingWeight(ns16)
        Waves::waveOrderingPriority(ns16["wave"])
    end

    # Waves::isPriorityWave(wave)
    def self.isPriorityWave(wave)
        Waves::waveOrderingPriority(wave) >= 3
    end

    # Waves::compareNS16s(n1, n2)
    def self.compareNS16s(n1, n2)
        if Waves::ns16ToOrderingWeight(n1) < Waves::ns16ToOrderingWeight(n2) then
            return -1
        end
        if Waves::ns16ToOrderingWeight(n1) > Waves::ns16ToOrderingWeight(n2) then
            return 1
        end
        n1["uuid"] <=> n2["uuid"]
    end

    # Waves::ns16s(domain)
    def self.ns16s(domain)
        Waves::items()
            .select{|item| item["domain"] == domain }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::ns16ShouldShow(item["uuid"]) }
            .map{|wave| Waves::toNS16(wave) }
            .sort{|n1, n2| Waves::compareNS16s(n1, n2) }
            .reverse
    end

    # Waves::isCircuitBroken()
    def self.isCircuitBroken()
        return true if Bank::valueOverTimespan("WAVE-CIRCUIT-BREAKER-A-B8-4774-A416F", 3600) >= 10
        return true if Beatrice::stdRecoveredHourlyTimeInHours("WAVES-TIME-75-42E8-85E2-F17E869DF4D3") >= 0.25
        false
    end

    # Waves::ns16sWithCircuitBreaker(domain)
    def self.ns16sWithCircuitBreaker(domain)
        return [] if Waves::isCircuitBroken()
        Waves::items()
            .select{|item| item["domain"] == domain }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::ns16ShouldShow(item["uuid"]) }
            .map{|wave| Waves::toNS16(wave) }
            .sort{|n1, n2| Waves::compareNS16s(n1, n2) }
            .reverse
    end

    # Waves::nx19s()
    def self.nx19s()
        Waves::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Waves::toString(item),
                "lambda"   => lambda { Waves::landing(item) }
            }
        }
    end
end
