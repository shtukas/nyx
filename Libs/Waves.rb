
# encoding: UTF-8

class Waves

    # Waves::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:489e8f4a-8b09-456d-ad5c-64fa551b9534"
    end

    # --------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        CoreData2::getSet(Waves::coreData2SetUUID())
    end

    # Waves::itemsForDomain(domain)
    def self.itemsForDomain(domain)
        Waves::items().select{|item| item["domain"] == domain }
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

        atom = CoreData2::interactivelyCreateANewAtomOrNull([Waves::coreData2SetUUID()])
        return nil if atom.nil?

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        if schedule.nil? then
            CoreData2::destroyAtom(atom["uuid"])
            return nil
        end

        repeatType       = schedule[0]
        repeatValue      = schedule[1]
        lastDoneDateTime = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        domain           = Domain::interactivelySelectDomain()

        atom["repeatType"]       = repeatType
        atom["repeatValue"]      = repeatValue
        atom["lastDoneDateTime"] = lastDoneDateTime
        atom["domain"]           = domain

        CoreData2::commitAtom2(atom)
        atom
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
            logfile = "/Users/pascal/Galaxy/LucilleOS/Backups-Utils/logs/alexandra-latest/records.txt"
            File.open(logfile, "a"){|f| f.puts("#{Time.new.to_s} : #{Waves::toString(wave)}")}
        end

        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        CoreData2::commitAtom2(wave)

        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)

        Bank::put("WAVES-UNITS-1-44F7-A64A-72D0205F8957", 1)
    end

    # Waves::accessContent(atom)
    def self.accessContent(atom)
        CoreData2::accessWithOptionToEdit(atom)
    end

    # Waves::landing(atom)
    def self.landing(atom)
        uuid = atom["uuid"]

        loop {
            system("clear")

            puts "#{Waves::toString(atom)}".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(atom["uuid"])}".green

            puts ""

            puts "uuid: #{atom["uuid"]}".yellow
            puts "schedule: #{Waves::scheduleString(atom)}".yellow
            puts "last done: #{atom["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(atom["uuid"])}".yellow

            puts ""

            puts "[item   ] access | done | <datecode> | note | [] | update description | update contents | recast schedule | domain | destroy | exit".yellow

            puts Interpreters::makersAndDiversCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "access" then
                Waves::accessContent(atom)
                next
            end

            if command == "done" then
                Waves::performDone(atom)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(atom["uuid"]) || "")
                StructuredTodoTexts::setNote(atom["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(atom["uuid"])
                next
            end

            if Interpreting::match("update description", command) then
                atom["description"] = Utils::editTextSynchronously(atom["description"])
                Waves::performDone(atom)
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
                atom["repeatType"] = schedule[0]
                atom["repeatValue"] = schedule[1]
                CoreData2::commitAtom2(atom)
                next
            end

            if Interpreting::match("domain", command) then
                atom["domain"] = Domain::interactivelySelectDomain()
                CoreData2::commitAtom2(atom)
                break
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    CoreData2::removeAtomFromSet(atom["uuid"], Waves::coreData2SetUUID())
                    break
                end
            end

            Interpreters::makersAndDiversInterpreter(command)
        }
    end

    # -------------------------------------------------------------------------
    # Waves

    # Waves::selectWaveOrNull(domain)
    def self.selectWaveOrNull(domain)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::itemsForDomain(domain).sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::waves(domain)
    def self.waves(domain)
        loop {
            system("clear")
            wave = Waves::selectWaveOrNull(domain)
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

        nxball = NxBalls::makeNxBall([uuid, "WAVES-TIME-75-42E8-85E2-F17E869DF4D3", Domain::getDomainBankAccount(wave["domain"])])
        Waves::accessContent(wave)

        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "exit"])

        NxBalls::closeNxBall(nxball, true)

        if operation.nil? then
            operation = "done (default)"
        end

        if operation == "done (default)" then
            Waves::performDone(wave)
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
            "start-land" => lambda {
                Waves::run(wave)
            },
            "wave" => wave,
            "bank-accounts" => [Domain::getDomainBankAccount(wave["domain"])]
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
