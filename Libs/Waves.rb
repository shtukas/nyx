
class Waves

    # Waves::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/Wave/#{uuid}.json"
    end

    # Waves::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Wave")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Waves::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = Waves::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Waves::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = Waves::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        filepath = Waves::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Making

    # Waves::interactivelySelectPriorityOrNull()
    def self.interactivelySelectPriorityOrNull()
        prioritys = ["ns:mandatory-today", "ns:time-important", "ns:beach"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("priority:", prioritys)
    end

    # Waves::interactivelySelectPriority()
    def self.interactivelySelectPriority()
        loop {
            priority = Waves::interactivelySelectPriorityOrNull()
            return priority if priority
        }
    end

    # Waves::makeNx46InteractivelyOrNull()
    def self.makeNx46InteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return {
                "type"  => "sticky",
                "value" => fromHour
            }
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return {
                    "type"  => type,
                    "value" => value
                }
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::computeNextDisplayTimeForNx46(nx46: Nx46)
    def self.computeNextDisplayTimeForNx46(nx46)
        if nx46["type"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - 86400) + nx46["value"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + nx46["value"].to_i*3600
        end
        if nx46["type"] == 'every-n-hours' then
            return Time.new.to_i+3600 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-n-days' then
            return Time.new.to_i+86400 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != nx46["value"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if nx46["type"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        raise "(error: afe44910-57c2-4be5-8e1f-2c2fb80ae61a) nx46: #{JSON.pretty_generate(nx46)}"
    end

    # Waves::nx46ToString(item)
    def self.nx46ToString(item)
        if item["type"] == 'sticky' then
            return "sticky, from: #{item["value"]}"
        end
        "#{item["type"]}: #{item["value"]}"
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Waves::makeNx46InteractivelyOrNull()
        return nil if nx46.nil?
        uuid = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        priority = Waves::interactivelySelectPriority()
        item = {
            "uuid"             => uuid,
            "mikuType"         => "Wave",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description,
            "nx46"             => nx46,
            "priority"         => priority,
            "nx113"            => nx113,
            "lastDoneDateTime" => "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        }
        Waves::commit(item)
        item
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::toString(item)
    def self.toString(item)
        maxt = item["maxTimeInHours"] ? " (max time: #{item["maxTimeInHours"].to_s.green})" : ""
        ago = "#{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} (#{Waves::nx46ToString(item["nx46"])}) (#{ago}) 🌊 (#{item["priority"]})#{maxt}"
    end

    # Waves::toStringForSearch(item)
    def self.toStringForSearch(item)
        ago = "#{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        isPendingStr = DoNotShowUntil::isVisible(item["uuid"]) ? " (pending)".green : ""
        "(wave) #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} (#{Waves::nx46ToString(item["nx46"])}) (#{ago})#{isPendingStr} 🌊 [#{item["priority"]}]"
    end

    # Waves::listingItems(priority)
    def self.listingItems(priority)
        Waves::items()
            .select{|item| 
                b1 = (item["priority"] == priority) 
                b2 = (item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()))
                b1 and b2
            }
    end

    # Waves::numbers(item)
    def self.numbers(item)
        if item["maxTimeInHours"].nil? then
            {
                "shouldListing"        => true,
                "missingHoursForToday" => 0
            }
        else
            valueToday = Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item))
            {
                "shouldListing"        => true,
                "missingHoursForToday" => (item["maxTimeInHours"]*3600 - valueToday).to_f/3600
            }
        end
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)
        puts "done-ing: #{Waves::toString(item)}"
        item["lastDoneDateTime"] = Time.now.utc.iso8601
        Waves::commit(item)

        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Waves::dive()
    def self.dive()
        loop {
            items = Waves::items().sort{|w1, w2| w1["description"] <=> w2["description"] }
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", items, lambda{|wave| wave["description"] })
            return if wave.nil?
            Waves::probe(wave)
        }
    end

    # Waves::access(item)
    def self.access(item)
        puts Waves::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # Waves::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return Waves::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        Waves::getOrNull(item["uuid"])
    end

    # Waves::probe(item)
    def self.probe(item)
        loop {
            item = Waves::getOrNull(item["uuid"])
            puts Waves::toString(item)
            actions = ["access", "update description", "update wave pattern", "perform done", "set project", "set max time", "set days of the week", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                Waves::access(item)
            end
            if action == "update description" then
                item["description"] = CommonUtils::editTextSynchronously(item["description"])
                Waves::commit(item)
                next
            end
            if action == "update wave pattern" then
                item["nx46"] = Waves::makeNx46InteractivelyOrNull()
                Waves::commit(item)
                next
            end
            if action == "perform done" then
                Waves::performWaveNx46WaveDone(item)
                next
            end
            if action == "set project" then
                project = NxProjects::interactivelySelectNxProjectOrNull()
                next if project.nil?
                item["projectId"] = project["uuid"]
                Waves::commit(item)
                next
            end
            if action == "set max time" then
                maxTimeInHours = LucilleCore::askQuestionAnswerAsString("max time in hours: ").to_f
                next if maxTimeInHours == 0
                item["maxTimeInHours"] = maxTimeInHours
                Waves::commit(item)
                next
            end
            if action == "set days of the week" then
                days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                item["onlyOnDays"] = days
                Waves::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of '#{Waves::toString(item)}' ? ") then
                    Waves::destroy(item["uuid"])
                    PolyActions::garbageCollectionAfterItemDeletion(item)
                end
                return
            end
        }
    end
end
