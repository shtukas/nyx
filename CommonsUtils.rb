
# encoding: UTF-8


# CommonsUtils::isLucille18()
# CommonsUtils::isActiveInstance(runId)
# CommonsUtils::currentHour()
# CommonsUtils::currentDay()
# CommonsUtils::simplifyURLCarryingString(string)
# CommonsUtils::traceToRealInUnitInterval(trace)
# CommonsUtils::traceToMetricShift(trace)
# CommonsUtils::realNumbersToZeroOne(x, origin, unit)
# CommonsUtils::codeToDatetimeOrNull(code)
# CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
# CommonsUtils::newBinArchivesFolderpath()

class CommonsUtils

    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"]==Config::get("PrimaryComputerName")
    end

    def self.isActiveInstance(runId)
        IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/run-identifier.data")==runId
    end

    def self.currentHour()
        Time.new.to_s[0,13]
    end

    def self.currentDay()
        Time.new.to_s[0,10]
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return CommonsUtils::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*CommonsUtils::traceToRealInUnitInterval(trace)
    end

    def self.realNumbersToZeroOne(x, origin, unit)
        alpha =
            if x >= origin then
                2-Math.exp(-(x-origin).to_f/unit)
            else
                Math.exp((x-origin).to_f/unit)
            end
        alpha.to_f/2
    end

    def self.codeToDatetimeOrNull(code)
        localsuffix = Time.new.to_s[-5,5]
        if code[0,1]=='+' then
            code = code[1,999]
            if code.index('@') then
                # The first part is an integer and the second HH:MM
                part1 = code[0,code.index('@')]
                part2 = code[code.index('@')+1,999]
                "#{( DateTime.now + part1.to_i ).to_date.to_s} #{part2}:00 #{localsuffix}"
            else
                if code.include?('days') or code.include?('day') then
                    if code.include?('days') then
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-4].to_f ).to_time.to_s}"
                    else
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-3].to_f ).to_time.to_s}"
                    end

                elsif code.include?('hours') or code.include?('hour') then
                    if code.include?('hours') then
                        ( Time.new + code[0,code.size-5].to_f*3600 ).to_s
                    else
                        ( Time.new + code[0,code.size-4].to_f*3600 ).to_s
                    end
                else
                    nil
                end
            end
        else
            # Here we expect "YYYY-MM-DD" or "YYYY-MM-DD@HH:MM"
            if code.index('@') then
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} #{part2}:00 #{localsuffix}"
            else
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} 00:00:00 #{localsuffix}"
            end
        end
    end

    def self.putshelp()
        puts "Special General Commands (view)"
        puts "    help"
        puts "    top"
        puts "    search <pattern>"
        puts "    :n # without changing the size of the workspace, focus on n^th item"
        puts "    r:on <requirement>"
        puts "    r:off <requirement>"
        puts "    r:show [requirement] # optional parameter # shows all the objects of that requirement"
        puts "    collections     # show collections"
        puts "    collections:new # new collection"
        puts "    threads         # show threads"
        puts "    projects        # show projects"
        puts ""
        puts ""
        puts "Special General Commands (inserts)"
        puts "    wave: <description>"
        puts "    stream: <description>"
        puts "    project: <description>"
        puts ""
        puts "Special General Commands (special circumstances)"
        puts "    clear # clear the screen"
        puts "    interface # run the interface of a given agent"
        puts "    lib # Invoques the Librarian interactive"
        puts ""
        puts "Special Object Commands:"
        puts "    (+)datetimecode"
        puts "    expose # pretty print the object"
        puts "    >c # send object to a collection"
        puts "    !today"
        puts "    r:add <requirement>"
        puts "    r:remove <requirement>"
        puts "    command ..."
    end

    def self.fDoNotShowUntilDateTimeTransform()
        FlockOperator::flockObjects().map{|object|
            if !FlockOperator::getDoNotShowUntilDateTimeDistribution()[object["uuid"]].nil? and (Time.new.to_s < FlockOperator::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["do-not-show-until-datetime"] = FlockOperator::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]
                object["metric"] = 0
            end
            if object["agent-uid"]=="283d34dd-c871-4a55-8610-31e7c762fb0d" and object["schedule"]["do-not-show-until-datetime"] and (Time.new.to_s < object["schedule"]["do-not-show-until-datetime"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["do-not-show-until-datetime"] = object["schedule"]["do-not-show-until-datetime"]
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end

    def self.isInteger(str)
        str.to_i.to_s == str
    end

    def self.emailSync(verbose)
        begin
            GeneralEmailClient::sync(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/guardian-relay.json")), verbose)
            OperatorEmailClient::download(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/operator.json")), verbose)
        rescue
        end
    end

    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    def self.processItemDescriptionPossiblyAsTextEditorInvitation(description)
        if description=='text' then
            editTextUsingTextmate("")
        else
            description
        end
    end

    def self.object2DonotShowUntilAsString(object)
        ( object["do-not-show-until-datetime"] and Time.new.to_s < object["do-not-show-until-datetime"] ) ? " (do not show until: #{object["do-not-show-until-datetime"]})" : ""
    end

    def self.object2Line_v0(object)
        announce = object['announce'].lines.first.strip
        if object["metric"]>1 then
            announce = announce.green
        end
        [
            "(#{"%.3f" % object["metric"]})",
            " [#{object["uuid"]}]",
            " #{announce}",
            CommonsUtils::object2DonotShowUntilAsString(object),
        ].join()
    end

    def self.object2Line_v1(object)
        announce = object['announce'].strip
        if object["metric"]>1 then
            announce = announce.green
        end
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        requirements = RequirementsOperator::getObjectRequirements(object['uuid'])
        requirementsAsString = requirements.size>0 ? " ( #{requirements.join(" ")} )" : ''
        [
            "(#{"%.3f" % object["metric"]})",
            " [#{object["uuid"]}]",
            " #{announce}",
            "#{requirementsAsString.green}",
            CommonsUtils::object2DonotShowUntilAsString(object),
            " (#{object["commands"].join(" ").red})",
            " \"#{defaultExpressionAsString.green}\""
        ].join()
    end

    def self.interactiveDisplayObjectAndProcessCommand(object)
        print CommonsUtils::object2Line_v1(object) + " : "
        givenCommand = STDIN.gets().strip
        command = givenCommand.size>0 ? givenCommand : ( object["default-expression"] ? object["default-expression"] : "" )
        CommonsUtils::processObjectAndCommand(object, command)
    end

    def self.processObjectAndCommand(object, expression)

        # no object needed

        if expression == 'help' then
            CommonsUtils::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == 'clear' then
            system("clear")
            return
        end

        if expression == "interface" then
            LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("agent", AgentsManager::agents(), lambda{ |agent| agent["agent-name"] })["interface"].call()
            return
        end

        if expression == 'info' then
            puts "CatalystDevOps::getArchiveTimelineSizeInMegaBytes(): #{CatalystDevOps::getArchiveTimelineSizeInMegaBytes()}".green
            puts "Todolists:".green
            puts "    Stream count : #{( count1 = Stream::getUUIDs().size )}".green
            puts "    Vienna count : #{(count3 = $viennaLinkFeeder.links().count)}".green
            puts "    Total        : #{(count1+count3)}".green
            puts "Requirements:".green
            puts "    On  : #{(RequirementsOperator::getAllRequirements() - RequirementsOperator::getCurrentlyUnsatisfiedRequirements()).join(", ")}".green
            puts "    Off : #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".green
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == "guardian" then
            aGuardianIsRunning = FlockOperator::flockObjects()
                .select{|object| object["agent-uid"]=="03a8bff4-a2a4-4a2b-a36f-635714070d1d" }
                .any?{|object| object["metadata"]["is-running"] }
            if aGuardianIsRunning then
                puts "You can't run `guardian` while a Guardian is running"
                LucilleCore::pressEnterToContinue()
            else
                o = FlockOperator::flockObjects()
                    .select{|object| object["agent-uid"]=="03a8bff4-a2a4-4a2b-a36f-635714070d1d" }
                    .select{|object| object["announce"].include?("Guardian") }
                    .first
                if o then
                    TimeCommitments::processObjectAndCommand(o, "start")
                else
                    puts "I could not find a time commitment guardian object to start"
                    LucilleCore::pressEnterToContinue()
                end
            end
            return
        end

        if expression == 'lib' then
            LibrarianExportedFunctions::librarianUserInterface_librarianInteractive()
            return
        end

        if expression == "collections" then
            collectionsuuids = CollectionsOperator::collectionsUUIDs()
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collections", collectionsuuids, lambda{ |collectionuuid| CollectionsOperator::collectionUUID2NameOrNull(collectionuuid) })
            return if collectionuuid.nil?
            CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "collections:new" then
            collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
            style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
            CollectionsOperator::createNewCollection_WithNameAndStyle(collectionname, style)
            return
        end

        if expression == "threads" then
            collectionsuuids = CollectionsOperator::collectionsUUIDs()
                .select{ |collectionuuid| CollectionsOperator::getCollectionStyle(collectionuuid)=="THREAD" }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("threads", collectionsuuids, lambda{ |collectionuuid| CollectionsOperator::collectionUUID2NameOrNull(collectionuuid) })
            return if collectionuuid.nil?
            CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "projects" then
            collectionsuuids = CollectionsOperator::collectionsUUIDs()
                .select{ |collectionuuid| CollectionsOperator::getCollectionStyle(collectionuuid)=="PROJECT" }
                .sort{|puuid1, puuid2| AgentCollections::objectMetricAsFloat(puuid1) <=> AgentCollections::objectMetricAsFloat(puuid2) }
                .reverse
            displayLambda = lambda{ |collectionuuid| "(#{"%.3f" % AgentCollections::objectMetricAsFloat(collectionuuid)}) [#{AgentCollections::objectMetricsAsString(collectionuuid)}] #{CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)}" }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", collectionsuuids, displayLambda)
            return if collectionuuid.nil?
            CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "threads-review" then
            CollectionsOperator::collectionsUUIDs()
                .select{ |collectionuuid| CollectionsOperator::getCollectionStyle(collectionuuid)=="THREAD" }
                .each{ |collectionuuid|
                    puts "# ---------------------------------------------------"
                    collectionname = CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)
                    if collectionname.nil? then
                        puts "Error 4ba7f95a: Could not determine the name of collection: #{collectionuuid}"
                        LucilleCore::pressEnterToContinue()
                        next
                    end
                    puts "Thread name: #{collectionname}"
                    CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
                }         
        end

        if expression.start_with?('wave:') then
            description = expression[5, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            uuid = SecureRandom.hex(4)
            folderpath = Wave::timestring22ToFolderpath(LucilleCore::timeStringL22())
            FileUtils.mkpath folderpath
            File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
            File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
            print "Default schedule is today, would you like to make another one ? [yes/no] (default: no): "
            answer = STDIN.gets().strip 
            schedule = 
                if answer=="yes" then
                    WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
                else
                    {
                        "uuid" => SecureRandom.hex,
                        "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                        "@"    => "today",
                        "unixtime" => Time.new.to_i
                    }
                end
            Wave::writeScheduleToDisk(uuid,schedule)
            if (datetimecode = LucilleCore::askQuestionAnswerAsString("datetime code ? (empty for none) : ")).size>0 then
                if (datetime = CommonsUtils::codeToDatetimeOrNull(datetimecode)) then
                    FlockOperator::setDoNotShowUntilDateTime(uuid, datetime)
                    EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(uuid, datetime))
                end
            end
            print "Move to a thread ? [yes/no] (default: no): "
            answer = STDIN.gets().strip 
            if answer=="yes" then
                CollectionsOperator::addObjectUUIDToCollectionInteractivelyChosen(uuid)
            end
            #LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('stream:') then
            description = expression[7, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = Stream::issueNewItemWithDescription(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('project:') then
            description = expression[8, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            collectionuuid = CollectionsOperator::createNewCollection_WithNameAndStyle(description, "PROJECT")
            puts "collection uuid: #{collectionuuid}"
            puts "collection name: #{description}"
            puts "collection path: #{CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('thread:') then
            description = expression[7, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            collectionuuid = CollectionsOperator::createNewCollection_WithNameAndStyle(description, "THREAD")
            puts "collection uuid: #{collectionuuid}"
            puts "collection name: #{description}"
            puts "collection path: #{CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?("r:on") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setSatisfifiedRequirement(requirement)
            return
        end

        if expression.start_with?("r:off") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setUnsatisfiedRequirement(requirement)
            return
        end

        if expression.start_with?("r:show") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            if requirement.nil? or requirement.size==0 then
                requirement = RequirementsOperator::selectRequirementFromExistingRequirementsOrNull()
            end
            loop {
                requirementObjects = FlockOperator::flockObjects().select{ |object| RequirementsOperator::getObjectRequirements(object['uuid']).include?(requirement) }
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", requirementObjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::interactiveDisplayObjectAndProcessCommand(selectedobject)
            }
            return
        end

        if expression.start_with?("search") then
            pattern = expression[6,expression.size].strip
            loop {
                searchobjects = FlockOperator::flockObjects().select{|object| CommonsUtils::object2Line_v0(object).downcase.include?(pattern.downcase) }
                break if searchobjects.size==0
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::interactiveDisplayObjectAndProcessCommand(selectedobject)
            }
            return
        end

        return if object.nil?

        # object needed

        if expression == '!G' then
            uuid = object["uuid"]
            NotGuardian::registerAsNonGuardian(uuid)
            return
        end

        if expression == ">c" then
            CollectionsOperator::addObjectUUIDToCollectionInteractivelyChosen(object["uuid"])
            return
        end

        if expression == '!today' then
            TodayOrNotToday::notToday(object["uuid"])
            return
        end

        if expression == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('+') then
            code = expression
            if (datetime = CommonsUtils::codeToDatetimeOrNull(code)) then
                FlockOperator::setDoNotShowUntilDateTime(object["uuid"], datetime)
                EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(object["uuid"], datetime))
            end
            return
        end

        if expression.start_with?("r:add") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::addRequirementToObject(object['uuid'],requirement)
            return
        end

        if expression.start_with?("r:remove") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::removeRequirementFromObject(object['uuid'],requirement)
            return
        end

        if expression.size > 0 then
            tokens = expression.split(" ").map{|t| t.strip }
            .each{|command|
                AgentsManager::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, command)
            }
        else
            AgentsManager::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, "")
        end
    end

    def self.main2(runId)
        workspaceSize = 1
        mainschedule = {}
        mainschedule["archives-gc"] = Time.new.to_i + Random::rand*86400
        mainschedule["events-gc"]   = Time.new.to_i + Random::rand*86400
        mainschedule["requirements-off-notification"] = Time.new.to_i + Random::rand*3600*2
        loop {
            AgentsManager::generalUpgrade()
            TodayOrNotToday::transform()
            RequirementsOperator::transform()
            CommonsUtils::fDoNotShowUntilDateTimeTransform()
            CollectionsOperator::transform()
            NotGuardian::transform()
            objects_selected = FlockOperator::flockObjects().sort{|o1,o2| o1['metric']<=>o2['metric'] }.reverse.take(workspaceSize)
            system("clear")
            if RequirementsOperator::getCurrentlyUnsatisfiedRequirements().size>0 then
                puts "REQUIREMENTS: OFF: #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".yellow
            end
            dayprogression = {
                "collections" => ( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/CollectionsOperator::dailyCommitmentInHours(),
                "stream"      => ( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/CollectionsOperator::dailyCommitmentInHours()
            }
            if dayprogression["collections"] >= 1 and dayprogression["stream"] >= 1 then
                puts "DAY PROGRESSION: (Collections, Stream) Cleared of duties. Enjoy while it last (^_^)".green
            else
                puts "DAY PROGRESSION: Collections: #{ (100*dayprogression["collections"]).to_i } % ; Stream: #{ (100*dayprogression["stream"]).to_i } %".red
            end
            if ( Time.new.to_i > mainschedule["archives-gc"] ) and CommonsUtils::isLucille18() then
                lines = CatalystDevOps::archivesTimelineGarbageCollection()
                puts "Archives timeline garbage collection: #{lines.size}"
                lines.each{|line|
                    puts "    - #{line}"
                }
                LucilleCore::pressEnterToContinue() if lines.size>0
                mainschedule["archives-gc"] = Time.new.to_i + Random::rand*86400
            end
            if ( Time.new.to_i > mainschedule["events-gc"] ) and CommonsUtils::isLucille18() then
                lines = CatalystDevOps::eventsTimelineGarbageCollection()
                puts "Events timeline garbage collection: #{lines.size}"
                lines.each{|line|
                    puts "    - #{line}"
                }
                LucilleCore::pressEnterToContinue() if lines.size>0
                mainschedule["events-gc"] = Time.new.to_i + Random::rand*86400
            end
            if ( Time.new.to_i > mainschedule["requirements-off-notification"] ) then
                if RequirementsOperator::getCurrentlyUnsatisfiedRequirements().size>0 then
                    puts "REQUIREMENTS OFF: #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}"
                    LucilleCore::pressEnterToContinue()
                end
                mainschedule["requirements-off-notification"] = Time.new.to_i + Random::rand*3600*2
                next
            end
            collectionuuid = CollectionsOperator::collectionsUUIDs()
                .select{ |collectionuuid| CollectionsOperator::getCollectionStyle(collectionuuid)=="THREAD" }
                .select{ |collectionuuid| Time.new.to_i >= CollectionsOperator::getNextReviewUnixtime(collectionuuid) }
                .first
            if collectionuuid then
                collectionname = CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)
                puts "Thread review: #{collectionname}"
                CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
                CollectionsOperator::setNextReviewUnixtime(collectionuuid)
                next
            end        
            puts ""
            object_selected = objects_selected.last.clone
            # --------------------------------------------------------------------------------
            # Sometimes a wave item that is an email, gets deleted by the Wave-Emails process.
            # In such a case they are still in Flock and should not be showed
            if object_selected["agent-uid"]=="283d34dd-c871-4a55-8610-31e7c762fb0d" then
                if object_selected["schedule"][":wave-emails:"] then
                    if !File.exists?(object_selected["item-data"]["folderpath"]) then
                        puts CommonsUtils::object2Line_v0(object_selected)
                        puts "This email has been deleted, removing Flock item:"
                        FlockOperator::removeObjectIdentifiedByUUID(object_selected["uuid"])
                        EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(object_selected["uuid"]))
                        next
                    end
                end
            end
            # --------------------------------------------------------------------------------
            objects_selected.each_with_index{|o, index|
                string =
                    if o["uuid"]==object_selected["uuid"] then
                        "#{"%2d" % (index+1)} [*] #{CommonsUtils::object2Line_v1(o)}"
                    else
                        "#{"%2d" % (index+1)}     #{CommonsUtils::object2Line_v0(o)}"
                    end
                puts string
            }
            print "--> "
            givenCommand = STDIN.gets().strip
            if givenCommand=="+" then
                workspaceSize = workspaceSize+1
                next
            end
            if givenCommand=="-" then
                workspaceSize = [workspaceSize-1, 1].max
                next
            end
            if CommonsUtils::isInteger(givenCommand) then
                workspaceSize = [givenCommand.to_i, 1].max
                next
            end
            if givenCommand.start_with?(":") and CommonsUtils::isInteger(givenCommand[1,9]) then
                object = objects_selected.take(givenCommand[1,9].to_i).last.clone
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                next
            end
            command = givenCommand.size>0 ? givenCommand : ( object_selected["default-expression"] ? object_selected["default-expression"] : "" )
            CommonsUtils::processObjectAndCommand(object_selected, command)
            File.open("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/run-identifier.data", "w") {|f| f.write(runId) }
        }
    end

    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts CommonsUtils::object2Line_v1(object)
        print "--> "
        givenCommand = STDIN.gets().strip
        command = givenCommand.size>0 ? givenCommand : ( object["default-expression"] ? object["default-expression"] : "" )
        CommonsUtils::processObjectAndCommand(object, command)
    end

    def self.newBinArchivesFolderpath()
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        targetFolder       
    end

end
