
# encoding: UTF-8

class Quarks

    # Quarks::interactivelyIssueNewMarbleQuarkOrNull(l22)
    def self.interactivelyIssueNewMarbleQuarkOrNull(l22)

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{l22}.marble"

        raise "[error: e7ed22f0-9962-472d-907f-419916d224ee]" if File.exists?(filepath)

        marble = Marbles::issueNewEmptyMarble(filepath)

        marble.set("uuid", SecureRandom.uuid)
        marble.set("unixtime", Time.new.to_i)
        marble.set("domain", "quarks")

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end  
        marble.set("description", description)

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])

        if type.nil? then
            FileUtils.rm(filepath)
            return nil
        end  

        if type == "Line" then
            marble.set("type", "Line")
            marble.set("payload", "")
        end
        if type == "Url" then
            marble.set("type", "Url")

            url = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if url == "" then
                FileUtils.rm(filepath)
                return nil
            end  
            marble.set("payload", url)
        end
        if type == "Text" then
            marble.set("type", "Text")
            text = Utils::editTextSynchronously("")
            payload = MarbleElizabeth.new(marble.filepath()).commitBlob(text)
            marble.set("payload", payload)
        end
        if type == "ClickableType" then
            marble.set("type", "ClickableType")
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(filepath) or !File.file?(filepath) then
                FileUtils.rm(filepath)
                return nil
            end
            nhash = MarbleElizabeth.new(marble.filepath()).commitBlob(IO.read(filepath)) # bad choice, this file could be large
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            marble.set("payload", payload)
        end
        if type == "AionPoint" then
            marble.set("type", "AionPoint")
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                FileUtils.rm(location)
                return nil
            end
            payload = AionCore::commitLocationReturnHash(MarbleElizabeth.new(marble.filepath()), location)
            marble.set("payload", payload)
        end
        marble
    end

    # --------------------------------------------------

    # Quarks::toString(marble)
    def self.toString(marble)
        "[quark] #{marble.description()}"
    end

    # --------------------------------------------------

    # Quarks::landing(marble)
    def self.landing(marble)
        loop {

            return if !marble.isStillAlive()

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(marble)
            puts "uuid: #{marble.uuid()}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(marble.uuid())
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "recoveredDailyTimeInHours: #{BankExtended::recoveredDailyTimeInHours(marble.uuid())}".yellow

            puts ""

            mx.item("access (partial edit)".yellow,lambda { 
                Marbles::access(marble)
            })

            mx.item("edit".yellow, lambda {
                Marbles::edit(marble["nereiduuid"])
            })

            mx.item("transmute".yellow, lambda { 
                Marbles::transmute(marble)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(marble)
                LucilleCore::pressEnterToContinue()
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

    # Quarks::middlePointOfTwoL22sOrNull(p1, p2)
    def self.middlePointOfTwoL22sOrNull(p1, p2)
        raise "ae294eb7-4a63-4c82-91a1-96ca58a04536" if p1 == p2

        projectL22ToFloat = lambda{|l22|
            Time.strptime(l22[0, 15], '%Y%m%d-%H%M%S').to_i + "0.#{l22[16, 6]}".to_f
        }

        float1 = projectL22ToFloat.call(p1)
        float2 = projectL22ToFloat.call(p2)

        float3 = (float1+float2).to_f/2

        p3 = Time.at(float3.to_i).strftime("%Y%m%d-%H%M%S") + "-#{("#{"%.6f" % (float3-float3.to_i)}")[2, 6].ljust(6, "0")}"

        return nil if [p1, p2].include?(p3)

        p3
    end

    # Quarks::computeLowL22()
    def self.computeLowL22()
        indx = 0
        loop {
            marbles = Marbles::marblesOfGivenDomainInOrder("quarks")
            if marbles.size < (21+indx) then
                return LucilleCore::timeStringL22()
            else
                l22s = marbles.drop(19+indx).take(2).map{|marble| File.basename(marble.filepath())[0, 22] }
                l22 = Quarks::middlePointOfTwoL22sOrNull(l22s[0], l22s[1])
                return l22 if l22
            end
            indx = indx+1
        }
    end

    # Quarks::determineMarbleQuarkPlacingL22()
    def self.determineMarbleQuarkPlacingL22()
        puts "Placement ordinal listing"
        command = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' #default, 'last'): ")
        if command == "low" or command == "" then
            return Quarks::computeLowL22()
        end
        LucilleCore::timeStringL22()
    end

    # Quarks::ns16s()
    def self.ns16s()

        toString = lambda {|marble|
            "(rt: #{"%5.3f" % BankExtended::recoveredDailyTimeInHours(marble.uuid()).round(3)}) #{Quarks::toString(marble)}"
        }

        # We intersect the quarks for the database with the uuids of the current slot

        Quarks::firstNVisibleMarbleQuarks([10, Utils::screenHeight()].max)
            .map{|marble|
                {
                    "uuid"     => marble.uuid(),
                    "announce" => "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(marble.uuid())}) #{Quarks::toString(marble)}",
                    "start"    => lambda{ Quarks::runMarbleQuark(marble) },
                    "done"     => lambda{
                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(marble)}' ? ", true) then
                            marble.destroy()
                        end
                    }
                }
            }
    end

    # Quarks::ns17s()
    def self.ns17s()
        Quarks::ns16s().map{|ns16|
            {
                "ns16" => ns16,
                "rt"   => BankExtended::recoveredDailyTimeInHours(ns16["uuid"])
            }
        }
    end

    # Quarks::runMarbleQuark(marble)
    def self.runMarbleQuark(marble)

        return if !marble.isStillAlive()

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Marble quark running for more than an hour")
                sleep 60
            }
        }

        puts "running: #{Quarks::toString(marble).green}"
        Marbles::access(marble)

        puts "landing | ++ # Postpone marble by an hour | + <weekday> # Postpone marble | + <float> <datecode unit> # Postpone marble | done | (empty) # default # exit".yellow

        loop {

            return if !marble.isStillAlive()

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("landing", command) then
                Quarks::landing(marble)
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(marble.uuid(), Time.new.to_i+3600)
                break
            end

            if Interpreting::match("+ *", command) then
                _, input = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(marble.uuid(), unixtime)
                break
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(marble.uuid(), unixtime)
                break
            end

            if Interpreting::match("done", command) then
                Marbles::postAccessCleanUp(marble) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                marble.destroy()
                break
            end

            if Interpreting::match("", command) then
                break
            end
        }

        thr.exit

        return if !marble.isStillAlive()

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min
        puts "putting #{timespan} seconds to marble: #{Quarks::toString(marble)}"
        Bank::put(marble.uuid(), timespan)

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
            if selected.size >= resultSize then
                selected
            else
                if (DoNotShowUntil::isVisible(marble.uuid())) then
                    selected + [marble]
                else
                    selected
                end 
            end
        }
    end

end
