# encoding: UTF-8

class Nx50s

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        nx50["description"] = description

        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?

        nx50["contentType"] = coordinates[0]
        nx50["payload"]     = coordinates[1]

        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)

        CoreDataTx::commit(nx50)

        nx50
    end

    # Nx50s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = CoreDataTx::getObjectsBySchema("Nx50")
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx50s::interactivelyDetermineNewItemUnixtimeOrNull()
    def self.interactivelyDetermineNewItemUnixtimeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["minus 1", "other", "last"])
        return nil if type.nil?
        if type == "minus 1" then
            return Nx50s::minusOneUnixtime()
        end
        if type == "other" then
            system('clear')
            puts "Select the before item:"
            items = CoreDataTx::getObjectsBySchema("Nx50")
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Nx50s::toString(item) })
            return nil if item.nil?
            loop {
                return nil if items.size < 2
                if items[0]["uuid"] == item["uuid"] then
                    return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
                end
                items.shift
                next
            }
        end
        if type == "last" then
            return Time.new.to_i
        end
    end

    # Nx50s::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = url
        nx50["contentType"] = "Url"
        nx50["payload"]     = url

        CoreDataTx::commit(nx50)
        CoreDataTx::getObjectByIdOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(nx50)
        CoreDataTx::getObjectByIdOrNull(uuid)
    end

    # Nx50s::issueNx50UsingTextInteractive(text)
    def self.issueNx50UsingTextInteractive(text)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = text.lines.first.strip
        nx50["contentType"] = "Text"
        nx50["payload"]     = BinaryBlobsService::putBlob(text)

        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)

        CoreDataTx::commit(nx50)
        CoreDataTx::getObjectByIdOrNull(uuid)
    end

    # Nx50s::transmuteToNx50UsingNx31Interactive(nx31)
    def self.transmuteToNx50UsingNx31Interactive(nx31)
        nx50 = nx31.clone
        nx50["schema"] = "Nx50"
        nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || nx31["unixtime"])
        CoreDataTx::commit(nx50)
        CoreDataTx::getObjectByIdOrNull(nx50["uuid"])
    end

    # --------------------------------------------------

    # Nx50s::toStringCore(nx50)
    def self.toStringCore(nx50)
        "[#{nx50["contentType"]}] #{nx50["description"]}"
    end

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{Nx50s::toStringCore(nx50)}"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{Nx50s::toString(nx50)}") }
        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
        CoreDataTx::delete(nx50["uuid"])
    end

    # Nx50s::access(nx50)
    def self.access(nx50)

        uuid = nx50["uuid"]

        nxball = BankExtended::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            return if CoreDataTx::getObjectByIdOrNull(uuid).nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx50s::toString(nx50)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green
            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx50["contentType"]}, #{nx50["payload"]}".yellow
            puts "schedule: #{nx50["schedule"]}".yellow
            if (unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)) then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(nx50["uuid"])}".yellow

            puts ""
            puts "access | note: | [] | landing | <datecode> | detach running | exit | completed".yellow
            puts "edit description | edit contents | edit schedule | transmute | destroy".yellow
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("note:", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx50["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                break
            end

            if Interpreting::match("completed", command) then
                Nx50s::complete(nx50)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("edit description", command) then
                description = Utils::editTextSynchronously(nx50["description"])
                if description.size > 0 then
                    nx50["description"] = description
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("edit contents", command) then
                coordinates = Nx102::edit(nx50["description"], nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("edit schedule", command) then
                nx50["schedule"] = JSON.parse(Utils::editTextSynchronously(JSON.pretty_generate(nx50["schedule"])))
                CoreDataTx::commit(nx50)
                next
            end

            if Interpreting::match("transmute", command) then
                coordinates = Nx102::transmute(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("destroy", command) then
                Nx50s::complete(nx50)
                break
            end

            UIServices::mainMenuInterpreter(command)
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
    end
    
    # Nx50s::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("Nx50").size <= 30 then
            CoreDataTx::getObjectsBySchema("quark")
                .sample(20)
                .each{|object|
                    object["schema"] = "Nx50"
                    CoreDataTx::commit(object)
                }
        end
    end

    # Nx50s::getCompletionLogUnixtimes()
    def self.getCompletionLogUnixtimes()
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt"
        IO.read(filepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0}
            .map{|line| line.split("|")[1].to_i }
    end

    # Nx50s::completionLogSize(days)
    def self.completionLogSize(days)
        horizon = Time.new.to_i - days*86400
        Nx50s::getCompletionLogUnixtimes().select{|unixtime| unixtime >= horizon }.size
    end

    # --------------------------------------------------

    # Nx50s::saturationRT(nx50)
    def self.saturationRT(nx50)
        # This function returns the recovery time after with the item is saturated
        t1 = Bank::valueOverTimespan(nx50["uuid"], 86400*14)
        tx = t1.to_f/(7*3600) # multiple of 7 hours over two weeks
        Math.exp(-tx)
    end

    # Nx50s::ns16(nx50)
    def self.ns16(nx50)
        uuid = nx50["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        saturation = Nx50s::saturationRT(nx50)
        announce = "[nx50] (#{"%4.2f" % rt}) #{Nx50s::toStringCore(nx50)}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                end
            },
            "[]"         => lambda { StructuredTodoTexts::applyT(nx50["uuid"]) },
            "unixtime"   => nx50["unixtime"],
            "nx50"       => nx50,
            "rt"         => rt,
            "saturation" => saturation,
            "isVisible"  => DoNotShowUntil::isVisible(uuid)
        }
    end

    # Nx50s::shouldShowNS16(ns16)
    def self.shouldShowNS16(ns16)
        return false if !ns16["isVisible"]

        nx50 = ns16["nx50"]

        if nx50["schedule"]["type"] == "indefinite-daily-commitment" then
            if nx50["schedule"]["exclusionDays"] and nx50["schedule"]["exclusionDays"].include?(Time.new.wday) then
                return false
            end
            return (Bank::valueAtDate(nx50["uuid"], Utils::today()) < nx50["schedule"]["hours"]*3600)
        end

        if nx50["schedule"]["type"] == "indefinite-weekly-commitment" then
            doneTimeInSeconds = Utils::datesSinceLastSaturday()
                                    .map{|date| Bank::valueAtDate(nx50["uuid"], date)}
                                    .inject(0, :+)
            return (doneTimeInSeconds < nx50["schedule"]["hours"]*3600)
        end

        if nx50["schedule"]["type"] == "regular" then
            return ns16["rt"] < ns16["saturation"]
        end

        raise "[error: 47e04a3d-5f18-493e-a8ec-3bebda4d430f] #{ns16}"
    end

    # Nx50s::getOperationalNS16ByUUIDOrNull(uuid)
    def self.getOperationalNS16ByUUIDOrNull(uuid)
        nx50 = CoreDataTx::getObjectByIdOrNull(uuid)
        return nil if nx50.nil?
        ns16 = Nx50s::ns16(nx50)
        return nil if !ns16["isVisible"]
        return nil if ns16["rt"] >= ns16["saturation"]
        ns16
    end

    # Nx50s::ns16sOfScheduleTypes(types)
    def self.ns16sOfScheduleTypes(types)

        rtForComparizon = lambda {|rt|
            # We do this to prevent zero elements to keep taking the focus
            return 0.25 if rt < 0.1
            rt
        }

        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|nx50| types.include?(nx50["schedule"]["type"]) }
            .map{|nx50| Nx50s::ns16(nx50) }
            .select{|ns16| Nx50s::shouldShowNS16(ns16) }
            .first(3)
            .sort{|i1, i2| rtForComparizon.call(i1["rt"]) <=> rtForComparizon.call(i2["rt"]) }
    end

    # Nx50s::ns16sExtended()
    def self.ns16sExtended()
        CoreDataTx::getObjectsBySchema("Nx50")
            .map{|nx50| Nx50s::ns16(nx50) }
            .map{|ns16|
                if ns16["rt"] >= ns16["saturation"] then
                    ns16["announce"] = "#{ns16["announce"]} [saturated]"
                end
                ns16
            }
            .map{|ns16|
                if !ns16["isVisible"] then
                    ns16["announce"] = "#{ns16["announce"]} [hidden until #{Time.at(DoNotShowUntil::getUnixtimeOrNull(ns16["uuid"])).to_s}]"
                    ns16["uuid"] = SecureRandom.hex
                end
                ns16
            }
    end

    # Nx50s::nx19s()
    def self.nx19s()
        CoreDataTx::getObjectsBySchema("Nx50").map{|item|
            {
                "announce" => Nx50s::toString(item),
                "lambda"   => lambda { Nx50s::access(item) }
            }
        }
    end
end

Thread.new {
    loop {
        sleep 3600
        Nx50s::maintenance()
    }
}
