
class Waves

    # ------------------------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        ObjectStore2::objects("Waves")
    end

    # Waves::getExistingFilepathForUUIDOrNull(uuid)
    def self.getExistingFilepathForUUIDOrNull(uuid)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Wave")
            .select{|filepath|
                obj = JSON.parse(IO.read(filepath))
                obj["uuid"] == uuid
            }
            .first
    end

    # Waves::commit(item)
    def self.commit(item)
        ObjectStore2::commit("Waves", item)
    end

    # --------------------------------------------------
    # Making

    # Waves::interactivelySelectPriorityOrNull()
    def self.interactivelySelectPriorityOrNull()
        priorities = ["ns:high", "ns:medium", "ns:low"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("priority:", priorities)
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
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        priority = Waves::interactivelySelectPriority()
        item = {
            "uuid"             => uuid,
            "mikuType"         => "Wave",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description,
            "nx46"             => nx46,
            "lastDoneDateTime" => "#{Time.new.strftime("%Y")}-01-01T00:00:00Z",
            "field11"          => coredataref,
            "priority"         => priority
        }
        ObjectStore2::commit("Waves", item)
        NonNxTodoItemToStreamMapping::interactiveProposalToSetMapping(item)
        item
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::toString(item)
    def self.toString(item)
        ago = "#{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]} (#{Waves::nx46ToString(item["nx46"])}) (coredataref: #{item["field11"]}) (#{ago}) 🌊"
    end

    # Waves::toStringForSearch(item)
    def self.toStringForSearch(item)
        ago = "#{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        isPendingStr = DoNotShowUntil::isVisible(item["uuid"]) ? " (pending)".green : ""
        "(wave) #{item["description"]} (#{Waves::nx46ToString(item["nx46"])}) (coredataref: #{item["field11"]}) (#{ago})#{isPendingStr} 🌊 [#{item["priority"]}]"
    end

    # Waves::listingItems()
    def self.listingItems()
        Waves::items()
            .select{|item|
                item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            }
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)

        # Marking the item as being done 
        puts "done-ing: #{Waves::toString(item)}"
        item["lastDoneDateTime"] = Time.now.utc.iso8601
        ObjectStore2::commit("Waves", item)

        # We control display using DoNotShowUntil
        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)

        Lookups::destroy("ListingTrajectories", item["uuid"])
    end

    # Waves::dive()
    def self.dive()
        loop {
            items = Waves::items().sort{|w1, w2| w1["description"] <=> w2["description"] }
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", items, lambda{|wave| wave["description"] })
            return if wave.nil?
            PolyActions::landing(wave)
        }
    end

    # Waves::access(item)
    def self.access(item)
        puts Waves::toString(item).green
        CoreData::access(item["field11"])
    end
end
