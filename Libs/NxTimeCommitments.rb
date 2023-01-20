
class NxTimeCommitments

    # NxTimeCommitments::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTimeCommitment/#{uuid}.json"
    end

    # NxTimeCommitments::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTimeCommitment")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxTimeCommitments::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTimeCommitments::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTimeCommitments::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTimeCommitments::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTimeCommitments::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTimeCommitments::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39
        }
        FileSystemCheck::fsck_NxTimeCommitment(item, true)
        NxTimeCommitments::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxTimeCommitments::toString(item)
    def self.toString(item)
        "(project) #{item["description"]}"
    end

    # NxTimeCommitments::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        descriptionPadding = 
        if shouldFormat then
            (XCache::getOrNull("NxTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 0).to_i
        else
            0
        end

        data = Ax39::standardAx39CarrierNumbers(item) # {shouldListing, missingHoursForToday}
        dataStr = " (pending today: #{"%5.2f" % data["missingHoursForToday"]})"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "(project) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})#{dataStr}#{dnsustr}"
    end

    # NxTimeCommitments::itemToProject(item)
    def self.itemToProject(item)
        NxTimeCommitments::getOrNull(item["projectId"])
    end

    # NxTimeCommitments::projectsForListing()
    def self.projectsForListing()
        NxTimeCommitments::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|project| Ax39::standardAx39CarrierNumbers(project)["shouldListing"] }
    end

    # NxTimeCommitments::runningProjects()
    def self.runningProjects()
        NxTimeCommitments::items()
            .select{|project| NxBalls::getNxBallForItemOrNull(project) }
    end

    # NxTimeCommitments::firstNxTodoItemsForNxTimeCommitment(projectId)
    def self.firstNxTodoItemsForNxTimeCommitment(projectId)
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-to-FirstItems/#{projectId}.json"

        getDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(uuid) }
                .compact
        }

        getRecentDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            return nil if (Time.new.to_i - packet["unixtime"]) > 3600
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(uuid) }
                .compact
        }

        issueNewFile = lambda {|filepath, projectId|
            #puts "> issuing new file for project: #{NxTimeCommitments::getOrNull(projectId)["description"]}"
            items = NxTodos::itemsForNxTimeCommitment(projectId)
                        .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
                        .first(10)
            uuids = items.map{|item| item["uuid"] }
            packet = {
                "unixtime" => Time.new.to_i,
                "uuids"    => uuids
            }
            File.open(filepath,  "w"){|f| f.puts(JSON.pretty_generate(packet)) }
            items
        }

        if Config::getOrNull("isLeaderInstance") then
            items = getRecentDataOrNull.call(filepath)
            return items if items
            return issueNewFile.call(filepath, projectId)
        else
            return (getDataOrNull.call(filepath) || [])
        end
    end

    # NxTimeCommitments::nextPositionForProject(projectId)
    def self.nextPositionForProject(projectId)
        ([0] + NxTodos::itemsForNxTimeCommitment(projectId).map{|todo| todo["projectposition"] }).max + 1
    end

    # NxTimeCommitments::projectsTotalHoursPerWeek()
    def self.projectsTotalHoursPerWeek()
        NxTimeCommitments::items().map{|item| item["ax39"]["hours"] }.inject(0, :+)
    end

    # NxTimeCommitments::numbers(project)
    def self.numbers(project)
        Ax39::standardAx39CarrierNumbers(project)
    end

    # NxTimeCommitments::projectWithToAllAssociatedListingItems(project)
    def self.projectWithToAllAssociatedListingItems(project)

        makeVx01 = lambda {|project|
            uuid = Digest::SHA1.hexdigest("0BCED4BA-4FCC-405A-8B06-EB5359CBFC75")
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => Time.new.to_f,
                "description" => "Main focus for project '#{NxTimeCommitments::toString(project)}'",
                "projectId"   => project["uuid"]
            }
        }

        items = NxTimeCommitments::firstNxTodoItemsForNxTimeCommitment(project["uuid"])
        if items.size > 0 then
            [makeVx01.call(project)] + items
        else
            [project]
        end
    end

    # NxTimeCommitments::listingItems()
    def self.listingItems()
        NxTimeCommitments::projectsForListing()
            .map{|project| NxTimeCommitments::projectWithToAllAssociatedListingItems(project) }
            .flatten
    end

    # --------------------------------------------
    # Ops

    # NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
    def self.interactivelySelectNxTimeCommitmentOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxTimeCommitments::items(), lambda{|project| NxTimeCommitments::toStringWithDetails(project, true)})
    end

    # NxTimeCommitments::interactivelySelectProject()
    def self.interactivelySelectProject()
        loop {
            project = NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
            return project if project
        }
    end

    # NxTimeCommitments::presentProjectItems(project)
    def self.presentProjectItems(project)
        items = NxTodos::itemsForNxTimeCommitment(project["uuid"])
        loop {
            system("clear")
            # We do not recompute all the items but we recall the ones we had to get the new 
            # projectpositions
            items = items
                        .map{|item| NxTodos::getOrNull(item["uuid"]) }
                        .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
            store = ItemStore.new()
            puts ""
            items
                .first(CommonUtils::screenHeight() - 4)
                .each{|item|
                    store.register(item, false)
                    puts "- (#{store.prefixString().to_s.rjust(2)}, #{"%7.3f" % item["projectposition"]}) #{NxTodos::toString(item)}"
                }
            puts ""
            puts "set position <index> <position>"
            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""
            if command.start_with?("set position") then
                command = command.strip[12, command.size]
                elements = command.split(" ")
                #puts JSON.generate(elements)
                indx = elements[0].to_i
                position = elements[1].to_f
                item = store.get(indx)
                #puts item
                next if item.nil?
                item["projectposition"] = position
                NxTodos::commit(item)
            end
        }
    end

    # NxTimeCommitments::probe(project)
    def self.probe(project)
        loop {
            puts NxTimeCommitments::toStringWithDetails(project, false)
            puts "data: #{Ax39::standardAx39CarrierNumbers(project)}"
            actions = ["start", "add time", "do not show until", "set Ax39", "expose", "items dive", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "start" then
                PolyActions::start(project)
                return
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{NxTimeCommitments::toString(project)}'"
                Bank::put(project["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(project["uuid"], unixtime)
            end
            if action == "set Ax39" then
                project["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxTimeCommitment(project, true)
                NxTimeCommitments::commit(project)
            end
            if action == "expose" then
                puts JSON.pretty_generate(project)
                LucilleCore::pressEnterToContinue()
            end
            if action == "items dive" then
                NxTimeCommitments::presentProjectItems(project)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTimeCommitment '#{NxTimeCommitments::toString(project)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment/#{project["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxTimeCommitments::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            puts "Total hours (daily): #{(NxTimeCommitments::projectsTotalHoursPerWeek().to_f/7).round(2)}"
            project = NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
            return if project.nil?
            NxTimeCommitments::probe(project)
        }
    end

    # NxTimeCommitments::interactivelyDecideProjectPosition(projectId)
    def self.interactivelyDecideProjectPosition(projectId)
        NxTodos::itemsForNxTimeCommitment(projectId)
            .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
            .first(CommonUtils::screenHeight() - 2)
            .each{|item|
                puts "- (#{"%7.3f" % item["projectposition"]}) #{NxTodos::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (default to next): ")
        if position then
            position.to_f
        else
            NxTimeCommitments::nextPositionForProject(projectId)
        end
    end
end
