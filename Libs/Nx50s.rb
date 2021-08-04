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

        domain = Domains::selectDomainOrNull()
        Domains::setDomainForItem(uuid, domain)

        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)

        CoreDataTx::commit(nx50)

        nx50
    end

    # Nx50s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = CoreDataTx::getObjectsBySchema("Nx50")
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx50s::getObjectsByDomain(domain | null)
    def self.getObjectsByDomain(domain)
        if domain.nil? then
            return CoreDataTx::getObjectsBySchema("Nx50")
        end
        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|item| 
                dx = Domains::getDomainForItemOrNull(item["uuid"])
                dx and (dx["uuid"] == domain["uuid"])
            }
    end

    # Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain = nil)
    def self.interactivelyDetermineNewItemUnixtimeOrNull(domain = nil)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["minus 1", "other", "last"])
        return nil if type.nil?
        if type == "minus 1" then
            return Nx50s::minusOneUnixtime()
        end
        if type == "other" then
            system('clear')
            puts "Select the before item:"
            items = Nx50s::getObjectsByDomain(domain)
            return Time.new.to_i if items.empty?
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

    # Nx50s::issueNx50UsingInboxLocationInteractive(location, domain)
    def self.issueNx50UsingInboxLocationInteractive(location, domain)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        if domain.nil? then
            domain = Domains::selectDomainOrNull()
        end
        Domains::setDomainForItem(uuid, domain)
        
        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)

        CoreDataTx::commit(nx50)
        CoreDataTx::getObjectByIdOrNull(uuid)
    end

    # Nx50s::issueNx50UsingInboxTextInteractive(text, domain)
    def self.issueNx50UsingInboxTextInteractive(text, domain)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = text.lines.first.strip
        nx50["contentType"] = "Text"
        nx50["payload"]     = BinaryBlobsService::putBlob(text)

        if domain.nil? then
            domain = Domains::selectDomainOrNull()
        end
        Domains::setDomainForItem(uuid, domain)
        
        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)

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
    # Operations

    # Nx50s::toStringCore(nx50)
    def self.toStringCore(nx50)
        "[#{nx50["contentType"]}] #{nx50["description"]}"
    end

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "#{Domains::domainPrefix(nx50["uuid"])} [nx50] #{Nx50s::toStringCore(nx50)}"
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

        nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7", Domains::getDomainUUIDForItemOrNull(uuid)].compact)

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
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

            if Domains::getDomainUUIDForItemOrNull(uuid).nil? then
                domain = Domains::selectDomainOrNull()
                if domain then
                    nxball["bankAccounts"] << domain["uuid"]
                    Domains::setDomainForItem(uuid, domain)
                end
            end

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx50["contentType"]}, #{nx50["payload"]}".yellow
            puts "domain: #{Domains::getDomainForItemOrNull(nx50["uuid"])}".yellow
            puts "schedule: #{nx50["schedule"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            puts ""

            puts "access | note | [] | <datecode> | detach running | exit | completed | edit description | edit domain | edit contents | edit unixtime | edit schedule | transmute | destroy".yellow

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

            if Interpreting::match("note", command) then
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
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7", Domains::getDomainUUIDForItemOrNull(uuid)].compact)
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

            if Interpreting::match("edit domain", command) then
                domain = Domains::selectDomainOrNull()
                Domains::setDomainForItem(nx50["uuid"], domain)
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

            if Interpreting::match("edit unixtime", command) then
                domain = Domains::getDomainForItemOrNull(nx50["uuid"])
                nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)
                CoreDataTx::commit(nx50)
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

        NxBalls::closeNxBall(nxball, true)

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
    # nx16s

    # Nx50s::hoursOverThePast21Days(nx50)
    def self.hoursOverThePast21Days(nx50)
        Bank::valueOverTimespan(nx50["uuid"], 86400*21).to_f/3600
    end

    # Nx50s::hoursDoneSinceLastSaturday(nx50)
    def self.hoursDoneSinceLastSaturday(nx50)
        Utils::datesSinceLastSaturday().map{|date| Bank::valueAtDate(uuid, date)}.inject(0, :+).to_f/3600
    end

    # Nx50s::saturationRT(nx50)
    def self.saturationRT(nx50)
        # This function returns the recovery time after with the item is saturated
        t1 = Bank::valueOverTimespan(nx50["uuid"], 86400*14)
        tx = t1.to_f/(10*3600) # multiple of 10 hours over two weeks
        Math.exp(-tx)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if (Nx50s::hoursOverThePast21Days(nx50) > 10 and Nx50s::hoursDoneSinceLastSaturday(nx50) > 2)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return nil if rt > Nx50s::saturationRT(nx50)
        announce = "#{Domains::domainPrefix(uuid)} [nx50] (#{"%4.2f" % rt}) #{Nx50s::toStringCore(nx50)}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                end
            },
            "[]"      => lambda { StructuredTodoTexts::applyT(uuid) },
            "domain"  => Domains::getDomainForItemOrNull(uuid),
            "rt"      => rt
        }
    end

    # Nx50s::ns16s(domain)
    def self.ns16s(domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s").each{|location|
            Nx50s::issueNx50UsingLocation(location)
        }

        if domain["uuid"] == Domains::alexandra()["uuid"] then
            rtForComparison = lambda{|rt|
                (rt == 0) ? 0.4 : rt
            }

            isSelectedForNS16 = lambda{|nx50, domain|
                itemdomain = Domains::getDomainForItemOrNull(nx50["uuid"])
                return true if itemdomain.nil?
                itemdomain["uuid"] == domain["uuid"]
            }

            ns16s = CoreDataTx::getObjectsBySchema("Nx50")
                        .select{|nx50| isSelectedForNS16.call(nx50, domain) }
                        .map{|nx50| Nx50s::ns16OrNull(nx50) }
                        .compact

            ns16s.first(3).sort{|n1, n2| rtForComparison.call(n1["rt"]) <=> rtForComparison.call(n2["rt"]) } + ns16s.drop(3)

            return ns16s
        end

        if domain["uuid"] == Domains::workDomain()["uuid"] then
            isSelectedForNS16 = lambda{|nx50, domain|
                itemdomain = Domains::getDomainForItemOrNull(nx50["uuid"])
                return false if itemdomain.nil?
                itemdomain["uuid"] == domain["uuid"]
            }

            ns16s = CoreDataTx::getObjectsBySchema("Nx50")
                        .select{|nx50| isSelectedForNS16.call(nx50, domain) }
                        .map{|nx50| Nx50s::ns16OrNull(nx50) }
                        .compact

            return ns16s
        end

        raise "[error: 61a6fdff-dd2d-48b3-a7c0-bba0c26a7a9e]"
    end

    # --------------------------------------------------

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
