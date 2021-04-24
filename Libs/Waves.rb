
# encoding: UTF-8

class Waves

    # Waves::makeScheduleParametersInteractivelyOrNull() # [type, value]
    def self.makeScheduleParametersInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes, lambda{|entity| entity })

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return ["sticky", fromHour]
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return [type, value]
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return [type, value]
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::getLocalTimeZone()
    def self.getLocalTimeZone()
        `date`.strip[-3 , 3]
    end

    # Waves::unixtimeAtComingMidnightAtGivenTimeZone(timezone)
    def self.unixtimeAtComingMidnightAtGivenTimeZone(timezone)
        supportedTimeZones = ["BST", "GMT"]
        if !supportedTimeZones.include?(timezone) then
            raise "error: 7CB8000B-7896-4F61-89ED-89C12E009EE6 ; we are only supporting '#{supportedTimeZones}' and you provided #{timezone}"
        end
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00 #{timezone}").to_time.to_i
    end

    # Waves::marbleToDoNotShowUnixtime(marble)
    def self.marbleToDoNotShowUnixtime(marble)
        filepath = marble.filepath()
        if Marbles::get(filepath, "repeatType") == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Waves::unixtimeAtComingMidnightAtGivenTimeZone(Waves::getLocalTimeZone()) - 86400) + Marbles::get(filepath, "repeatValue").to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Waves::unixtimeAtComingMidnightAtGivenTimeZone(Waves::getLocalTimeZone()) + Marbles::get(filepath, "repeatValue").to_i*3600
        end
        if Marbles::get(filepath, "repeatType") == 'every-n-hours' then
            return Time.new.to_i+3600 * Marbles::get(filepath, "repeatValue").to_f
        end
        if Marbles::get(filepath, "repeatType") == 'every-n-days' then
            return Time.new.to_i+86400 * Marbles::get(filepath, "repeatValue").to_f
        end
        if Marbles::get(filepath, "repeatType") == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != Marbles::get(filepath, "repeatValue") do
                cursor = cursor + 3600
            end
           return cursor
        end
        if Marbles::get(filepath, "repeatType") == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != Marbles::get(filepath, "repeatValue") do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(marble)
    def self.scheduleString(marble)
        filepath = marble.filepath()
        if Marbles::get(filepath, "repeatType") == 'sticky' then
            return "sticky, from: #{Marbles::get(filepath, "repeatValue")}"
        end
        "#{Marbles::get(filepath, "repeatType")}: #{Marbles::get(filepath, "repeatValue")}"
    end

    # Waves::performDone(marble)
    def self.performDone(marble)
        filepath = marble.filepath()
        Marbles::set(filepath, "lastDoneDateTime", Time.now.utc.iso8601)
        unixtime = Waves::marbleToDoNotShowUnixtime(marble)
        DoNotShowUntil::setUnixtime(Marbles::get(filepath, "uuid"), unixtime)
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/waves/#{LucilleCore::timeStringL22()}.marble"

        Marbles::issueNewEmptyMarble(filepath)

        Marbles::set(filepath, "uuid", SecureRandom.uuid)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "domain", "waves")

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end
        Marbles::set(filepath, "description", description)

        Marbles::set(filepath, "type", "Line")
        Marbles::set(filepath, "payload", "")

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        if schedule.nil? then
            FileUtils.rm(filepath)
            return nil
        end
        Marbles::set(filepath, "repeatType", schedule[0])
        Marbles::set(filepath, "repeatValue",  schedule[1])

        Marbles::set(filepath, "lastDoneDateTime", "2021-01-01T00:00:11Z")

        marble
    end

    # Waves::toString(marble)
    def self.toString(marble)
        filepath = marble.filepath()
        ago = 
            if Marbles::get(filepath, "lastDoneDateTime") then
                "#{((Time.new.to_i - DateTime.parse(Marbles::get(filepath, "lastDoneDateTime")).to_time.to_i).to_f/86400).round(2)} days ago"
            else
                ""
            end
        "[wave] [#{Waves::scheduleString(marble)}] #{Marbles::get(filepath, "description")} (#{ago})"
    end

    # Waves::ns16s()
    def self.ns16s()
        Marbles::marblesOfGivenDomainInOrder("waves")
            .map{|marble|
                filepath = marble.filepath()
                {
                    "uuid"     => Marbles::get(filepath, "uuid"),
                    "announce" => Waves::toString(marble),
                    "start"    => lambda {
                        Waves::access(marble)
                        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
                            Waves::performDone(marble)
                        end
                    },
                    "done"     => lambda{
                        Waves::performDone(marble)
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Waves::access(marble)
    def self.access(marble)
        filepath = marble.filepath()
        puts Waves::toString(marble)
        if Marbles::get(filepath, "type") == "Line" then
            return
        end
        if Marbles::get(filepath, "type") == "Url" then
            Utils::openUrl(Marbles::get(filepath, "payload"))
            return
        end

        raise "81367369-5265-44d3-a338-8240067b2442"
    end

    # Waves::selectMarbleWaveOrNull()
    def self.selectMarbleWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Marbles::marblesOfGivenDomainInOrder("waves").sort{|m1, m2| m1.get("lastDoneDateTime") <=> m2.get("lastDoneDateTime") }, lambda {|m| Waves::toString(m) })
    end

    # Waves::landing(marble)
    def self.landing(marble)
        filepath = marble.filepath()
        loop {

            return if !marble.isStillAlive()

            puts Waves::toString(marble)
            puts "uuid: #{Marbles::get(filepath, "uuid")}"
            puts "last done: #{Marbles::get(filepath, "lastDoneDateTime")}"

            if DoNotShowUntil::isVisible(Marbles::get(filepath, "uuid")) then
                puts "active"
            else
                puts "hidden until: #{Time.at(DoNotShowUntil::getUnixtimeOrNull(Marbles::get(filepath, "uuid"))).to_s}"
            end

            puts "schedule: #{Waves::scheduleString(marble)}"

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item("start", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                    Waves::performDone(marble)
                end
            })

            menuitems.item("done",lambda { Waves::performDone(marble) })

            menuitems.item("recast schedule", lambda { 
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                Marbles::set(filepath, "repeatType", schedule[0])
                Marbles::set(filepath, "repeatValue",  schedule[1])
            })

            menuitems.item("destroy", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                    marble.destroy()
                end
            })

            status = menuitems.promptAndRunSandbox()
            break if !status
        }
    end

    # Waves::wavesDive()
    def self.wavesDive()
        loop {
            system("Waves Dive")
            wave = Waves::selectMarbleWaveOrNull()
            return if wave.nil?
            Waves::landing(wave)
        }
    end

    # Waves::main()
    def self.main()
        loop {
            puts "Waves 🌊 (main)"
            options = [
                "new wave",
                "waves dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "new wave" then
                Waves::issueNewWaveInteractivelyOrNull()
            end
            if option == "waves dive" then
                Waves::wavesDive()
            end
        }
    end
end



