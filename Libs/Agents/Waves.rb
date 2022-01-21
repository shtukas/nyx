
class Waves

    # --------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Waves")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Waves::commit(wave)
    def self.commit(wave)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Waves/#{Digest::SHA1.hexdigest(wave["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(wave)) }
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Waves/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
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

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        wave = {
            "uuid"        => SecureRandom.uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "atom"        => CoreData5::interactivelyCreateNewAtomOrNull(),
        }

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        wave["repeatType"]       = schedule[0]
        wave["repeatValue"]      = schedule[1]
        wave["lastDoneDateTime"] = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        Waves::commit(wave)
        wave
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::toString(wave)
    def self.toString(wave)
        lastDoneDateTime = wave["lastDoneDateTime"] || "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] #{wave["description"]} (#{Waves::scheduleString(wave)}) (#{ago})"
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        if Waves::toString(wave).include?("[backup]") then
            logfile = "/Users/pascal/Galaxy/LucilleOS/Backups-Utils/logs/main.txt"
            File.open(logfile, "a"){|f| f.puts("#{Time.new.to_s} : #{wave["description"]}")}
        end

        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        Waves::commit(wave)

        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
    end

    # Waves::accessContent(wave)
    def self.accessContent(wave)
        return if wave["atom"]["type"] == "description-only"
        updated = CoreData5::accessWithOptionToEdit(wave["atom"])
        if updated then
            wave["atom"] = updated
            Waves::commit(wave)
        end
    end

    # Waves::landing(wave)
    def self.landing(wave)
        uuid = wave["uuid"]

        NxBallsService::issue(uuid, Waves::toString(wave), [uuid, TwentyTwo::getCachedAccountForObject(Waves::toString(wave), wave["uuid"])])

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

            puts "[item   ] access | done | <datecode> | note | description | atom | recast schedule | destroy | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

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

            if Interpreting::match("description", command) then
                wave["description"] = Utils::editTextSynchronously(wave["description"])
                Waves::performDone(wave)
                next
            end

            if Interpreting::match("atom", command) then
                wave["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Waves::commit(wave)
                next
            end

            if Interpreting::match("recast schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                Waves::commit(wave)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    Waves::destroy(wave["uuid"])
                    break
                end
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # -------------------------------------------------------------------------
    # Waves

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::items().sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::waves()
    def self.waves()
        loop {
            system("clear")
            wave = Waves::selectWaveOrNull()
            return if wave.nil?
            Waves::landing(wave)
        }
    end

    # -------------------------------------------------------------------------
    # NS16

    # Waves::run(wave)
    def self.run(wave)
        system("clear")
        uuid = wave["uuid"]
        puts Waves::toString(wave)
        puts "Starting at #{Time.new.to_s}"

        NxBallsService::issue(uuid, wave["description"], [uuid, TwentyTwo::getCachedAccountForObject(Waves::toString(wave), wave["uuid"])])

        Waves::accessContent(wave)

        loop {
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "stop and exit", "exit and continue", "landing and back"])

            if operation.nil? or operation == "done (default)" then
                Waves::performDone(wave)
                NxBallsService::close(uuid, true)
                break
            end

            if operation == "stop and exit" then
                NxBallsService::close(uuid, true)
                break
            end

            if operation == "exit and continue" then
                break
            end

            if operation == "landing and back" then
                Waves::landing(wave)
            end
        }
    end

    # Waves::isPriorityWave(wave)
    def self.isPriorityWave(wave)
        return true if wave["repeatType"] == "sticky"
        return true if wave["repeatType"] == "every-this-day-of-the-month"
        return true if wave["repeatType"] == "every-this-day-of-the-week"
        false
    end

    # Waves::toNS16(wave)
    def self.toNS16(wave)
        uuid = wave["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "ns16:wave1",
            "announce" => Waves::toString(wave),
            "commands" => ["..", "landing", "done"],
            "wave"     => wave
        }
    end

    # Waves::ns16s()
    def self.ns16s()
        # We return the priority ones according to the `Waves::isPriorityWave` definition of priority
        # otherwise we manage the wave

        ns16s = Waves::items()
                    .select{|wave| Waves::isPriorityWave(wave) }
                    .select{|wave| DoNotShowUntil::isVisible(wave["uuid"]) }
                    .select{|wave| InternetStatus::ns16ShouldShow(wave["uuid"]) }
                    .map{|wave| Waves::toNS16(wave) }

        return ns16s if !ns16s.empty?

        Waves::items()
                    .select{|wave| DoNotShowUntil::isVisible(wave["uuid"]) }
                    .select{|wave| InternetStatus::ns16ShouldShow(wave["uuid"]) }
                    .map{|wave| Waves::toNS16(wave) }
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
