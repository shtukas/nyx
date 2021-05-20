
# encoding: UTF-8

class L22Extentions

    # L22Extentions::l22ToFloat(l22)
    def self.l22ToFloat(l22)
        Time.strptime(l22[0, 15], '%Y%m%d-%H%M%S').to_i + "0.#{l22[16, 6]}".to_f
    end

    # L22Extentions::floatToL22(float)
    def self.floatToL22(float)
        Time.at(float.to_i).strftime("%Y%m%d-%H%M%S") + "-#{("#{"%.6f" % (float-float.to_i)}")[2, 6].ljust(6, "0")}"
    end
end

class QuarkPlacementManagement

    # QuarkPlacementManagement::middlePointOfTwoL22sOrNull(p1, p2)
    def self.middlePointOfTwoL22sOrNull(p1, p2)
        raise "ae294eb7-4a63-4c82-91a1-96ca58a04536" if p1 == p2

        float1 = L22Extentions::l22ToFloat(p1)
        float2 = L22Extentions::l22ToFloat(p2)

        float3 = (float1+float2).to_f/2

        p3 = L22Extentions::floatToL22(float3)

        return nil if [p1, p2].include?(p3)

        p3
    end

    # QuarkPlacementManagement::newL22()
    def self.newL22()

        l22s = Elbrams::marblesOfGivenDomainInOrder("quarks").map{|marble| File.basename(marble.filepath())[0, 22] }
        
        if l22s.size < 100 then # If we actually have less then 100 elements, we just return return the current time
            return LucilleCore::timeStringL22()
        end

        unixtime = 1621462757 # 2021-05-19 23:19:17 +0100
        alpha = 1.to_f/(Math::PI/2) * Math.atan( (Time.new.to_f - unixtime) * 1.to_f/(86400*365) )

        # alpha increases from 0 to 1 asymptotically starting at unixtime
  
        base = (1-alpha) * L22Extentions::l22ToFloat(l22s[0]) + alpha * L22Extentions::l22ToFloat(l22s[-1])

        ienum = LucilleCore::integerEnumerator()

        loop {
            l22 = L22Extentions::floatToL22(base+ienum.next().to_f/1000)
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{l22}.marble"
            next if File.exists?(filepath)
            return l22
        }
    end

    # QuarkPlacementManagement::findFreeToUseLowerL22(l22)
    def self.findFreeToUseLowerL22(l22)
        float1 = L22Extentions::l22ToFloat(l22)
        ienum = LucilleCore::integerEnumerator()
        loop {
            float2 = float1 - ienum.next().to_f/1000
            l22 = L22Extentions::floatToL22(float2)
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{l22}.marble"
            next if File.exists?(filepath)
            return l22
        }
    end
end

class Quarks

    # Quarks::applyBlueTagToFile(filepath)
    def self.applyBlueTagToFile(filepath)
        system("xattr -wx com.apple.FinderInfo \"0000000000000000000900000000000000000000000000000000000000000000\" '#{filepath}'")
    end

    # Quarks::importLocationAsNewAionPointQuark(location)
    def self.importLocationAsNewAionPointQuark(location)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{QuarkPlacementManagement::newL22()}.marble"

        Elbrams::issueNewEmptyElbram(filepath)

        Quarks::applyBlueTagToFile(filepath)

        uuid = SecureRandom.uuid

        Elbrams::set(filepath, "uuid", uuid)
        Elbrams::set(filepath, "unixtime", Time.new.to_i)
        Elbrams::set(filepath, "domain", "quarks")

        description = File.basename(location) 
        Elbrams::set(filepath, "description", description)

        Elbrams::set(filepath, "type", "AionPoint")

        payload = AionCore::commitLocationReturnHash(ElbramElizabeth.new(filepath), location)
        Elbrams::set(filepath, "payload", payload)
    end

    # Quarks::importURLAsNewURLQuark(url)
    def self.importURLAsNewURLQuark(url)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{QuarkPlacementManagement::newL22()}.marble"

        Elbrams::issueNewEmptyElbram(filepath)

        Quarks::applyBlueTagToFile(filepath)

        uuid = SecureRandom.uuid

        Elbrams::set(filepath, "uuid", uuid)
        Elbrams::set(filepath, "unixtime", Time.new.to_i)
        Elbrams::set(filepath, "domain", "quarks")
        Elbrams::set(filepath, "description", url)

        Elbrams::set(filepath, "type", "Url")
        Elbrams::set(filepath, "payload", url)
    end

    # Quarks::interactivelyIssueNewElbramQuarkOrNullAtLowL22()
    def self.interactivelyIssueNewElbramQuarkOrNullAtLowL22()

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{QuarkPlacementManagement::newL22()}.marble"

        raise "[error: e7ed22f0-9962-472d-907f-419916d224ee]" if File.exists?(filepath)

        Elbrams::issueNewEmptyElbram(filepath)

        Quarks::applyBlueTagToFile(filepath)

        uuid = SecureRandom.uuid

        Elbrams::set(filepath, "uuid", uuid)
        Elbrams::set(filepath, "unixtime", Time.new.to_i)
        Elbrams::set(filepath, "domain", "quarks")

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end  
        Elbrams::set(filepath, "description", description)

        agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
        if agent then
            agent["itemsuids"] << uuid
            AirTrafficControl::commitAgentToDisk(agent)
        end

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])

        if type.nil? then
            FileUtils.rm(filepath)
            return nil
        end  

        if type == "Line" then
            Elbrams::set(filepath, "type", "Line")
            Elbrams::set(filepath, "payload", "")
        end
        if type == "Url" then
            Elbrams::set(filepath, "type", "Url")

            url = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if url == "" then
                FileUtils.rm(filepath)
                return nil
            end  
            Elbrams::set(filepath, "payload", url)
        end
        if type == "Text" then
            Elbrams::set(filepath, "type", "Text")
            text = Utils::editTextSynchronously("")
            payload = ElbramElizabeth.new(filepath).commitBlob(text)
            Elbrams::set(filepath, "payload", payload)
        end
        if type == "ClickableType" then
            Elbrams::set(filepath, "type", "ClickableType")
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(f1) or !File.file?(f1) then
                FileUtils.rm(filepath)
                return nil
            end
            nhash = ElbramElizabeth.new(filepath).commitBlob(IO.read(f1)) # bad choice, this file could be large
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            Elbrams::set(filepath, "payload", payload)
        end
        if type == "AionPoint" then
            Elbrams::set(filepath, "type", "AionPoint")
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                FileUtils.rm(location)
                return nil
            end
            payload = AionCore::commitLocationReturnHash(ElbramElizabeth.new(filepath), location)
            Elbrams::set(filepath, "payload", payload)
        end
        filepath
    end

    # Quarks::architechFilepathOrNull()
    def self.architechFilepathOrNull()
        marbles = Quarks::firstNVisibleQuarks(Utils::screenHeight()-3)
        marble = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", marbles, lambda { |marble| Quarks::toString(marble) })
        return marble.filepath() if marble
        Quarks::interactivelyIssueNewElbramQuarkOrNullAtLowL22()
    end

    # --------------------------------------------------

    # Quarks::toString(marble)
    def self.toString(marble)
        filepath = marble.filepath()
        "[quark] #{Elbrams::get(filepath, "description")}"
    end

    # Quarks::firstNQuarks(resultSize)
    def self.firstNQuarks(resultSize)
        Elbrams::marblesOfGivenDomainInOrder("quarks").reduce([]) {|selected, marble|
            if selected.size >= resultSize then
                selected
            else
                selected + [marble] 
            end
        }
    end

    # Quarks::firstNVisibleQuarks(resultSize)
    def self.firstNVisibleQuarks(resultSize)
        Elbrams::marblesOfGivenDomainInOrder("quarks").reduce([]) {|selected, marble|
            filepath = marble.filepath()
            if selected.size >= resultSize then
                selected
            else
                if (DoNotShowUntil::isVisible(Elbrams::get(filepath, "uuid"))) then
                    selected + [marble]
                else
                    selected
                end 
            end
        }
    end

    # Quarks::marbleHasActiveDependencies(uuid)
    def self.marbleHasActiveDependencies(uuid)
        # Let's pickup any possible dependency
        filepath = Elbrams::getFilepathByIdAtDomainOrNull("quarks", uuid)
        raise "495ec4cf-aea7-4666-a609-6559c7a5d3d3" if filepath.nil?
        uuidx = Elbrams::getOrNull(filepath, "dependency")
        return false if uuidx.nil?
        !Elbrams::getFilepathByIdAtDomainOrNull("quarks", uuidx).nil? # retrn true if a file for this uuidx was found
    end

    # --------------------------------------------------

    # Quarks::runQuark(marble)
    def self.runQuark(marble)

        filepath = marble.filepath()

        return if !marble.isStillAlive()

        uuid = Elbrams::get(filepath, "uuid")
        toString = Quarks::toString(marble)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Elbram quark running for more than an hour")
                sleep 60
            }
        }

        system("clear")
        puts "running: #{Quarks::toString(marble)}"
        Elbrams::access(marble)

        loop {

            system("clear")

            return if !marble.isStillAlive()

            puts "running: #{Quarks::toString(marble)}"

            AirTrafficControl::agentsForUUID(uuid).each{|agent|
                puts "@agent: #{agent["name"]}"
            }
            if Elbrams::getOrNull(filepath, "dependency") then
                uuidx = Elbrams::getOrNull(filepath, "dependency")
                filepathx = Elbrams::getFilepathByIdAtDomainOrNull("quarks", uuidx)
                if filepathx then
                    puts "Dependency: #{Elbrams::getOrNull(filepathx, "description")}"
                end
            end

            if marble.getNote().size > 0 then
                puts ""
                puts "Note:"
                puts marble.getNote()
                puts ""
            end

            puts "landing | edit note | update agent | set dependency | ++ # Postpone marble by an hour | + <weekday> # Postpone marble | + <float> <datecode unit> # Postpone marble | detach running | done | (empty) # default # exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("landing", command) then
                Quarks::landing(marble)
            end

            if Interpreting::match("edit note", command) then
                marble.editNote()
            end

            if Interpreting::match("update agent", command) then
                agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
                if agent then
                    agent["itemsuids"] << uuid
                    AirTrafficControl::commitAgentToDisk(agent)
                    AirTrafficControl::agents().each{|a|
                        next if a["uuid"] == agent["uuid"]
                        next if !a["itemsuids"].include?(uuid)
                        a["itemsuids"] = a["itemsuids"] - [uuid]
                        AirTrafficControl::commitAgentToDisk(a)
                    }
                end
            end

            if Interpreting::match("set dependency", command) then
                filepathx1 = Quarks::architechFilepathOrNull()
                return if filepathx1.nil?
                puts "Setting dependency on #{Elbrams::get(filepathx1, "description")}"
                uuidx = Elbrams::get(filepathx1, "uuid")
                return if uuidx == uuid
                Elbrams::set(filepath, "dependency", uuidx)
                # There is one more thing we need to do, and that is to move the architected marble (aka the dependency) before [this]
                filepathx2 = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{QuarkPlacementManagement::findFreeToUseLowerL22(File.basename(filepath)[0, 22])}.marble"
                puts "moving marble:"
                puts "    #{filepathx1}"
                puts "    #{filepathx2}"
                FileUtils.mv(filepathx1, filepathx2)
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(Elbrams::get(filepath, "uuid"), Time.new.to_i+3600)
                break
            end

            if Interpreting::match("+ *", command) then
                _, input = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(Elbrams::get(filepath, "uuid"), unixtime)
                break
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(Elbrams::get(filepath, "uuid"), unixtime)
                break
            end

            if Interpreting::match("detach running", command) then
                bankAccounts = []
                bankAccounts << uuid
                AirTrafficControl::agentsForUUID(uuid).each{|agent|
                    bankAccounts << agent["uuid"]
                }
                DetachedRunning::issueNew(uuid, Quarks::toString(marble), Time.new.to_i, bankAccounts)
                break
            end

            if Interpreting::match("done", command) then
                if marble.getNote().size > 0 then
                    puts "You can't delete a quark with  non empty note"
                    LucilleCore::pressEnterToContinue()
                else
                    Elbrams::postAccessCleanUp(marble) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                    marble.destroy()
                end
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

        AirTrafficControl::agentsForUUID(uuid).each{|agent|
            puts "putting #{timespan} seconds into agent '#{agent["name"]}'"
            Bank::put(agent["uuid"], timespan)
        }

        puts "putting #{timespan} seconds to uuid: #{uuid} ; marble: #{toString}"
        Bank::put(uuid, timespan)

        Elbrams::postAccessCleanUp(marble)
    end

    # Quarks::marbleToNS16(marble)
    def self.marbleToNS16(marble)

        filepath     = marble.filepath()
        uuid         = Elbrams::get(filepath, "uuid")
        description  = Elbrams::get(filepath, "description")
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        numbersX     = (recoveryTime > 0) ? "(#{"%5.3f" % recoveryTime}) " : "        "
        announce     = "#{numbersX}#{description}"
        
        if marble.hasNote() then
            prefix = "              "
            announce = announce + "\n#{prefix}Note:\n" + marble.getNote().lines.map{|line| "#{prefix}#{line}"}.join()
        end
        
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(marble) },
            "done"     => lambda{
                if marble.hasNote() or marble.get("type") != "Line" then
                    puts "You cannot listing done this quark"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(marble)}' ? ", true) then
                    marble.destroy()
                end
            },
            "recoveryTime" => recoveryTime
        }
    end

    # Quarks::ns16s()
    def self.ns16s()
        Quarks::firstNVisibleQuarks([10, Utils::screenHeight()].max)
            .map {|marble| Quarks::marbleToNS16(marble) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) and !Quarks::marbleHasActiveDependencies(item["uuid"]) }
    end

    # Quarks::ns17s()
    def self.ns17s()
        Quarks::ns16s().map{|x| 
            x["recoveryTime"] = BankExtended::stdRecoveredDailyTimeInHours(x["uuid"])
            x
        }
    end

    # Quarks::airTrafficControlAgentToNS20OrNull(agent, agents, ns17s)
    def self.airTrafficControlAgentToNS20OrNull(agent, agents, ns17s)

        ns17s =
            if agent["uuid"] == "3AD70E36-826B-4958-95BF-02E12209C375" then
                # We collect the ns17s with are not in any agent
                ns17s.select{|ns17| agents.none?{|ag| ag["itemsuids"].include?(ns17["uuid"]) } }
            else
                # We collect the ns17s which are in this agent
                ns17s.select{|ns17| agent["itemsuids"].include?(ns17["uuid"]) }
            end

        return nil if ns17s.empty?

        if !AirTrafficControl::processingStyles().include?(agent["processingStyle"]) then
            puts JSON.pretty_generate(agent)
            raise "5da5d984-7d27-49b1-946f-0780fefa0b71"
        end

        if agent["processingStyle"] == "Sequential" then
            # Nothing to do
        end
        if agent["processingStyle"] == "FirstThreeCompeting" then
            ns17s = ns17s.first(3).sort{|x1, x2| x1["recoveryTime"] <=> x2["recoveryTime"] } + ns17s.drop(3)
        end
        if agent["processingStyle"] == "AllCompetings" then
            ns17s = ns17s.sort{|x1, x2| x1["recoveryTime"] <=> x2["recoveryTime"] } 
        end

        {
            "announce"     => agent["name"],
            "recoveryTime" => BankExtended::stdRecoveredDailyTimeInHours(agent["uuid"]),
            "ns16s"        => ns17s
        }
    end

    # Quarks::ns20s()
    def self.ns20s()
        agents = AirTrafficControl::agents()
        ns17s = Quarks::ns17s()
        agents.map{|agent| Quarks::airTrafficControlAgentToNS20OrNull(agent, agents, ns17s)}.compact
    end

    # --------------------------------------------------

    # Quarks::landing(marble)
    def self.landing(marble)
        filepath = marble.filepath()
        loop {

            return if !marble.isStillAlive()

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(marble)
            puts "uuid: #{Elbrams::get(filepath, "uuid")}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(Elbrams::get(filepath, "uuid"))
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(Elbrams::get(filepath, "uuid"))}".yellow

            puts ""

            mx.item("access (partial edit)".yellow,lambda { 
                Elbrams::access(marble)
            })

            mx.item("edit".yellow, lambda {
                Elbrams::edit(marble)
            })

            mx.item("transmute".yellow, lambda { 
                Elbrams::transmute(marble)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this marble and its content? ") then
                    marble.destroy()
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
