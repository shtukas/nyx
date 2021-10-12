
# encoding: UTF-8

class Vectors

    # --------------------------------------------------
    # IO

    # Vectors::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/vectors"
    end

    # Vectors::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Vectors::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Vectors::items()
    def self.items()
        LucilleCore::locationsAtFolder(Vectors::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
    end

    # Vectors::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Vectors::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Vectors::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Vectors::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Making

    # Vectors::makeScheduleParametersInteractivelyOrNull() # [type, value]
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

    # Vectors::vectorToDoNotShowUnixtime(vector)
    def self.vectorToDoNotShowUnixtime(vector)
        if vector["repeatType"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 86400) + vector["repeatValue"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + vector["repeatValue"].to_i*3600
        end
        if vector["repeatType"] == 'every-n-hours' then
            return Time.new.to_i+3600 * vector["repeatValue"].to_f
        end
        if vector["repeatType"] == 'every-n-days' then
            return Time.new.to_i+86400 * vector["repeatValue"].to_f
        end
        if vector["repeatType"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != vector["repeatValue"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if vector["repeatType"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != vector["repeatValue"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Vectors::scheduleString(vector)
    def self.scheduleString(vector)
        if vector["repeatType"] == 'sticky' then
            return "sticky, from: #{vector["repeatValue"]}"
        end
        "#{vector["repeatType"]}: #{vector["repeatValue"]}"
    end

    # Vectors::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_i

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("content type", ["line", "url"])
        return nil if type.nil?

        description  = nil
        coreDataId      = nil

        if type == "line" then
            description    = LucilleCore::askQuestionAnswerAsString("line: ")
        end

        if type == "url" then
            url            = LucilleCore::askQuestionAnswerAsString("url: ")
            coreDataId        = SecureRandom.uuid
            description    = url
            CoreData::issueUrlPointDataObjectUsingUrl(url)
        end

        schedule = Vectors::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        repeatType   = schedule[0]
        repeatValue  = schedule[1]
        lastDoneDateTime = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        vector = {
          "uuid"             => uuid,
          "unixtime"         => unixtime,
          "description"      => description,
          "coreDataId"          => coreDataId,
          "repeatType"       => repeatType,
          "repeatValue"      => repeatValue,
          "lastDoneDateTime" => lastDoneDateTime
        }
        Vectors::commitItemToDisk(vector)
        vector
    end

    # -------------------------------------------------------------------------
    # Operations

    # Vectors::toString(vector)
    def self.toString(vector)
        ago = "#{((Time.new.to_i - DateTime.parse(vector["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "[vector] #{vector["description"]} (#{Vectors::scheduleString(vector)}) (#{ago})"
    end

    # Vectors::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("vector", Vectors::items().sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|vector| Vectors::toString(vector) })
    end

    # Vectors::performDone(vector)
    def self.performDone(vector)
        puts "done-ing: #{Vectors::toString(vector)}"
        vector["lastDoneDateTime"] = Time.now.utc.iso8601
        Vectors::commitItemToDisk(vector)

        unixtime = Vectors::vectorToDoNotShowUnixtime(vector)
        puts "Not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(vector["uuid"], unixtime)

        Bank::put("WAVE-CIRCUIT-BREAKER-A-B8-4774-A416F", 1)
    end

    # Vectors::main()
    def self.main()
        loop {
            puts "Vectors 🌊 (main)"
            options = [
                "vector",
                "vectors dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "vector" then
                Vectors::issueNewWaveInteractivelyOrNull()
            end
            if option == "vectors dive" then
                loop {
                    system("clear")
                    vector = Vectors::selectWaveOrNull()
                    return if vector.nil?
                    Vectors::landing(vector)
                }
            end
        }
    end

    # Vectors::accessContent(vector)
    def self.accessContent(vector)
        CoreData::accessWithOptionToEdit(vector["coreDataId"])
    end

    # Vectors::landing(vector)
    def self.landing(vector)
        uuid = vector["uuid"]

        nxball = NxBalls::makeNxBall([uuid])

        loop {
            system("clear")

            puts "#{Vectors::toString(vector)}".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(vector["uuid"])}".green

            puts ""

            puts "uuid: #{vector["uuid"]}".yellow
            puts "schedule: #{Vectors::scheduleString(vector)}".yellow
            puts "last done: #{vector["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(vector["uuid"])}".yellow

            puts ""

            puts "[item   ] access | done | <datecode> | note | [] | detach running | update description | update contents | recast schedule | destroy".yellow

            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "access" then
                Vectors::accessContent(vector)
                next
            end

            if command == "done" then
                Vectors::performDone(vector)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(vector["uuid"]) || "")
                StructuredTodoTexts::setNote(vector["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(vector["uuid"])
                next
            end

            if command == "detach running" then
                DetachedRunning::issueNew2(Vectors::toString(vector), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("update description", command) then
                vector["description"] = Utils::editTextSynchronously(vector["description"])
                Vectors::performDone(vector)
                next
            end

            if Interpreting::match("update contents", command) then
                puts "update contents against NxAxiom library has not been implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("recast schedule", command) then
                schedule = Vectors::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                vector["repeatType"] = schedule[0]
                vector["repeatValue"] = schedule[1]
                Vectors::commitItemToDisk(vector)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this vector ? : ") then
                    Vectors::destroy(vector)
                    break
                end
            end

            Interpreters::mainMenuInterpreter(command)
        }

        NxBalls::closeNxBall(nxball, true)
    end

    # -------------------------------------------------------------------------
    # NS16

    # Vectors::run(vector)
    def self.run(vector)
        system("clear")
        uuid = vector["uuid"]
        puts Vectors::toString(vector)
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid])

        Vectors::accessContent(vector)

        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "detach running; will done", "exit"])

        NxBalls::closeNxBall(nxball, true)

        if operation.nil? then
            operation = "done (default)"
        end

        if operation == "done (default)" then
            Vectors::performDone(vector)
        end

        if operation == "detach running; will done" then
            Vectors::performDone(vector)
            DetachedRunning::issueNew2(Vectors::toString(vector), Time.new.to_i, [uuid])
        end

        if operation == "exit" then

        end
    end

    # Vectors::toNS16(vector)
    def self.toNS16(vector)
        uuid = vector["uuid"]
        {
            "uuid"        => uuid,
            "announce"    => Vectors::toString(vector),
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda{|command|
                if command == ".." then
                    Vectors::run(vector)
                end
                if command == "landing" then
                    Vectors::landing(vector)
                end
                if command == "done" then
                    Vectors::performDone(vector)
                end
            },
            "run" => lambda {
                Vectors::run(vector)
            },
            "vector" => vector,
        }
    end

    # Vectors::vectorOrderingPriority(vector)
    def self.vectorOrderingPriority(vector)
        mapping = {
            "sticky"                      => 5,
            "every-this-day-of-the-month" => 4,
            "every-this-day-of-the-week"  => 3,
            "every-n-hours"               => 2,
            "every-n-days"                => 1
        }
        mapping[vector["repeatType"]]
    end

    # Vectors::ns16ToOrderingWeight(ns16)
    def self.ns16ToOrderingWeight(ns16)
        Vectors::vectorOrderingPriority(ns16["vector"])
    end

    # Vectors::isPriorityWave(vector)
    def self.isPriorityWave(vector)
        Vectors::vectorOrderingPriority(vector) >= 3
    end

    # Vectors::compareNS16s(n1, n2)
    def self.compareNS16s(n1, n2)
        if Vectors::ns16ToOrderingWeight(n1) < Vectors::ns16ToOrderingWeight(n2) then
            return -1
        end
        if Vectors::ns16ToOrderingWeight(n1) > Vectors::ns16ToOrderingWeight(n2) then
            return 1
        end
        n1["uuid"] <=> n2["uuid"]
    end

    # Vectors::ns16s()
    def self.ns16s()
        Vectors::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::ns16ShouldShow(item["uuid"]) }
            .map{|vector| Vectors::toNS16(vector) }
            .sort{|n1, n2| Vectors::compareNS16s(n1, n2) }
            .reverse
    end

    # Vectors::nx19s()
    def self.nx19s()
        Vectors::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Vectors::toString(item),
                "lambda"   => lambda { Vectors::landing(item) }
            }
        }
    end
end
