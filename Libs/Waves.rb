
class Waves

    # --------------------------------------------------
    # IO

    # Waves::filepathForUUID(uuid)
    def self.filepathForUUID(uuid)
        "#{Config::pathToDataCenter()}/Wave/#{uuid}.Nx5"
    end

    # Waves::nx5Filepaths()
    def self.nx5Filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Wave")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # Waves::items()
    def self.items()
        Waves::nx5Filepaths()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # Waves::commitItem(item)
    def self.commitItem(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = Waves::filepathForUUID(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # Waves::commitAttribute1(uuid, attname, attvalue)
    def self.commitAttribute1(uuid, attname, attvalue)
        filepath = Waves::filepathForUUID(uuid)
        raise "(error: EDE283D3-0E7E-4D66-B055-160F43D127C5) uuid: '#{uuid}', attname: '#{attname}', attvalue: '#{attvalue}'" if !File.exists?(filepath)
        Nx5::emitEventToFile1(filepath, attname, attvalue)
    end

    # Waves::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = Waves::filepathForUUID(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        filepath = Waves::filepathForUUID(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        Item2Cx22::garbageCollection(uuid)
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
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(Waves::operatorForUUID(uuid))
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
        Waves::commitItem(item)
        item
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::toString(item)
    def self.toString(item)
        lastDoneDateTime = item["lastDoneDateTime"]
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} (#{Waves::nx46ToString(item["nx46"])}) (#{ago}) 🌊 [#{item["priority"]}]"
    end

    # Waves::listingItems(priority)
    def self.listingItems(priority)
        Waves::items()
            .select{|item| item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()) }
            .select{|item| item["priority"] == priority }
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Waves::filepathForUUID(uuid)
        ElizabethNx5.new(filepath)
    end

    # Waves::operatorForItem(item)
    def self.operatorForItem(item)
        Waves::operatorForUUID(item["uuid"])
    end

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)
        puts "done-ing: #{Waves::toString(item)}"
        Waves::commitAttribute1(item["uuid"], "lastDoneDateTime", Time.now.utc.iso8601)

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
            Nx113Access::access(Waves::operatorForItem(item), item["nx113"])
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
            puts Waves::toString(item)
            actions = ["access", "perform done", "set days of the week", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                Waves::access(item)
            end
            if action == "perform done" then
                Waves::performWaveNx46WaveDone(item)
                next
            end
            if action == "set days of the week" then
                days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                item["onlyOnDays"] = days
                Waves::commitItem(item)
            end
            if action == "destroy" then
                Waves::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end
end
