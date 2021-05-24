
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

    # Waves::waveToDoNotShowUnixtime(wave)
    def self.waveToDoNotShowUnixtime(wave)
        if wave["repeatType"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 86400) + wave["repeatValue"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + wave["repeatValue"].to_i*3600
        end
        if wave["repeatType"] == 'every-n-hours' then
            return Time.new.to_i+3600 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-n-days' then
            return Time.new.to_i+86400 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != wave["repeatValue"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if wave["repeatType"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != wave["repeatValue"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(wave)
    def self.scheduleString(wave)
        if wave["repeatType"] == 'sticky' then
            return "sticky, from: #{wave["repeatValue"]}"
        end
        "#{wave["repeatType"]}: #{wave["repeatValue"]}"
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        CoreDataTx::commit(wave)
        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
        $counterx.registerDone()
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        wave = {}

        uuid = SecureRandom.uuid

        wave["uuid"] = uuid
        wave["schema"] = "wave"
        wave["unixtime"] = Time.new.to_i

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            return nil
        end

        wave["description"] = description

        wave["contentType"] = "Line"
        wave["payload"] = ""

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        if schedule.nil? then
            return nil
        end

        wave["repeatType"] = schedule[0]
        wave["repeatValue"] = schedule[1]

        wave["lastDoneDateTime"] = "2021-01-01T00:00:11Z"

        CoreDataTx::commit(wave)

        wave
    end

    # Waves::toString(wave)
    def self.toString(wave)
        ago = "#{((Time.new.to_i - DateTime.parse(wave["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] [#{Waves::scheduleString(wave)}] #{wave["description"]} (#{ago})"
    end

    # Waves::ns16s()
    def self.ns16s()
        CoreDataTx::getObjectsBySchema("wave")
            .map
            .with_index{|wave, indx|
                {
                    "uuid"      => wave["uuid"],
                    "metric"    => ["ns:wave", nil, nil, indx],
                    "announce"  => Waves::toString(wave),
                    "access"    => lambda {
                        startUnixtime = Time.new.to_f
                        Waves::access(wave)
                        command = LucilleCore::askQuestionAnswerAsString("[actions: 'done'] action : ")
                        if command == "done" then
                            Waves::performDone(wave)
                        end
                        timespan = Time.new.to_f - startUnixtime
                        timespan = [timespan, 3600*2].min
                        puts "putting #{timespan} seconds to CounterX"
                        $counterx.registerTimeInSeconds(timespan)
                    },
                    "done"     => lambda{
                        Waves::performDone(wave)
                    }
                }
            }
    end

    # Waves::access(wave)
    def self.access(wave)
        puts Waves::toString(wave)
        if wave["contentType"] == "Line" then
            return
        end
        if wave["contentType"] == "Url" then
            Utils::openUrl(wave["payload"])
            return
        end
        raise "81367369-5265-44d3-a338-8240067b2442"
    end

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", CoreDataTx::getObjectsBySchema("wave").sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::landing(wave)
    def self.landing(wave)
        loop {

            return if CoreDataTx::getObjectByIdOrNull(wave["uuid"]).nil?

            puts Waves::toString(wave)
            puts "uuid: #{wave["uuid"]}"
            puts "last done: #{wave["lastDoneDateTime"]}"

            if DoNotShowUntil::isVisible(wave["uuid"]) then
                puts "active"
            else
                puts "hidden until: #{Time.at(DoNotShowUntil::getUnixtimeOrNull(wave["uuid"])).to_s}"
            end

            puts "schedule: #{Waves::scheduleString(wave)}"

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item("access", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                    Waves::performDone(wave)
                end
            })

            menuitems.item("done",lambda { Waves::performDone(wave) })

            menuitems.item("recast schedule", lambda { 
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                CoreDataTx::commit(wave)
            })

            menuitems.item("destroy", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                    CoreDataTx::delete(wave["uuid"])
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
            wave = Waves::selectWaveOrNull()
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
