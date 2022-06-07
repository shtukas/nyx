
class NxCatalyst

    # --------------------------------------------------
    # IO

    # NxCatalyst::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxCatalyst")
    end

    # NxCatalyst::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        Librarian::getObjectsByMikuTypeAndUniverse("NxCatalyst", universe)
    end

    # NxCatalyst::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Making

    # NxCatalyst::makeNx47WavePatternInteractivelyOrNull() # Nx47WavePattern
    def self.makeNx47WavePatternInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes)

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

    # NxCatalyst::computeNextDisplayTimeForNx47WavePattern(item: Nx47WavePattern)
    def self.computeNextDisplayTimeForNx47WavePattern(item)
        if item["type"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - 86400) + item["value"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + item["value"].to_i*3600
        end
        if item["type"] == 'every-n-hours' then
            return Time.new.to_i+3600 * item["value"].to_f
        end
        if item["type"] == 'every-n-days' then
            return Time.new.to_i+86400 * item["value"].to_f
        end
        if item["type"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != item["value"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if item["type"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != item["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # NxCatalyst::nx47WavePatternToString(item)
    def self.nx47WavePatternToString(item)
        if item["type"] == 'sticky' then
            return "sticky, from: #{item["value"]}"
        end
        "#{item["type"]}: #{item["value"]}"
    end

    # NxCatalyst::issueNewNxCatalystInteractivelyOrNull()
    def self.issueNewNxCatalystInteractivelyOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx46 = nil

        nx46Type = LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx46 (behaviour)", ["Nx46Dated (not supported yet)", "Nx46Float (not supported yet)", "Nx46Project (not supported yet)", "Nx46Todo (not supported yet)", "Nx46Wave"])

        if nx46Type == "Nx46Wave" then
            nx47 = NxCatalyst::makeNx47WavePatternInteractivelyOrNull()
            return if nx47.nil?
            nx46 = {
                "mikuType"         => "Nx46Wave",
                "pattern"          => nx47,
                "lastDoneDateTime" => "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
            }
        end

        raise "(error: 99ef1c4f-994c-4c4a-a742-03ebb0d66c89)" if nx46.nil?

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        universe = Multiverse::interactivelySelectUniverse()

        catalyst = {
            "uuid"        => uuid,
            "mikuType"    => "NxCatalyst",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "behaviour"   => nx46,
            "content"     => nx111,
            "universe"    => universe,
        }

        Librarian::commit(catalyst)
        catalyst
    end

    # -------------------------------------------------------------------------
    # Operations

    # NxCatalyst::toString(item)
    def self.toString(item)
        lastDoneDateTime = item["behaviour"]["lastDoneDateTime"]
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "(#{item["behaviour"]["mikuType"]}) #{item["description"]} (#{Nx111::toString(item["content"])}) (#{NxCatalyst::nx47WavePatternToString(item["behaviour"]["pattern"])}) (#{ago}) (#{item["universe"]})"
    end

    # NxCatalyst::performNxCatalystNx46WaveDone(item)
    def self.performNxCatalystNx46WaveDone(item)
        puts "done-ing: #{NxCatalyst::toString(item)}"
        item["behaviour"]["lastDoneDateTime"] = Time.now.utc.iso8601
        Librarian::commit(item)

        unixtime = NxCatalyst::computeNextDisplayTimeForNx47WavePattern(item)
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # NxCatalyst::landing(item)
    def self.landing(item)
        uuid = item["uuid"]

        loop {

            system("clear")

            store = ItemStore.new()

            uuid = item["uuid"]

            puts "#{NxCatalyst::toString(item)}".green

            puts "uuid: #{item["uuid"]}".yellow
            puts "content: #{Nx111::toString(item["content"])}"
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts ""

            puts "access | done | <datecode> | description | iam | behaviour | note | universe | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if command == "access" then
                EditionDesk::accessItem(item)
                next
            end

            if command == "done" then
                NxCatalyst::performNxCatalystNx46WaveDone(item)
                break
            end

            if (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("description", command) then
                item["description"] = CommonUtils::editTextSynchronously(item["description"])
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
                next if nx111.nil?
                item["content"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("behaviour", command) then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy '#{NxCatalyst::toString(item).green}' ? : ") then
                    NxCatalyst::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # -------------------------------------------------------------------------

    # NxCatalyst::itemsForListing(universe)
    def self.itemsForListing(universe)
        Librarian::getObjectsByMikuTypeAndPossiblyNullUniverse("NxCatalyst", universe)
    end

    # NxCatalyst::nx20s()
    def self.nx20s()
        NxCatalyst::items().map{|item|
            {
                "announce" => NxCatalyst::toString(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
