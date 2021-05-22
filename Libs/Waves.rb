
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

    # Waves::marbleToDoNotShowUnixtime(marble)
    def self.marbleToDoNotShowUnixtime(marble)
        filepath = marble.filepath()
        if Elbrams::get(filepath, "repeatType") == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 86400) + Elbrams::get(filepath, "repeatValue").to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + Elbrams::get(filepath, "repeatValue").to_i*3600
        end
        if Elbrams::get(filepath, "repeatType") == 'every-n-hours' then
            return Time.new.to_i+3600 * Elbrams::get(filepath, "repeatValue").to_f
        end
        if Elbrams::get(filepath, "repeatType") == 'every-n-days' then
            return Time.new.to_i+86400 * Elbrams::get(filepath, "repeatValue").to_f
        end
        if Elbrams::get(filepath, "repeatType") == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != Elbrams::get(filepath, "repeatValue") do
                cursor = cursor + 3600
            end
           return cursor
        end
        if Elbrams::get(filepath, "repeatType") == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != Elbrams::get(filepath, "repeatValue") do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(marble)
    def self.scheduleString(marble)
        filepath = marble.filepath()
        if Elbrams::get(filepath, "repeatType") == 'sticky' then
            return "sticky, from: #{Elbrams::get(filepath, "repeatValue")}"
        end
        "#{Elbrams::get(filepath, "repeatType")}: #{Elbrams::get(filepath, "repeatValue")}"
    end

    # Waves::performDone(marble)
    def self.performDone(marble)
        filepath = marble.filepath()
        Elbrams::set(filepath, "lastDoneDateTime", Time.now.utc.iso8601)
        unixtime = Waves::marbleToDoNotShowUnixtime(marble)
        DoNotShowUntil::setUnixtime(Elbrams::get(filepath, "uuid"), unixtime)
        $counterx.registerDone()
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/waves/#{LucilleCore::timeStringL22()}.marble"

        Elbrams::issueNewEmptyElbram(filepath)

        Elbrams::set(filepath, "uuid", SecureRandom.uuid)
        Elbrams::set(filepath, "unixtime", Time.new.to_i)
        Elbrams::set(filepath, "domain", "waves")

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end
        Elbrams::set(filepath, "description", description)

        Elbrams::set(filepath, "type", "Line")
        Elbrams::set(filepath, "payload", "")

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        if schedule.nil? then
            FileUtils.rm(filepath)
            return nil
        end
        Elbrams::set(filepath, "repeatType", schedule[0])
        Elbrams::set(filepath, "repeatValue",  schedule[1])

        Elbrams::set(filepath, "lastDoneDateTime", "2021-01-01T00:00:11Z")

        nil
    end

    # Waves::toString(marble)
    def self.toString(marble)
        filepath = marble.filepath()
        ago = 
            if Elbrams::get(filepath, "lastDoneDateTime") then
                "#{((Time.new.to_i - DateTime.parse(Elbrams::get(filepath, "lastDoneDateTime")).to_time.to_i).to_f/86400).round(2)} days ago"
            else
                ""
            end
        "[wave] [#{Waves::scheduleString(marble)}] #{Elbrams::get(filepath, "description")} (#{ago})"
    end

    # Waves::ns16s()
    def self.ns16s()
        Elbrams::marblesOfGivenDomainInOrder("waves")
            .map
            .with_index{|marble, indx|
                filepath = marble.filepath()
                {
                    "uuid"      => Elbrams::get(filepath, "uuid"),
                    "metric"    => ["ns:wave", nil, nil, indx],
                    "announce"  => Waves::toString(marble),
                    "access"    => lambda {
                        Waves::access(marble)
                        command = LucilleCore::askQuestionAnswerAsString("[actions: 'done'] action : ")
                        if command == "done" then
                            Waves::performDone(marble)
                        end
                    },
                    "done"     => lambda{
                        Waves::performDone(marble)
                    }
                }
            }
    end

    # Waves::access(marble)
    def self.access(marble)
        filepath = marble.filepath()
        puts Waves::toString(marble)
        if Elbrams::get(filepath, "type") == "Line" then
            return
        end
        if Elbrams::get(filepath, "type") == "Url" then
            Utils::openUrl(Elbrams::get(filepath, "payload"))
            return
        end

        raise "81367369-5265-44d3-a338-8240067b2442"
    end

    # Waves::selectElbramWaveOrNull()
    def self.selectElbramWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Elbrams::marblesOfGivenDomainInOrder("waves").sort{|m1, m2| m1.get("lastDoneDateTime") <=> m2.get("lastDoneDateTime") }, lambda {|m| Waves::toString(m) })
    end

    # Waves::landing(marble)
    def self.landing(marble)
        filepath = marble.filepath()
        loop {

            return if !marble.isStillAlive()

            puts Waves::toString(marble)
            puts "uuid: #{Elbrams::get(filepath, "uuid")}"
            puts "last done: #{Elbrams::get(filepath, "lastDoneDateTime")}"

            if DoNotShowUntil::isVisible(Elbrams::get(filepath, "uuid")) then
                puts "active"
            else
                puts "hidden until: #{Time.at(DoNotShowUntil::getUnixtimeOrNull(Elbrams::get(filepath, "uuid"))).to_s}"
            end

            puts "schedule: #{Waves::scheduleString(marble)}"

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item("access", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                    Waves::performDone(marble)
                end
            })

            menuitems.item("done",lambda { Waves::performDone(marble) })

            menuitems.item("recast schedule", lambda { 
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                Elbrams::set(filepath, "repeatType", schedule[0])
                Elbrams::set(filepath, "repeatValue",  schedule[1])
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
            wave = Waves::selectElbramWaveOrNull()
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



