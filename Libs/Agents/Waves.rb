
class Waves

    # --------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Wave")
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
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

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        Librarian6Objects::commit(atom)

        wave = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Wave",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "atomuuid"    => atom["uuid"],
        }

        wave["repeatType"]       = schedule[0]
        wave["repeatValue"]      = schedule[1]
        wave["lastDoneDateTime"] = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        Librarian6Objects::commit(wave)
        wave
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::toString(wave)
    def self.toString(wave)
        lastDoneDateTime = wave["lastDoneDateTime"] || "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] #{wave["description"]}#{AgentsUtils::atomTypeForToStrings(" ", wave["atomuuid"])} (#{Waves::scheduleString(wave)}) (#{ago})"
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        if Waves::toString(wave).include?("[backup]") then
            logfile = "/Users/pascal/Galaxy/LucilleOS/Backups-Utils/logs/main.txt"
            File.open(logfile, "a"){|f| f.puts("#{Time.new.to_s} : #{wave["description"]}")}
        end

        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        Librarian6Objects::commit(wave)

        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
    end

    # Waves::landing(wave)
    def self.landing(wave)
        uuid = wave["uuid"]

        loop {

            system("clear")

            puts "#{Waves::toString(wave)}".green

            puts ""

            puts "uuid: #{wave["uuid"]}".yellow
            puts "schedule: #{Waves::scheduleString(wave)}".yellow
            puts "last done: #{wave["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(wave["uuid"])}".yellow

            Librarian7Notes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            puts ""

            puts "access | done | <datecode> | description | atom | note | schedule | destroy | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if command == "access" then
                AgentsUtils::accessAtom(wave["atomuuid"])
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

            if Interpreting::match("description", command) then
                wave["description"] = Utils::editTextSynchronously(wave["description"])
                Waves::performDone(wave)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                Librarian6Objects::commit(atom)
                wave["atomuuid"] = atom["uuid"]
                Librarian6Objects::commit(wave)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian7Notes::addNote(wave["uuid"], text)
                next
            end

            if Interpreting::match("schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                Librarian6Objects::commit(wave)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    Waves::destroy(wave["uuid"])
                    break
                end
            end
        }
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

    # Waves::access(wave)
    def self.access(wave)
        system("clear")
        uuid = wave["uuid"]
        puts Waves::toString(wave)
        puts "Starting at #{Time.new.to_s}"

        AgentsUtils::accessAtom(wave["atomuuid"])

        loop {
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "stop and exit", "exit and continue", "landing and back", "delay"])

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

                # The next line handle if the landing resulted in a destruction of the object
                break if Librarian6Objects::getObjectByUUIDOrNull(wave["uuid"]).nil?
            end
            if operation == "delay" then
                unixtime = Utils::interactivelySelectUnixtimeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
                break
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
            "mikuType" => "NS16:Wave",
            "announce" => Waves::toString(wave),
            "commands" => ["..", "done"],
            "wave"     => wave
        }
    end

    # Waves::ns16s(universe)
    def self.ns16s(universe)
        items1, items2 = Waves::items()
            .select{|item| Multiverse::getUniverseOrDefault(item["uuid"]) == universe }
            .partition{|wave| Waves::isPriorityWave(wave) }

        items2 = items2
                .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }

        (items1 + items2)
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
