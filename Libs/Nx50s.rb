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

    # Nx50s::isFull()
    def self.isFull()
        CoreDataTx::getObjectsBySchema("Nx50").size >= 50
    end

    # Nx50s::importURLAsNewURLNx50(url)
    def self.importURLAsNewURLNx50(url)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "Nx50"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = url
        quark["contentType"] = "Url"
        quark["payload"]     = url

        CoreDataTx::commit(quark)
    end

    # Nx50s::importLocationAsNewAionPointNx50(location)
    def self.importLocationAsNewAionPointNx50(location)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "Nx50"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = File.basename(location) 
        quark["contentType"] = "AionPoint"
        quark["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(quark)
    end

    # Nx50s::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("Nx50").size <= 20 then
            Quarks::quarks()
                .sample(20)
                .each{|object|
                    object["schema"] = "Nx50"
                    CoreDataTx::commit(object)
                }
        end
    end

    # Nx50s::toNS15(nx50)
    def self.toNS15(nx50)
        uuid = nx50["uuid"]

        stdRecTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)

        announce = "[nx50] (#{"%.3f" % stdRecTime}) #{nx50["description"]}"

        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(nx50)}' ? ", true) then
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
        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|nx50| Nx50s::toNS15(nx50) }
            .reject{|nx50| nx50["x-24Timespan" ] >= 3600 }
            .sort{|i1, i2| i1["x-stdRecoveryTime"] <=> i2["x-stdRecoveryTime"] }
            .reverse
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
            puts "listing: new wave / ondate / calendar item / quark / todo / work item / project | exit".yellow
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

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewOrNull()
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

        UIServices::programmableListingDisplay(getItems, processItems)

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