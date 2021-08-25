
# encoding: UTF-8

class Waves

    # Waves::databaseItemToWave(item)
    def self.databaseItemToWave(item)
        item["contentType"]      = item["payload1"]
        item["contentPayload"]   = item["payload2"]
        item["repeatType"]       = item["payload3"]
        item["repeatValue"]      = item["payload4"]
        item["lastDoneDateTime"] = item["payload5"]
        item
    end

    # Waves::commitWaveToDisk(wave)
    def self.commitWaveToDisk(wave)
        uuid         = wave["uuid"]
        unixtime     = wave["unixtime"]
        description  = wave["description"]
        catalystType = "wave"
        payload1     = wave["contentType"]
        payload2     = wave["contentPayload"]
        payload3     = wave["repeatType"]
        payload4     = wave["repeatValue"]
        payload5     = wave["lastDoneDateTime"]
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Waves::waves()
    def self.waves()
        CatalystDatabase::getItemsByCatalystType("wave").map{|item|
            Waves::databaseItemToWave(item)
        }
    end

    # ------------------------------------------

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

    # Waves::interactivelyMakeContentsOrNull() : [type, payload] 
    def self.interactivelyMakeContentsOrNull()
        types = ['line', 'url']
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("types", types)
        return nil if type.nil?
        if type == "line" then
            line  = LucilleCore::askQuestionAnswerAsString("line (empty to abort) : ")
            return nil if line == ""
            return ["line", line]
        end
        if type == "url" then
            url  = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
            return nil if url == ""
            return ["url", url]
        end
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        contents = Waves::interactivelyMakeContentsOrNull()
        return nil if contents.nil?

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_i
        
        catalystType = "wave"

        if contents[0] == "line" then
            description  = contents[1]
            payload1     = nil
            payload2     = nil
        end

        if contents[0] == "url" then
            description  = contents[1]
            payload1     = "url"
            payload2     = contents[1]
        end

        payload3     = schedule[0]
        payload4     = schedule[1]
        payload5     = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # -------------------------------------------------------------------------

    # Waves::toString(wave)
    def self.toString(wave)
        ago = "#{((Time.new.to_i - DateTime.parse(wave["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] #{wave["description"]} (#{Waves::scheduleString(wave)}) (#{ago})"
    end

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::waves().sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        Waves::commitWaveToDisk(wave)

        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
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
        if wave["contentType"] == "line" then

        end
        if wave["contentType"] == "url" then
            Utils::openUrlUsingSafari(wave["contentPayload"])
        end
    end

    # Waves::landing(wave)
    def self.landing(wave)
        uuid = wave["uuid"]

        nxball = NxBalls::makeNxBall([uuid, "WAVES-A81E-4726-9F17-B71CAD66D793"])

        loop {
            system("clear")

            puts "#{Waves::toString(wave)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(wave["uuid"])}".green

            puts ""

            puts "uuid: #{wave["uuid"]}".yellow
            puts "schedule: #{Waves::scheduleString(wave)}".yellow
            puts "last done: #{wave["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(wave["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | done | <datecode> | detach running | exit | update description | recast contents | recast schedule | destroy".yellow

            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if Interpreting::match("update description", command) then
                wave["description"] = Utils::editTextSynchronously(wave["description"])
                Waves::performDone(wave)
                next
            end

            if Interpreting::match("recast contents", command) then
                contents = Waves::interactivelyMakeContentsOrNull()
                next if contents.nil?
                if contents[0] == "line" then
                    wave["description"]  = contents[1]
                    wave["contentType"]    = nil
                    wave["contentPayload"] = nil
                end
                if contents[0] == "url" then
                    wave["description"] = contents[1]
                    wave["contentType"]    = contents[0]
                    wave["contentPayload"] = contents[1]
                end
                Waves::commitWaveToDisk(wave)
                next
            end

            if Interpreting::match("recast schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                Waves::commitWaveToDisk(wave)
                next
            end

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("done", command) then
                Waves::performDone(wave)
                break
            end

            if command == "access" then
                Waves::accessContent(wave)
                next
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

            if command == "done" then
                Waves::performDone(wave)
                break
            end

            if command == "detach running" then
                DetachedRunning::issueNew2(Waves::toString(wave), Time.new.to_f, [uuid, "WAVES-A81E-4726-9F17-B71CAD66D793"])
                Waves::performDone(wave)
                break
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    CatalystDatabase::delete(wave["uuid"])
                    break
                end
            end

            Interpreters::mainMenuInterpreter(command)
        }
        
        NxBalls::closeNxBall(nxball, true)
    end

    # -------------------------------------------------------------------------

    # Waves::run(wave)
    def self.run(wave)
        puts Waves::toString(wave)
        uuid = wave["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "WAVES-A81E-4726-9F17-B71CAD66D793"])
        Waves::accessContent(wave)
        LucilleCore::pressEnterToContinue()
        Waves::performDone(wave)
        NxBalls::closeNxBall(nxball, true)
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

    # Waves::ns16s()
    def self.ns16s()
        Waves::waves()
            .map{|wave| Waves::toNS16(wave) }
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Waves::nx19s()
    def self.nx19s()
        Waves::waves().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Waves::toString(item),
                "lambda"   => lambda { Waves::landing(item) }
            }
        }
    end
end
