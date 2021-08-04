# encoding: UTF-8

=begin

{
    "uuid"         => String
    "unixtime"     => Float
    "description"  => String
    "catalystType" => "Nx31"

    "payload1" : String | null
    "payload2" : String | null
    "payload3" :

    "contentType"    : payload1
    "contentPayload" : payload2
}

=end

=begin
# -----------------------------------
Saturation Simulation

times = []

def averageOverThePastNDays(times, n)
    times.last(n).inject(0, :+).to_f/n
end

def computeRecoveryTime(times)
    (1..7).map{|n| averageOverThePastNDays(times, n) }.max
end

def saturationRT(times)
    timeInHours = times.last(14).inject(0, :+)
    tx = timeInHours.to_f/10 # multiple of 10 hours over two weeks
    Math.exp(-tx)
end

(0..100).each {|i|
    saturation = saturationRT(times)
    times << saturation
    rt = computeRecoveryTime(times)
    puts "saturation: #{saturation.round(2)}, rt: #{rt.round(2)}"
    sleep 1
}

The above code was to convince myself that the value of the exponential wasn't too badly chosen. Interestingly the daily saturation converges to 0.5 :)
=end

class Nx50s

=begin

{
    "uuid"         => String
    "unixtime"     => Float
    "description"  => String
    "catalystType" => "quark" | "Nx50"

    "payload1" : String # contentType
    "payload2" : String # contentPayload
    "payload3" : nil

    "contentType"    : payload1
    "contentPayload" : payload2
}

=end

    # Nx50s::databaseItemToNx50(item)
    def self.databaseItemToNx50(item)
        item["contentType"]    = item["payload1"]
        item["contentPayload"] = item["payload2"]
        item
    end

    # Nx50s::nx50s()
    def self.nx50s()
        CatalystDatabase::getItemsByCatalystType("Nx50").map{|item|
            Nx50s::databaseItemToNx50(item)
        }
    end

    # Nx50s::quarks()
    def self.quarks()
        CatalystDatabase::getItemsByCatalystType("quark").map{|item|
            Nx50s::databaseItemToNx50(item)
        }
    end

    # Nx31s::commitNx50ToDisk(nx50)
    def self.commitNx50ToDisk(nx50)
        uuid         = nx50["uuid"]
        unixtime     = nx50["unixtime"]
        description  = nx50["description"]
        catalystType = "Nx50"
        payload1     = nx50["contentType"]
        payload2     = nx50["contentPayload"]
        payload3     = nil
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Nx50s::getNx50ByUUIDOrNull(uuid)
    def self.getNx50ByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        Nx50s::databaseItemToNx50(item)
    end

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates = Axion::interactivelyIssueNewCoordinatesOrNullNoLine()

        domain = Domains::selectDomainOrNull()
        Domains::setDomainForItem(uuid, domain)

        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)

        catalystType = "Nx50"
        payload1     = coordinates ? coordinates["contentType"] : nil
        payload2     = coordinates ? coordinates["contentPayload"] : nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = Nx50s::nx50s()
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx50s::getObjectsByDomain(domain | null)
    def self.getObjectsByDomain(domain)
        if domain.nil? then
            return Nx50s::nx50s()
        end
        Nx50s::nx50s()
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
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = url
        catalystType = "Nx50"
        payload1     = "url"
        payload2     = url
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = File.basename(location) 
        catalystType = "Nx50"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingInboxLocationInteractive(location, domain)
    def self.issueNx50UsingInboxLocationInteractive(location, domain)
        uuid         = SecureRandom.uuid
        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)
        description  = LucilleCore::askQuestionAnswerAsString("description: ")
        catalystType = "Nx50"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        if domain.nil? then
            domain = Domains::selectDomainOrNull()
        end
        Domains::setDomainForItem(uuid, domain)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingInboxTextInteractive(text, domain)
    def self.issueNx50UsingInboxTextInteractive(text, domain)
        uuid         = SecureRandom.uuid
        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)
        description  = LucilleCore::askQuestionAnswerAsString("description: ")
        catalystType = "Nx50"
        payload1     = "text"
        payload2     = AxionBinaryBlobsService::putBlob(text)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        if domain.nil? then
            domain = Domains::selectDomainOrNull()
        end
        Domains::setDomainForItem(uuid, domain)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::toStringCore(nx50)
    def self.toStringCore(nx50)
        contentType = nx50["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{nx50["contentType"]})" : ""
        "#{nx50["description"]}#{str1}"
    end

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "#{Domains::domainPrefix(nx50["uuid"])} [nx50] #{Nx50s::toStringCore(nx50)}"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{Nx50s::toString(nx50)}") }
        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])
        CatalystDatabase::delete(nx50["uuid"])
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

            nx50 = Nx50s::getNx50ByUUIDOrNull(uuid)

            return if nx50.nil?

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
            puts "coordinates: #{nx50["contentType"]}, #{nx50["contentPayload"]}".yellow
            puts "domain: #{Domains::getDomainForItemOrNull(nx50["uuid"])}".yellow
            puts "schedule: #{nx50["schedule"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            puts ""

            puts "access | note | [] | <datecode> | detach running | exit | completed | update description | update domain | update contents | update unixtime | update schedule | ordinal | destroy".yellow

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
                update = nil
                Axion::access(nx50["contentType"], nx50["contentPayload"], update)
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

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx50["description"])
                if description.size > 0 then
                    CatalystDatabase::updateDescription(nx50["uuid"], description)
                end
                next
            end

            if Interpreting::match("update domain", command) then
                domain = Domains::selectDomainOrNull()
                Domains::setDomainForItem(nx50["uuid"], domain)
                next
            end

            if Interpreting::match("update contents", command) then
                update = nil
                Axion::edit(nx50["contentType"], nx50["contentPayload"], update)
                next
            end

            if Interpreting::match("update unixtime", command) then
                domain = Domains::getDomainForItemOrNull(nx50["uuid"])
                nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull(domain) || Time.new.to_f)
                Nx31s::commitNx50ToDisk(nx50)
                next
            end

            if Interpreting::match("update schedule", command) then
                nx50["schedule"] = JSON.parse(Utils::editTextSynchronously(JSON.pretty_generate(nx50["schedule"])))
                Nx31s::commitNx50ToDisk(nx50)
                next
            end

            if Interpreting::match("ordinal", command) then
                WorkOrdering::resetOrdinal(nx50["uuid"], Nx50s::toString(nx50))
                break
            end

            if Interpreting::match("destroy", command) then
                Nx50s::complete(nx50)
                break
            end

            UIServices::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])
    end
    
    # Nx50s::maintenance()
    def self.maintenance()
        if Nx50s::nx50s().size <= 30 then
            Nx50s::quarks()
                .sample(20)
                .each{|item|
                    db = SQLite3::Database.new(CatalystDatabase::databaseFilepath())
                    db.busy_timeout = 117
                    db.busy_handler { |count| true }
                    db.transaction 
                    db.execute "update _catalyst_ set _catalystType_=? where _uuid_=?", ["Nx50", item["uuid"]]
                    db.commit 
                    db.close
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

            ns16s = Nx50s::nx50s()
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

            ns16s = Nx50s::nx50s()
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
        Nx50s::nx50s().map{|item|
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
