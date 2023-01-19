
class NxProjects

    # NxProjects::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxProject/#{uuid}.json"
    end

    # NxProjects::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxProject")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxProject-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxProjects::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxProjects::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxProjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxProjects::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxProjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxProjects::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "isWork"      => false
        }
        FileSystemCheck::fsck_NxProject(item, true)
        NxProjects::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]}"
    end

    # NxProjects::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        descriptionPadding = 
        if shouldFormat then
            (XCache::getOrNull("NxProject-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 0).to_i
        else
            0
        end

        data = Ax39::standardAx39CarrierNumbers(item) # {shouldListing, missingHoursForToday}
        dataStr = " (pending today: #{"%5.2f" % data["missingHoursForToday"]})"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "(project) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})#{dataStr}#{dnsustr}"
    end

    # NxProjects::itemToProject(item)
    def self.itemToProject(item)
        NxProjects::getOrNull(item["projectId"])
    end

    # NxProjects::projectsForListing()
    def self.projectsForListing()
        NxProjects::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|project| Ax39::standardAx39CarrierNumbers(project)["shouldListing"] }
    end

    # NxProjects::runningProjects()
    def self.runningProjects()
        NxProjects::items()
            .select{|project| NxBalls::getNxBallForItemOrNull(project) }
    end

    # NxProjects::firstNxTodoItemsForNxProject(projectId)
    def self.firstNxTodoItemsForNxProject(projectId)
        filepath = "#{Config::pathToDataCenter()}/NxProject-to-FirstItems/#{projectId}.json"

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
            #puts "> issuing new file for project: #{NxProjects::getOrNull(projectId)["description"]}"
            items = NxTodos::itemsForNxProject(projectId)
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

    # NxProjects::nextPositionForProject(projectId)
    def self.nextPositionForProject(projectId)
        ([0] + NxTodos::itemsForNxProject(projectId).map{|todo| todo["projectposition"] }).max + 1
    end

    # NxProjects::projectsTotalHoursPerWeek()
    def self.projectsTotalHoursPerWeek()
        NxProjects::items().map{|item| item["ax39"]["hours"] }.inject(0, :+)
    end

    # NxProjects::numbers(project)
    def self.numbers(project)
        Ax39::standardAx39CarrierNumbers(project)
    end

    # NxProjects::projectWithToAllAssociatedListingItems(project)
    def self.projectWithToAllAssociatedListingItems(project)

        makeVx01 = lambda {|project|
            uuid = Digest::SHA1.hexdigest("0BCED4BA-4FCC-405A-8B06-EB5359CBFC75")
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => Time.new.to_f,
                "description" => "Main focus for project '#{NxProjects::toString(project)}'",
                "projectId"   => project["uuid"]
            }
        }

        items = NxProjects::firstNxTodoItemsForNxProject(project["uuid"])
        if items.size > 0 then
            [makeVx01.call(project)] + items
        else
            [project]
        end
    end

    # NxProjects::listingItems()
    def self.listingItems()
        NxProjects::projectsForListing()
            .map{|project| NxProjects::projectWithToAllAssociatedListingItems(project) }
            .flatten
    end

    # --------------------------------------------
    # Ops

    # NxProjects::interactivelySelectNxProjectOrNull()
    def self.interactivelySelectNxProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxProjects::items(), lambda{|project| NxProjects::toStringWithDetails(project, true)})
    end

    # NxProjects::interactivelySelectProject()
    def self.interactivelySelectProject()
        loop {
            project = NxProjects::interactivelySelectNxProjectOrNull()
            return project if project
        }
    end

    # NxProjects::presentProjectItems(project)
    def self.presentProjectItems(project)
        items = NxTodos::itemsForNxProject(project["uuid"])
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

    # NxProjects::probe(project)
    def self.probe(project)
        loop {
            puts NxProjects::toStringWithDetails(project, false)
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
                puts "adding #{timeInHours} hours to '#{NxProjects::toString(project)}'"
                Bank::put(project["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(project["uuid"], unixtime)
            end
            if action == "set Ax39" then
                project["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxProject(project, true)
                NxProjects::commit(project)
            end
            if action == "expose" then
                puts JSON.pretty_generate(project)
                LucilleCore::pressEnterToContinue()
            end
            if action == "items dive" then
                NxProjects::presentProjectItems(project)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxProject '#{NxProjects::toString(project)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxProject/#{project["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxProjects::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            puts "Total hours (daily): #{(NxProjects::projectsTotalHoursPerWeek().to_f/7).round(2)}"
            project = NxProjects::interactivelySelectNxProjectOrNull()
            return if project.nil?
            NxProjects::probe(project)
        }
    end

    # NxProjects::interactivelyDecideProjectPosition(projectId)
    def self.interactivelyDecideProjectPosition(projectId)
        NxTodos::itemsForNxProject(projectId)
            .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
            .first(CommonUtils::screenHeight() - 2)
            .each{|item|
                puts "- (#{"%7.3f" % item["projectposition"]}) #{NxTodos::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (default to next): ")
        if position then
            position.to_f
        else
            NxProjects::nextPositionForProject(projectId)
        end
    end
end
