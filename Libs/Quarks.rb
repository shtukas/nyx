
# encoding: UTF-8

class L22X

    # L22X::l22ToFloat(l22)
    def self.l22ToFloat(l22)
        Time.strptime(l22[0, 15], '%Y%m%d-%H%M%S').to_i + "0.#{l22[16, 6]}".to_f
    end

    # L22X::floatToL22(float)
    def self.floatToL22(float)
        Time.at(float.to_i).strftime("%Y%m%d-%H%M%S") + "-#{("#{"%.6f" % (float-float.to_i)}")[2, 6].ljust(6, "0")}"
    end

    # L22X::middlePointOfTwoL22sOrNull(p1, p2)
    def self.middlePointOfTwoL22sOrNull(p1, p2)
        raise "ae294eb7-4a63-4c82-91a1-96ca58a04536" if p1 == p2

        float1 = L22X::l22ToFloat(p1)
        float2 = L22X::l22ToFloat(p2)

        float3 = (float1+float2).to_f/2

        p3 = L22X::floatToL22(float3)

        return nil if [p1, p2].include?(p3)

        p3
    end

    # L22X::newL22()
    def self.newL22()

        # l22s = Elbrams::marblesOfGivenDomainInOrder("quarks").map{|marble| File.basename(marble.filepath())[0, 22] }

        marbles = Elbrams::marblesOfGivenDomainInOrder("quarks")

        if marbles.size < 100 then # If we actually have less then 100 elements, we just return return the current time
            return LucilleCore::timeStringL22()
        end

        loop {
            break if marbles.size < 2
            m0 = marbles[0]
            m1 = marbles[1] 
            if (m0.getOrNull("blue-tag-2f45a660") or m1.getOrNull("blue-tag-2f45a660")) then
                marbles.shift
                next
            end
            p0 = File.basename(m0.filepath())[0, 22]
            p1 = File.basename(m1.filepath())[0, 22]
            l22 = L22X::middlePointOfTwoL22sOrNull(p0, p1)
            if l22 then
                filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{l22}.marble"
                if !File.exists?(filepath) then
                    return l22
                end
            end
            marbles.shift
        }

        LucilleCore::timeStringL22()
    end

    # L22X::findFreeToUseLowerL22(l22)
    def self.findFreeToUseLowerL22(l22)
        float1 = L22X::l22ToFloat(l22)
        ienum = LucilleCore::integerEnumerator()
        loop {
            float2 = float1 - ienum.next().to_f/1000
            l22 = L22X::floatToL22(float2)
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{l22}.marble"
            next if File.exists?(filepath)
            return l22
        }
    end
end

class Quarks

    # Quarks::applyBlueTagToFile(filepath)
    def self.applyBlueTagToFile(filepath)
        Elbrams::set(filepath, "blue-tag-2f45a660", "true")
        # system("xattr -wx com.apple.FinderInfo \"0000000000000000000900000000000000000000000000000000000000000000\" '#{filepath}'")
    end

    # Quarks::importLocationAsNewAionPointQuark(location)
    def self.importLocationAsNewAionPointQuark(location)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{L22X::newL22()}.marble"

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
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{L22X::newL22()}.marble"

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

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{L22X::newL22()}.marble"

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
            Elbrams::set(filepath, "air-traffic-control-agent", agent["uuid"])
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

    # Quarks::marbleToAgent(marble)
    def self.marbleToAgent(marble)
        agentuuid = Elbrams::getOrNull(marble.filepath(), "air-traffic-control-agent")
        AirTrafficControl::getAgentByIdOrNull(agentuuid) || AirTrafficControl::defaultAgent()
    end

    # Quarks::runQuark(marble)
    def self.runQuark(marble)

        filepath = marble.filepath()

        return if !marble.isStillAlive()

        uuid = Elbrams::get(filepath, "uuid")

        toString = Quarks::toString(marble)

        agent = Quarks::marbleToAgent(marble)

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

            agent = Quarks::marbleToAgent(marble)
            puts "@agent: #{agent["name"]}"

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
                next if agent.nil?
                Elbrams::set(filepath, "air-traffic-control-agent", agent["uuid"])
                return
            end

            if Interpreting::match("set dependency", command) then
                filepathx1 = Quarks::architechFilepathOrNull()
                return if filepathx1.nil?
                puts "Setting dependency on #{Elbrams::get(filepathx1, "description")}"
                uuidx = Elbrams::get(filepathx1, "uuid")
                return if uuidx == uuid
                Elbrams::set(filepath, "dependency", uuidx)
                # There is one more thing we need to do, and that is to move the architected marble (aka the dependency) before [this]
                filepathx2 = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/quarks/#{L22X::findFreeToUseLowerL22(File.basename(filepath)[0, 22])}.marble"
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
                agent = Quarks::marbleToAgent(marble)
                DetachedRunning::issueNew(uuid, Quarks::toString(marble), Time.new.to_i, [uuid, agent["uuid"]])
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

        puts "putting #{timespan} seconds to uuid: #{uuid} ; marble: #{toString}"
        Bank::put(uuid, timespan)

        puts "putting #{timespan} seconds to uuid: #{agent}"
        Bank::put(agent["uuid"], timespan)

        $counterx.registerTimeInSeconds(timespan)

        Elbrams::postAccessCleanUp(marble)

        Dispatch::send({
            "type"    => "c95462ff: quark has been accessed",
            "payload" => {
                "filepath" => filepath
            } 
        })
    end

    # Quarks::marbleToNS16(marble)
    def self.marbleToNS16(marble)
        filepath     = marble.filepath()
        uuid         = Elbrams::get(filepath, "uuid")
        description  = Elbrams::get(filepath, "description")
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        agent        = Quarks::marbleToAgent(marble)
        metricLevel, agentRecoveryTime = AirTrafficDataOperator::agentToMetricData(agent)

        announce     = "(#{agent["name"]}) #{description}"

        if marble.hasNote() then
            prefix = "              "
            announce = announce + "\n#{prefix}Note:\n" + marble.getNote().lines.map{|line| "#{prefix}#{line}"}.join()
        end

        recoveryTime > 0 ? recoveryTime : 0.4 # This means that zero elements, notably the new one, don't monopolise the feed

        {
            "uuid"     => uuid,
            "metric"   => [metricLevel, agentRecoveryTime, recoveryTime, nil],
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
            "x-source"       => "Quarks",
            "x-filepath"     => filepath,
            "x-recoveryTime" => recoveryTime,
            "x-agent"        => agent,
            "x-agent-metric-data" => AirTrafficDataOperator::agentToMetricData(agent)
        }
    end

    # Quarks::ns16s()
    def self.ns16s()
        AirTrafficControl::agentsOrderedByRecoveryTime().map{|agent|
            Quarks::firstNVisibleQuarks([10, Utils::screenHeight()].max)
                .select{|marble| (Elbrams::getOrNull(marble.filepath(), "air-traffic-control-agent") || "3AD70E36-826B-4958-95BF-02E12209C375") == agent["uuid"] }
                .first(3)
                .map {|marble| Quarks::marbleToNS16(marble) }
                .select{|item| !Quarks::marbleHasActiveDependencies(item["uuid"]) }
        }
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

$NS16sCached = nil

class QuarksOperator

    # QuarksOperator::ns16s()
    def self.ns16s()
        if $NS16sCached.nil? then
            $NS16sCached = Quarks::ns16s()
        end
        $NS16sCached
    end

    # QuarksOperator::removeItemIdentifiedByFilepath(filepath)
    def self.removeItemIdentifiedByFilepath(filepath)
        $NS16sCached = $NS16sCached.reject{|item| item["x-filepath"] == filepath }
    end
end

Dispatch::callback(lambda{|type, payload|
    if type == "c95462ff: quark has been accessed" then
        QuarksOperator::removeItemIdentifiedByFilepath(payload["filepath"])
    end
})

Thread.new {
    loop {
        sleep 600
        $NS16sCached = Quarks::ns16s()
    }
}
