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

    # Nx50s::issueNx50UsingLocationInteractive(location)
    def self.issueNx50UsingLocationInteractive(location)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        domain = Domains::selectDomainOrNull()
        Domains::setDomainForItem(uuid, domain)
        
        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)

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

        domain = Domains::selectDomainOrNull()
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
            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx50["contentType"]}, #{nx50["payload"]}".yellow
            puts "domain: #{Domains::getDomainForItemOrNull(nx50["uuid"])}".yellow
            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts "schedule: #{nx50["schedule"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            
            puts ""
            puts "edit description | edit domain | edit contents | edit unixtime | edit schedule | transmute | destroy".yellow
            puts "access | note: | [] | <datecode> | detach running | exit | completed".yellow

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
    # nx16s

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
        isSaturated = rt > saturation
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
            "[]"          => lambda { StructuredTodoTexts::applyT(uuid) },
            "domain"      => Domains::getDomainForItemOrNull(uuid),
            "rt"          => rt,
            "saturation"  => saturation,
            "isSaturated" => isSaturated,
            "isVisible"   => DoNotShowUntil::isVisible(uuid)
        }
    end

    # Nx50s::ns16sIndefinite()
    def self.ns16sIndefinite()
        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|nx50| (nx50["schedule"]["type"] == "indefinite-daily-commitment") or (nx50["schedule"]["type"] == "indefinite-weekly-commitment") }
            .map{|nx50| Nx50s::ns16(nx50) }
            .compact
    end

    # Nx50s::ns16sRegularPrimaryThreeOfTheDay()
    def self.ns16sRegularPrimaryThreeOfTheDay()
        liveFirstThree = lambda {
            CoreDataTx::getObjectsBySchema("Nx50")
                .select{|nx50| nx50["schedule"]["type"] == "regular" }
                .select{|nx50| DoNotShowUntil::isVisible(nx50["uuid"]) }
                .first(3)
                .map{|nx50| nx50["uuid"] }
        }

        three = lambda {
            today = Utils::today()
            location = "6d5e7249-5a6d-4c08-8b8f-4dfafcc0113f:#{today}"
            uuids = KeyValueStore::getOrNull(nil, location)
            if uuids.nil? then
                uuids = liveFirstThree.call()
                KeyValueStore::set(nil, location, JSON.generate(uuids))
            else
                uuids = JSON.parse(uuids)
            end
            uuids
        }

        three.call()
            .map{|uuid| CoreDataTx::getObjectByIdOrNull(uuid) }
            .compact
            .map{|nx50| Nx50s::ns16(nx50) }
    end

    # Nx50s::ns16sRegularSecondary()
    def self.ns16sRegularSecondary()
        three = lambda {
            today = Utils::today()
            location = "6d5e7249-5a6d-4c08-8b8f-4dfafcc0113f:#{today}"
            uuids = KeyValueStore::getOrNull(nil, location)
            if uuids.nil? then
                uuids = liveFirstThree.call()
                KeyValueStore::set(nil, location, JSON.generate(uuids))
            else
                uuids = JSON.parse(uuids)
            end
            uuids
        }

        three = three.call()

        nx50s = CoreDataTx::getObjectsBySchema("Nx50")
                    .select{|nx50| nx50["schedule"]["type"] == "regular" }
                    .select{|nx50| !three.include?(nx50["uuid"]) }

        items1 = nx50s.select{|nx50| Bank::valueOverTimespan(nx50["uuid"], 86400*7) > 0 } # active within the past week
        items2 = nx50s.select{|nx50| Bank::valueOverTimespan(nx50["uuid"], 86400*7) == 0 }

        (items1 + items2)
            .map{|nx50| Nx50s::ns16(nx50) }
            .compact
    end

    # Nx50s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s").each{|location|
            Nx50s::issueNx50UsingLocation(location)
        }

        (Nx50s::ns16sIndefinite() + Nx50s::ns16sRegularPrimaryThreeOfTheDay() + Nx50s::ns16sRegularSecondary())
            .select{|ns16| !ns16["isSaturated"] }
            .first(3)
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
