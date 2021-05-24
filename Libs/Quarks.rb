
# encoding: UTF-8

class Quarks

    # Quarks::importLocationAsNewAionPointQuark(location)
    def self.importLocationAsNewAionPointQuark(location)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "quark"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = File.basename(location) 
        quark["contentType"] = "AionPoint"
        quark["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(quark)
    end

    # Quarks::importURLAsNewURLQuark(url)
    def self.importURLAsNewURLQuark(url)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "quark"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = url
        quark["contentType"] = "Url"
        quark["payload"]     = url

        CoreDataTx::commit(quark)
    end

    # Quarks::interactivelyIssueNewQuarkOrNull()
    def self.interactivelyIssueNewQuarkOrNull()
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "quark"
        quark["unixtime"]    = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end  
        quark["description"] = description

        agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
        if agent then
            quark["air-traffic-control-agent"] = agent["uuid"]
        end

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])

        if type.nil? then
            return nil
        end  

        if type == "Line" then
            quark["contentType"] = "Line"
            quark["payload"]     = ""
        end

        if type == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if url == "" then
                return nil
            end
            quark["contentType"] = "Url"
            quark["payload"]     = url
        end

        if type == "Text" then
            text = Utils::editTextSynchronously("")
            quark["contentType"] = "Text"
            quark["payload"]     = BinaryBlobsService::putBlob(text)
        end

        if type == "ClickableType" then
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(f1) or !File.file?(f1) then
                return nil
            end
            nhash = BinaryBlobsService::putBlob(IO.read(f1))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            quark["contentType"] = "ClickableType"
            quark["payload"]     = payload
        end

        if type == "AionPoint" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                return nil
            end
            quark["contentType"] = "AionPoint"
            quark["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)
        end


        CoreDataTx::commit(quark)
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{quark["description"]}"
    end

    # Quarks::quarks()
    def self.quarks()
        CoreDataTx::getObjectsBySchema("quark")
    end

    # --------------------------------------------------

    # Quarks::quarkToAgent(quark)
    def self.quarkToAgent(quark)
        agentuuid = quark["air-traffic-control-agent"]
        return AirTrafficControl::defaultAgent() if agentuuid.nil?
        AirTrafficControl::getAgentByIdOrNull(agentuuid) || AirTrafficControl::defaultAgent()
    end

    # Quarks::runQuark(quark)
    def self.runQuark(quark)

        uuid = quark["uuid"]

        toString = Quarks::toString(quark)

        agent = Quarks::quarkToAgent(quark)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Quark running for more than an hour")
                sleep 60
            }
        }

        system("clear")
        puts Quarks::toString(quark)
        Nx101::access(quark)

        loop {

            return if CoreDataTx::getObjectByIdOrNull(quark["uuid"]).nil?

            system("clear")

            puts Quarks::toString(quark)

            agent = Quarks::quarkToAgent(quark)
            puts "@agent: #{agent["name"]}"

            puts "landing | update agent | set dependency | ++ # Postpone quark by an hour | + <weekday> # Postpone quark | + <float> <datecode unit> # Postpone quark | detach running | done | (empty) # default # exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("landing", command) then
                Quarks::landing(quark)
            end

            if Interpreting::match("update agent", command) then
                agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
                next if agent.nil?
                quark["air-traffic-control-agent"] = agent["uuid"]
                CoreDataTx::commit(object)
                return
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(quark["uuid"], Time.new.to_i+3600)
                break
            end

            if Interpreting::match("+ *", command) then
                _, input = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("detach running", command) then
                agent = Quarks::quarkToAgent(quark)
                DetachedRunning::issueNew(uuid, Quarks::toString(quark), Time.new.to_i, [uuid, agent["uuid"]])
                break
            end

            if Interpreting::match("done", command) then
                Nx101::postAccessCleanUp(quark)
                CoreDataTx::delete(quark["uuid"])
                $counterx.registerDone()
                break
            end

            if Interpreting::match("", command) then
                break
            end
        }

        thr.exit

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to uuid: #{uuid} ; quark: #{toString}"
        Bank::put(uuid, timespan)

        puts "putting #{timespan} seconds to uuid: #{agent}"
        Bank::put(agent["uuid"], timespan)

        $counterx.registerTimeInSeconds(timespan)

        Nx101::postAccessCleanUp(quark)
    end

    # Quarks::quarkToNS16(quark)
    def self.quarkToNS16(quark)
        uuid         = quark["uuid"]
        description  = quark["description"]
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        agent        = Quarks::quarkToAgent(quark)
        metricLevel, agentRecoveryTime = AirTrafficDataOperator::agentToMetricData(agent)

        announce     = "[qurk] (#{agent["name"]}) #{description}"

        recoveryTime = (recoveryTime > 0) ? recoveryTime : 0.4 # This means that zero elements, notably the new ones, don't monopolise the feed

        {
            "uuid"     => uuid,
            "metric"   => [metricLevel, agentRecoveryTime, recoveryTime, nil],
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(quark) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(quark)}' ? ", true) then
                    quark.destroy()
                end
            },
            "x-source"       => "Quarks",
            "x-recoveryTime" => recoveryTime,
            "x-agent"        => agent,
            "x-agent-metric-data" => AirTrafficDataOperator::agentToMetricData(agent)
        }
    end

    # Quarks::ns16s()
    def self.ns16s()
        l1 = lambda{|agent|
            cacheduuids = KeyValueStore::getOrNull(nil, "f56a2ee4-385a-4647-821e-b66c89c93cb7:#{agent["uuid"]}:#{Time.new.to_s[0, 13]}")
            if cacheduuids then
                cacheduuids = JSON.parse(cacheduuids)
                return cacheduuids.map{|uuid| CoreDataTx::getObjectByIdOrNull(uuid) }.compact
            end

            quarks = Quarks::quarks()
                        .select{|quark| (agent["uuid"] == "3AD70E36-826B-4958-95BF-02E12209C375" and quark["air-traffic-control-agent"].nil?) or (quark["air-traffic-control-agent"] == agent["uuid"]) }
            quarks = quarks.first(16)
            cacheduuids = quarks.map{|quark| quark["uuid"] }
            KeyValueStore::set(nil, "f56a2ee4-385a-4647-821e-b66c89c93cb7:#{agent["uuid"]}:#{Time.new.to_s[0, 13]}", JSON.generate(cacheduuids))
            quarks
        }

        AirTrafficControl::agentsOrderedByRecoveryTime().map{|agent|
            l1.call(agent)
                .select{|quark| DoNotShowUntil::isVisible(quark["uuid"]) }
                .first(3)
                .map {|quark| Quarks::quarkToNS16(quark) }
        }
        .flatten
    end

    # --------------------------------------------------

    # Quarks::landing(quark)
    def self.landing(quark)

        loop {

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts ""

            mx.item("access (partial edit)".yellow,lambda { 
                Nx101::access(quark)
            })

            mx.item("edit".yellow, lambda {
                Nx101::edit(quark)
            })

            mx.item("transmute".yellow, lambda { 
                Nx101::transmute(quark)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this quark and its content? ") then
                    CoreDataTx::delete(quark["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end