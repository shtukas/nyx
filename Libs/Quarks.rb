
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



class Quarks

    # Quarks::middlePointOfTwoL22sOrNull(p1, p2)
    def self.middlePointOfTwoL22sOrNull(p1, p2)
        raise "ae294eb7-4a63-4c82-91a1-96ca58a04536" if p1 == p2

        float1 = L22Extentions::l22ToFloat(p1)
        float2 = L22Extentions::l22ToFloat(p2)

        float3 = (float1+float2).to_f/2

        p3 = L22Extentions::floatToL22(float3)

        return nil if [p1, p2].include?(p3)

        p3
    end

    # Quarks::computeLowL22()
    def self.computeLowL22()
        marbles = Marbles::marblesOfGivenDomainInOrder("quarks")
        if marbles.size < 21 then
            return LucilleCore::timeStringL22()
        end

        l22s = marbles.drop(19).take(2).map{|marble| File.basename(marble.filepath())[0, 22] }
        l22 = Quarks::middlePointOfTwoL22sOrNull(l22s[0], l22s[1])
        return l22 if l22

        # let's make some space

        Marbles::marblesOfGivenDomainInOrder("quarks").take(20).each{|marble|
            filepath1 = marble.filepath()
            x1 = File.basename(filepath1)[0, 4]
            x2 = ((x1.to_i)-1).to_s
            filepath2 = "#{File.dirname(filepath1)}/#{x2}#{File.basename(filepath1)[4, 99]}"
            FileUtils.mv(filepath1, filepath2)
        }

        # Now having some space, let's recompute

        marbles = Marbles::marblesOfGivenDomainInOrder("quarks")
        l22s = marbles.drop(19).take(2).map{|marble| File.basename(marble.filepath())[0, 22] }
        l22 = Quarks::middlePointOfTwoL22sOrNull(l22s[0], l22s[1])
        raise "5802573f-2248-4c04-8915-b025d3ebdc02" if l22.nil? # this is not supposed to fire

        l22
    end

    # Quarks::computeLowerL22(l22)
    def self.computeLowerL22(l22)
        float1 = L22Extentions::l22ToFloat(l22)
        cursor = 0
        loop {
            cursor = cursor + 1
            floatx = float1 - cursor
            l22x = L22Extentions::floatToL22(floatx)
            filepathx = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{l22x}.marble"
            next if File.exists?(filepathx)
            return l22x
        }
    end

    # Quarks::interactivelyIssueNewMarbleQuarkOrNull()
    def self.interactivelyIssueNewMarbleQuarkOrNull()

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{Quarks::computeLowL22()}.marble"

        raise "[error: e7ed22f0-9962-472d-907f-419916d224ee]" if File.exists?(filepath)

        Marbles::issueNewEmptyMarble(filepath)

        uuid = SecureRandom.uuid

        Marbles::set(filepath, "uuid", uuid)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "domain", "quarks")

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end  
        Marbles::set(filepath, "description", description)

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
            Marbles::set(filepath, "type", "Line")
            Marbles::set(filepath, "payload", "")
        end
        if type == "Url" then
            Marbles::set(filepath, "type", "Url")

            url = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if url == "" then
                FileUtils.rm(filepath)
                return nil
            end  
            Marbles::set(filepath, "payload", url)
        end
        if type == "Text" then
            Marbles::set(filepath, "type", "Text")
            text = Utils::editTextSynchronously("")
            payload = MarbleElizabeth.new(filepath).commitBlob(text)
            Marbles::set(filepath, "payload", payload)
        end
        if type == "ClickableType" then
            Marbles::set(filepath, "type", "ClickableType")
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(f1) or !File.file?(f1) then
                FileUtils.rm(filepath)
                return nil
            end
            nhash = MarbleElizabeth.new(filepath).commitBlob(IO.read(f1)) # bad choice, this file could be large
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            Marbles::set(filepath, "payload", payload)
        end
        if type == "AionPoint" then
            Marbles::set(filepath, "type", "AionPoint")
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                FileUtils.rm(location)
                return nil
            end
            payload = AionCore::commitLocationReturnHash(MarbleElizabeth.new(filepath), location)
            Marbles::set(filepath, "payload", payload)
        end
        filepath
    end

    # Quarks::architechFilepathOrNull()
    def self.architechFilepathOrNull()
        marbles = Quarks::firstNVisibleMarbleQuarks(Utils::screenHeight()-3)
        marble = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", marbles, lambda { |marble| Quarks::toString(marble) })
        return marble.filepath() if marble
        Quarks::interactivelyIssueNewMarbleQuarkOrNull()
    end

    # --------------------------------------------------

    # Quarks::toString(marble)
    def self.toString(marble)
        filepath = marble.filepath()
        "[quark] #{Marbles::get(filepath, "description")}"
    end

    # Quarks::marbleHasActiveDependencies(uuid)
    def self.marbleHasActiveDependencies(uuid)
        # Let's pickup any possible dependency
        filepath = Marbles::getFilepathByIdAtDomainOrNull("quarks", uuid)
        raise "495ec4cf-aea7-4666-a609-6559c7a5d3d3" if filepath.nil?
        uuidx = Marbles::getOrNull(filepath, "dependency")
        return false if uuidx.nil?
        !Marbles::getFilepathByIdAtDomainOrNull("quarks", uuidx).nil? # retrn true if a file for this uuidx was found
    end

    # --------------------------------------------------

    # Quarks::landing(marble)
    def self.landing(marble)
        filepath = marble.filepath()
        loop {

            return if !marble.isStillAlive()

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(marble)
            puts "uuid: #{Marbles::get(filepath, "uuid")}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(Marbles::get(filepath, "uuid"))
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(Marbles::get(filepath, "uuid"))}".yellow

            puts ""

            mx.item("access (partial edit)".yellow,lambda { 
                Marbles::access(marble)
            })

            mx.item("edit".yellow, lambda {
                Marbles::edit(marble)
            })

            mx.item("transmute".yellow, lambda { 
                Marbles::transmute(marble)
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

    # Quarks::marbleToNS16(marble indx = nil)
    def self.marbleToNS16(marble, indx = nil)
        toAnnounce = lambda {|marble|
            filepath = marble.filepath()
            rt = BankExtended::stdRecoveredDailyTimeInHours(Marbles::get(filepath, "uuid"))
            numbers = (rt > 0) ? "(#{"%5.3f" % BankExtended::stdRecoveredDailyTimeInHours(Marbles::get(filepath, "uuid"))}) " : "        "
            "#{numbers}#{Marbles::get(filepath, "description")}"
        }

        filepath = marble.filepath()
        announce = "#{toAnnounce.call(marble)}"
        
        if marble.hasNote() then
            prefix = "              "
            announce = announce + "\n#{prefix}Note:\n" + marble.getNote().lines.map{|line| "#{prefix}#{line}"}.join()
        end
        
        {
            "uuid"     => Marbles::get(filepath, "uuid"),
            "announce" => announce,
            "start"    => lambda{ Quarks::runMarbleQuark(marble) },
            "done"     => lambda{
                if marble.hasNote() or marble.get("type") != "Line" then
                    puts "You cannot listing done this quark"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(marble)}' ? ", true) then
                    marble.destroy()
                end
            }
        }
    end

    # Quarks::ns16s()
    def self.ns16s()
        Quarks::firstNVisibleMarbleQuarks([10, Utils::screenHeight()].max)
            .map
            .with_index{|marble, indx| Quarks::marbleToNS16(marble, indx) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) and !Quarks::marbleHasActiveDependencies(item["uuid"]) }
    end

    # Quarks::ns16ToNS17(ns16)
    def self.ns16ToNS17(ns16)
        {
            "uuid" => ns16["uuid"],
            "ns16" => ns16,
            "rt"   => BankExtended::stdRecoveredDailyTimeInHours(ns16["uuid"])
        }
    end

    # Quarks::ns17s()
    def self.ns17s()
        Quarks::ns16s().map{|ns16| Quarks::ns16ToNS17(ns16) }
    end

    # Quarks::runMarbleQuark(marble)
    def self.runMarbleQuark(marble)

        filepath = marble.filepath()

        return if !marble.isStillAlive()

        uuid = Marbles::get(filepath, "uuid")
        toString = Quarks::toString(marble)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Marble quark running for more than an hour")
                sleep 60
            }
        }

        system("clear")
        puts "running: #{Quarks::toString(marble)}"
        Marbles::access(marble)

        loop {

            system("clear")

            return if !marble.isStillAlive()

            puts "running: #{Quarks::toString(marble)}"

            AirTrafficControl::agentsForUUID(uuid).each{|agent|
                puts "@agent: #{agent["name"]}"
            }
            if Marbles::getOrNull(filepath, "dependency") then
                uuidx = Marbles::getOrNull(filepath, "dependency")
                filepathx = Marbles::getFilepathByIdAtDomainOrNull("quarks", uuidx)
                if filepathx then
                    puts "Dependency: #{Marbles::getOrNull(filepathx, "description")}"
                end
            end

            if marble.getNote().size > 0 then
                puts ""
                puts "Note:"
                puts marble.getNote()
                puts ""
            end

            puts "landing | edit note | update agent | set dependency | ++ # Postpone marble by an hour | + <weekday> # Postpone marble | + <float> <datecode unit> # Postpone marble | done | (empty) # default # exit".yellow

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
                puts "Setting dependency on #{Marbles::get(filepathx1, "description")}"
                uuidx = Marbles::get(filepathx1, "uuid")
                return if uuidx == uuid
                Marbles::set(filepath, "dependency", uuidx)
                # There is one more thing we need to do, and that is to move the architected marble (aka the dependency) before [this]
                filepathx2 = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{Quarks::computeLowerL22(File.basename(filepath)[0, 22])}.marble"
                puts "moving marbe:"
                puts "    #{filepathx1}"
                puts "    #{filepathx2}"
                FileUtils.mv(filepathx1, filepathx2)
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(Marbles::get(filepath, "uuid"), Time.new.to_i+3600)
                break
            end

            if Interpreting::match("+ *", command) then
                _, input = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(Marbles::get(filepath, "uuid"), unixtime)
                break
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(Marbles::get(filepath, "uuid"), unixtime)
                break
            end

            if Interpreting::match("done", command) then
                if marble.getNote().size > 0 then
                    puts "You can't delete a quark with  non empty note"
                    LucilleCore::pressEnterToContinue()
                else
                    Marbles::postAccessCleanUp(marble) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
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

        Marbles::postAccessCleanUp(marble)
    end

    # Quarks::firstNMarbleQuarks(resultSize)
    def self.firstNMarbleQuarks(resultSize)
        Marbles::marblesOfGivenDomainInOrder("quarks").reduce([]) {|selected, marble|
            if selected.size >= resultSize then
                selected
            else
                selected + [marble] 
            end
        }
    end

    # Quarks::firstNVisibleMarbleQuarks(resultSize)
    def self.firstNVisibleMarbleQuarks(resultSize)
        Marbles::marblesOfGivenDomainInOrder("quarks").reduce([]) {|selected, marble|
            filepath = marble.filepath()
            if selected.size >= resultSize then
                selected
            else
                if (DoNotShowUntil::isVisible(Marbles::get(filepath, "uuid"))) then
                    selected + [marble]
                else
                    selected
                end 
            end
        }
    end
end
