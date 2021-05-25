
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

            puts "landing | update agent | set dependency | <datecode> | detach running | done | (empty) # default # exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("landing", command) then
                Quarks::landing(quark)
            end

            if Interpreting::match("update agent", command) then
                agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
                next if agent.nil?
                quark["air-traffic-control-agent"] = agent["uuid"]
                CoreDataTx::commit(quark)
                next
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

        puts "putting #{timespan} seconds to uuid: #{uuid} ; quark: #{Quarks::toString(quark)}"
        Bank::put(uuid, timespan)

        puts "putting #{timespan} seconds to uuid: #{agent}"
        Bank::put(agent["uuid"], timespan)

        $counterx.registerTimeInSeconds(timespan)

        Nx101::postAccessCleanUp(quark)
    end

    # Quarks::quarkToNS16(quark)
    def self.quarkToNS16(quark)
        uuid         = quark["uuid"]

        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        # To prevent endlessly focusing on new items
        if recoveryTime == 0 then
            Bank::put(uuid, rand*3600)
            recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        end

        agent        = Quarks::quarkToAgent(quark)

        announce     = "[qurk] (#{agent["name"]}) #{quark["description"]}"

        {
            "uuid"     => uuid,
            "metric"   => ["ns:zone", recoveryTime, nil],
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(quark) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(quark)}' ? ", true) then
                    CoreDataTx::delete(quark["uuid"])
                end
            },
            "x-source"       => "Quarks",
            "x-recoveryTime" => recoveryTime,
            "x-agent"        => agent
        }
    end

    # Quarks::ns16s()
    def self.ns16s()
        l1 = lambda{|agent, agentsuuids|

            cacheduuids = KeyValueStore::getOrNull(nil, "f56a2ee4-385a-4647-821e-b66c89c93cb8:#{agent["uuid"]}:#{Time.new.to_s[0, 13]}")
            if cacheduuids then
                cacheduuids = JSON.parse(cacheduuids)
                quarks = cacheduuids
                            .map{|uuid| CoreDataTx::getObjectByIdOrNull(uuid) }
                            .compact
                            .select{|quark| DoNotShowUntil::isVisible(quark["uuid"]) }
                if quarks.size == 3 then
                    return quarks
                end
            end

            quarks = Quarks::quarks()
                        .map{|quark|
                            if (quark["air-traffic-control-agent"].nil? or !agentsuuids.include?(quark["air-traffic-control-agent"])) then
                                quark["air-traffic-control-agent"] = "3AD70E36-826B-4958-95BF-02E12209C375"
                            end
                            quark
                        }
                        .select{|quark| quark["air-traffic-control-agent"] == agent["uuid"] }
                        .select{|quark| DoNotShowUntil::isVisible(quark["uuid"]) }
                        .first(3)

            cacheduuids = quarks.map{|quark| quark["uuid"] }
            KeyValueStore::set(nil, "f56a2ee4-385a-4647-821e-b66c89c93cb8:#{agent["uuid"]}:#{Time.new.to_s[0, 13]}", JSON.generate(cacheduuids))
            quarks
        }

        l3 = lambda{

            # Here we get the end of the stream
            cacheduuids = KeyValueStore::getOrNull(nil, "69fe83c5-479d-46da-ae0c-921e9941a154:#{Time.new.to_s[0, 13]}")
            if cacheduuids then
                cacheduuids = JSON.parse(cacheduuids)
                quarks = cacheduuids
                            .map{|uuid| CoreDataTx::getObjectByIdOrNull(uuid) }
                            .compact
                            .select{|quark| DoNotShowUntil::isVisible(quark["uuid"]) }
                if quarks.size == 3 then
                    return quarks
                end
            end

            quarks = Quarks::quarks().reverse.first(3)

            cacheduuids = quarks.map{|quark| quark["uuid"] }
            KeyValueStore::set(nil, "69fe83c5-479d-46da-ae0c-921e9941a154:#{Time.new.to_s[0, 13]}", JSON.generate(cacheduuids))
            quarks
        }

        agents = AirTrafficControl::agents()
        agentsuuids = agents.map{|a| a["uuid"] }

        n1 = agents.map{|agent| l1.call(agent, agentsuuids)}.flatten
        n3 = l3.call()

        (n1 + n3)
            .reduce([]){|selected, quark|
                if selected.none?{|q| q["uuid"] == quark["uuid"] } then
                    selected + [quark]
                else
                    selected
                end
            }
            .map{|quark| Quarks::quarkToNS16(quark) }
    end

    # --------------------------------------------------

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            puts Quarks::toString(quark)
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
                Nx101::access(quark)
            end

            if Interpreting::match("edit", command) then
                Nx101::edit(quark)
            end

            if Interpreting::match("transmute", command) then
                Nx101::transmute(quark)
            end

            if Interpreting::match("destroy", command) then
                CoreDataTx::delete(quark["uuid"])
                break
            end
        }
    end
end