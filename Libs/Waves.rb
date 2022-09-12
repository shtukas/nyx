
class Waves

    # --------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        TheIndex::mikuTypeToItems("Wave")
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Making

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
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "Wave")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx46",        nx46)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        DxF1::setAttribute2(uuid, "lastDoneDateTime", "#{Time.new.strftime("%Y")}-01-01T00:00:00Z")
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 28781f44-be29-4f67-bc87-4c9d6171ffc9) How did that happen ? 🤨"
        end
        item
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::toString(item)
    def self.toString(item)
        lastDoneDateTime = item["lastDoneDateTime"]
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]}#{Cx::uuidToString(item["nx112"])} (#{Waves::nx46ToString(item["nx46"])}) (#{ago}) 🌊"
    end

    # Waves::isPriority(item)
    def self.isPriority(item)
        nx46 = item["nx46"]
        return true if nx46["type"] == "sticky"
        return true if nx46["type"] == "every-this-day-of-the-week"
        return true if nx46["type"] == "every-this-day-of-the-month"
        false
    end

    # Waves::listingItems(priority)
    def self.listingItems(priority)
        Waves::items()
            .select{|item| priority ? Waves::isPriority(item) : !Waves::isPriority(item) }
    end

    # -------------------------------------------------------------------------

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)
        puts "done-ing: #{Waves::toString(item)}"
        DxF1::setAttribute2(item["uuid"], "lastDoneDateTime", Time.now.utc.iso8601)

        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Waves::dive()
    def self.dive()
        loop {
            waves = Waves::items()
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", waves, lambda{|item| Waves::toString(item) })
            break if wave.nil?
            if LucilleCore::askQuestionAnswerAsBoolean("'#{wave["description"].green}' done ? ", true) then
                Waves::performWaveNx46WaveDone(wave)
                NxBallsService::close(wave["uuid"], true)
            end
        }
    end
end
