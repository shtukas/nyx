# encoding: UTF-8

=begin

Nx50s doesn't use NS16s, and use NS15s instead

NS15 {
    "uuid"     : String # used by DoNotShowUntil
    "announce" : String
    "access"   : Lambda or nil # optional
    "done"     : Lambda or nil # optional
    "[]"       : Lambda or nil # optional
}

=end

class Nx50s

    # Nx50s::importURLAsNewURLNx50(url)
    def self.importURLAsNewURLNx50(url)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = url
        nx50["contentType"] = "Url"
        nx50["payload"]     = url

        CoreDataTx::commit(nx50)
    end

    # Nx50s::importLocationAsNewAionPointNx50(location)
    def self.importLocationAsNewAionPointNx50(location)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(nx50)
    end

    # --------------------------------------------------

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

    # Nx50s::landing(quark)
    def self.landing(quark)
        loop {

            puts Nx50s::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts "access (partial edit) | edit | transmute | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(quark["contentType"], quark["payload"])
                if coordinates then
                    quark["contentType"] = coordinates[0]
                    quark["payload"]     = coordinates[1]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("edit", command) then
                coordinates = Nx102::edit(quark["description"], quark["contentType"], quark["payload"])
                if coordinates then
                    quark["description"] = coordinates[0]
                    quark["contentType"] = coordinates[1]
                    quark["payload"]     = coordinates[2]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("transmute", command) then
                Nx102::transmute(quark["description"], quark["contentType"], quark["payload"])
            end

            if Interpreting::match("destroy", command) then
                CoreDataTx::delete(quark["uuid"])
                break
            end
        }
    end

    # --------------------------------------------------

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # Nx50s::access(nx50)
    def self.access(nx50)

        uuid = nx50["uuid"]

        nxball = BankExtended::makeNxBall([uuid, "Nx50s-E65A9917-EFF4-4AF7-877C-CC0DC10C8794"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, true)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        system("clear")
        
        puts "running: #{Nx50s::toString(nx50)}".green

        coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
        if coordinates then
            nx50["contentType"] = coordinates[0]
            nx50["payload"]     = coordinates[1]
            CoreDataTx::commit(nx50)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(nx50["uuid"]).nil?

            system("clear")

            puts "running: #{Nx50s::toString(nx50)}".green

            puts "access | landing | <datecode> | detach running | done | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx50["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    ProjectItems::commit(nx50)
                end
                next
            end

            if Interpreting::match("landing", command) then
                Nx50s::landing(nx50)
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-E65A9917-EFF4-4AF7-877C-CC0DC10C8794"])
                break
            end

            if Interpreting::match("done", command) then
                Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
                CoreDataTx::delete(nx50["uuid"])
                break
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
    end

    # Nx50s::toNS15(nx50)
    def self.toNS15(nx50)
        uuid = nx50["uuid"]

        stdRecTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)

        announce = "[nx50] (#{"%.3f" % stdRecTime}) #{nx50["description"]}"

        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    CoreDataTx::delete(nx50["uuid"])
                end
            },
            "x-source"          => "Nx50s",
            "x-stdRecoveryTime" => stdRecTime,
            "x-24Timespan"      => Bank::valueOverTimespan(uuid, 86400)
        }
    end

    # Nx50s::ns15s()
    def self.ns15s()
        # Visible, less than one hour in the past day, highest stdRecoveredDailyTime first

        items0 = CoreDataTx::getObjectsBySchema("Nx50")
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .map{|nx50| Nx50s::toNS15(nx50) }
                    .sort{|i1, i2| i1["x-stdRecoveryTime"] <=> i2["x-stdRecoveryTime"] }

        items1 = items0
                    .select{|nx50| nx50["x-24Timespan" ] < 3600 }
                    .reverse

        items2 = items0
                    .select{|nx50| nx50["x-24Timespan" ] >= 3600 }
                    .map{|ns15|
                        ns15["announce"] = ns15["announce"].red
                        ns15
                    }

        items1.take(3) + items2 + items1.drop(3)
    end

    # Nx50s::timeCommitmentPerWeek()
    def self.timeCommitmentPerWeek()
        2*7 # 2 hours per day
    end

    # Nx50s::main()
    def self.main()

        getItems = lambda { Nx50s::ns15s() }

        processItems = lambda {|items|

            system("clear")

            vspaceleft = Utils::screenHeight()-6

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                announce   = "#{indexStr} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }
            puts "( Nx50s: #{CoreDataTx::getObjectsBySchema("Nx50").size} items )"
            puts "listing: new wave / ondate / calendar item / todo / work item / project | exit".yellow
            if !items.empty? then
                puts "top    : .. (access top) | select / expose / start / done (<n>) | [] (Priority.txt) | <datecode> | done".yellow
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return "ns:loop" if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                item = items[0]
                return "ns:loop" if item.nil? 
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return "ns:loop"
            end

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                UIServices::accessItem(items[0])
                return "ns:loop"
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                UIServices::accessItem(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("expose *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                return "ns:loop" if item.nil?
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                return "ns:loop"
            end

            if Interpreting::match("access", command) then
                UIServices::accessItem(items[0])
                return "ns:loop"
            end

            if Interpreting::match("start *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                UIServices::accessItem(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("done", command) then
                item = items[0]
                return "ns:loop" if item.nil? 
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                return "ns:loop" if item.nil?
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("new project", command) then
                Projects::interactivelyCreateNewProject()
                return "ns:loop"
            end

            if Interpreting::match("new ondate", command) then
                Nx31s::interactivelyIssueNewOrNull()
                return "ns:loop"
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
                return "ns:loop"
            end

           if Interpreting::match("new todo", command) then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort) : ")
                return "ns:loop" if line == ""
                nx50 = {
                    "uuid"        => SecureRandom.uuid,
                    "schema"      => "Nx50",
                    "unixtime"    => Time.new.to_i,
                    "description" => line,
                    "contentType" => "Line",
                    "payload"     => ""
                }
                puts JSON.pretty_generate(nx50)
                CoreDataTx::commit(nx50)
                return "ns:loop"
            end

            if Interpreting::match("new work item", command) then
                Work::interactvelyIssueNewItem()
                return "ns:loop"
            end

            if Interpreting::match("new calendar item", command) then
                Calendar::interactivelyIssueNewCalendarItem()
                return "ns:loop"
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                next if item.nil? 
                next if item["[]"].nil?
                item["[]"].call()
                return "ns:loop"
            end

            if Interpreting::match("exit", command) then
                return "ns:exit"
            end

            "ns:loop"
        }

        startUnixtime = Time.new.to_i

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - startUnixtime) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 itself running for more than an hour")
                end
            }
        }

        UIServices::programmableListingDisplay(getItems, processItems)

        thr.exit
    end

    # Nx50s::ns16()
    def self.ns16()
        ratio = BankExtended::completionRatioRelativelyToTimeCommitmentInHoursPerWeek("Nx50s-E65A9917-EFF4-4AF7-877C-CC0DC10C8794", Nx50s::timeCommitmentPerWeek())
        metric = ((ratio < 1) ? ["ns:time-commitment", ratio] : ["ns:zero", nil])
        {
            "uuid"     => "Nx50s-E65A9917-EFF4-4AF7-877C-CC0DC10C8794",
            "metric"   => metric,
            "announce" => "[Nx50] (completion: #{"%6.2f" % (ratio*100)} % of #{"%4.1f" % Nx50s::timeCommitmentPerWeek()})",
            "access"   => lambda { Nx50s::main() },
            "done"     => lambda { }
        }
    end
end