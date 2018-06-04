#!/usr/bin/ruby

# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "Flock.rb"
require_relative "FlockBasedServices.rb"

# ----------------------------------------------------------------

# Config::get(keyname)

class Config
    def self.getConfig()
        JSON.parse(IO.read(CATALYST_COMMON_CONFIG_FILEPATH))
    end
    def self.get(keyname)
        self.getConfig()[keyname]
    end
end

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

        if expression == 'lib' then
            LibrarianExportedFunctions::librarianUserInterface_librarianInteractive()
            return
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
                OperatorCollections::addObjectUUIDToCollectionInteractivelyChosen(uuid)
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
            collectionuuid = OperatorCollections::createNewCollection_WithNameAndStyle(description, "PROJECT")
            puts "collection uuid: #{collectionuuid}"
            puts "collection name: #{description}"
            puts "collection path: #{OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('thread:') then
            description = expression[7, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            collectionuuid = OperatorCollections::createNewCollection_WithNameAndStyle(description, "THREAD")
            puts "collection uuid: #{collectionuuid}"
            puts "collection name: #{description}"
            puts "collection path: #{OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == "collections" then
            collectionsuuids = OperatorCollections::collectionsUUIDs()
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collections", collectionsuuids, lambda{ |collectionuuid| OperatorCollections::collectionUUID2NameOrNull(collectionuuid) })
            return if collectionuuid.nil?
            OperatorCollections::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "collections:new" then
            collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
            style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
            OperatorCollections::createNewCollection_WithNameAndStyle(collectionname, style)
            return
        end

        if expression == "threads" then
            collectionsuuids = OperatorCollections::collectionsUUIDs()
                .select{ |collectionuuid| OperatorCollections::getCollectionStyle(collectionuuid)=="THREAD" }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("threads", collectionsuuids, lambda{ |collectionuuid| OperatorCollections::collectionUUID2NameOrNull(collectionuuid) })
            return if collectionuuid.nil?
            OperatorCollections::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "projects" then
            collectionsuuids = OperatorCollections::collectionsUUIDs()
                .select{ |collectionuuid| OperatorCollections::getCollectionStyle(collectionuuid)=="PROJECT" }
                .sort{|puuid1, puuid2| AgentCollections::objectMetricAsFloat(puuid1) <=> AgentCollections::objectMetricAsFloat(puuid2) }
                .reverse
            displayLambda = lambda{ |collectionuuid| "(#{"%.3f" % AgentCollections::objectMetricAsFloat(collectionuuid)}) [#{AgentCollections::objectMetricsAsString(collectionuuid)}] #{OperatorCollections::collectionUUID2NameOrNull(collectionuuid)}" }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", collectionsuuids, displayLambda)
            return if collectionuuid.nil?
            OperatorCollections::ui_mainDiveIntoCollection_v2(collectionuuid)
            return
        end

        if expression == "threads-review" then
            OperatorCollections::collectionsUUIDs()
                .select{ |collectionuuid| OperatorCollections::getCollectionStyle(collectionuuid)=="THREAD" }
                .each{ |collectionuuid|
                    puts "# ---------------------------------------------------"
                    collectionname = OperatorCollections::collectionUUID2NameOrNull(collectionuuid)
                    if collectionname.nil? then
                        puts "Error 4ba7f95a: Could not determine the name of collection: #{collectionuuid}"
                        LucilleCore::pressEnterToContinue()
                        next
                    end
                    puts "Thread name: #{collectionname}"
                    OperatorCollections::ui_mainDiveIntoCollection_v2(collectionuuid)
                }         
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

        if expression == ">c" then
            OperatorCollections::addObjectUUIDToCollectionInteractivelyChosen(object["uuid"])
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
            OperatorCollections::transform()
            objects_selected = FlockOperator::flockObjects().sort{|o1,o2| o1['metric']<=>o2['metric'] }.reverse.take(workspaceSize)
            system("clear")
            if RequirementsOperator::getCurrentlyUnsatisfiedRequirements().size>0 then
                puts "REQUIREMENTS: OFF: #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".yellow
            end
            dayprogression = {
                "collections" => ( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/OperatorCollections::dailyCommitmentInHours(),
                "stream"      => ( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTSTREAM_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/OperatorCollections::dailyCommitmentInHours()
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
        command = givenCommand.size>0 ? givenCommand : ( object["default-expression"] ? object_selected["default-expression"] : "" )
        CommonsUtils::processObjectAndCommand(object, command)
    end

    def self.newBinArchivesFolderpath()
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        targetFolder       
    end

end

# ----------------------------------------------------------------------

# AgentsManager::agents()
# AgentsManager::agentuuid2AgentData(agentuuid)
# AgentsManager::generalUpgrade()

class AgentsManager

    def self.agents()
        [
            {
                "agent-name"      => "Collections",
                "agent-uid"       => "e4477960-691d-4016-884c-8694db68cbfb",
                "general-upgrade" => lambda { AgentCollections::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| AgentCollections::processObjectAndCommand(object, command) },
                "interface"       => lambda{ AgentCollections::interface() }
            },
            {
                "agent-name"      => "GuardianTime",
                "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "general-upgrade" => lambda { GuardianTime::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| GuardianTime::processObjectAndCommand(object, command) },
                "interface"       => lambda{ GuardianTime::interface() }
            },
            {
                "agent-name"      => "Ninja",
                "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "general-upgrade" => lambda { Ninja::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Ninja::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Ninja::interface() }
            },
            {
                "agent-name"      => "Stream",
                "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "general-upgrade" => lambda { Stream::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Stream::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Stream::interface() }
            },
            {
                "agent-name"      => "TimeCommitments",
                "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "general-upgrade" => lambda { TimeCommitments::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| TimeCommitments::processObjectAndCommand(object, command) },
                "interface"       => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"      => "Today",
                "agent-uid"       => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "general-upgrade" => lambda { Today::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Today::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Today::interface() }
            },
            {
                "agent-name"      => "Vienna",
                "agent-uid"       => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "general-upgrade" => lambda { Vienna::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Vienna::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Vienna::interface() }
            },
            {
                "agent-name"      => "Wave",
                "agent-uid"       => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "general-upgrade" => lambda { Wave::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Wave::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2AgentData(agentuuid)
        AgentsManager::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end

    def self.generalUpgrade()
        AgentsManager::agents().each{|agentinterface| agentinterface["general-upgrade"].call() }
    end
end

# RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
# RequirementsOperator::setUnsatisfiedRequirement(requirement)
# RequirementsOperator::setSatisfifiedRequirement(requirement)
# RequirementsOperator::requirementIsCurrentlySatisfied(requirement)

# RequirementsOperator::getObjectRequirements(uuid)
# RequirementsOperator::setObjectRequirements(uuid, requirements)
# RequirementsOperator::addRequirementToObject(uuid,requirement)
# RequirementsOperator::removeRequirementFromObject(uuid,requirement)
# RequirementsOperator::objectMeetsRequirements(uuid)

# RequirementsOperator::getAllRequirements()
# RequirementsOperator::transform()

class RequirementsOperator

    def self.getCurrentlyUnsatisfiedRequirements()
        JSON.parse(FKVStore::getOrDefaultValue("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", "[]"))
    end

    def self.setUnsatisfiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        FKVStore::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.setSatisfifiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        FKVStore::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # objects

    def self.getObjectRequirements(uuid)
        JSON.parse(FKVStore::getOrDefaultValue("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", "[]"))
    end

    def self.setObjectRequirements(uuid, requirements)
        FKVStore::set("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", JSON.generate(requirements))
    end

    def self.addRequirementToObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid) + [requirement]).uniq)
    end

    def self.removeRequirementFromObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid).reject{|r| r==requirement }))
    end

    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.getAllRequirements()
        FlockOperator::flockObjects().map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.transform()
        FlockOperator::flockObjects().each{|object|
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end
end

# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)
# TodayOrNotToday::transform()

class TodayOrNotToday
    def self.notToday(uuid)
        FKVStore::set("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        FKVStore::getOrNull("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}").nil?
    end
    def self.transform()
        FlockOperator::flockObjects().each{|object|
            if !TodayOrNotToday::todayOk(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end
end

# FolderProbe::nonDotFilespathsAtFolder(folderpath)
# FolderProbe::folderpath2metadata(folderpath)
    #    {
    #        "target-type" => "folder"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "openable-file"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "line",
    #        "text" => line
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "url",
    #        "url" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "virtually-empty-wave-folder",
    #        "announce" =>
    #    }

# FolderProbe::openActionOnMetadata(metadata)

class FolderProbe
    def self.nonDotFilespathsAtFolder(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1]!="." }
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    def self.folderpath2metadata(folderpath)

        metadata = {}

        # --------------------------------------------------------------------
        # Trying to read a description file

        getDescriptionFilepathMaybe = lambda{|folderpath|
            filepaths = FolderProbe::nonDotFilespathsAtFolder(folderpath)
            if filepaths.any?{|filepath| File.basename(filepath).include?("description.txt") } then
                filepaths.select{|filepath| File.basename(filepath).include?("description.txt") }.first
            else
                nil
            end
        }

        getDescriptionFromDescriptionFileMaybe = lambda{|folderpath|
            filepathOpt = getDescriptionFilepathMaybe.call(folderpath)
            if filepathOpt then
                IO.read(filepathOpt).strip
            else
                nil
            end
        }

        descriptionOpt = getDescriptionFromDescriptionFileMaybe.call(folderpath)
        if descriptionOpt then
            metadata["announce"] = descriptionOpt
            if descriptionOpt.start_with?("http") then
                metadata["target-type"] = "url"
                metadata["url"] = descriptionOpt
                return metadata
            end
        end

        # --------------------------------------------------------------------
        #

        files = FolderProbe::nonDotFilespathsAtFolder(folderpath)
                .select{|filepath| !File.basename(filepath).start_with?('wave') }
                .select{|filepath| !File.basename(filepath).start_with?('catalyst') }

        fileIsOpenable = lambda {|filepath|
            File.basename(filepath)[-4,4]==".txt" or
            File.basename(filepath)[-4,4]==".eml" or
            File.basename(filepath)[-4,4]==".jpg" or
            File.basename(filepath)[-4,4]==".png" or
            File.basename(filepath)[-4,4]==".gif" or
            File.basename(filepath)[-7,7]==".webloc"
        }

        openableFiles = files
                .select{|filepath| fileIsOpenable.call(filepath) }


        filesWithoutTheDescription = files
                .select{|filepath| !File.basename(filepath).include?('description.txt') }

        extractURLFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            line = contents.lines.first.strip
            line = CommonsUtils::simplifyURLCarryingString(line)
            return nil if !line.start_with?("http")
            line
        }

        extractLineFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            contents.lines.first.strip
        }

        if File.exists?("#{folderpath}/email-metatada-emailuid.txt") then
            metadata["target-type"] = "openable-file"
            emailFilename = Dir.entries(folderpath).select{|filename| filename[-4, 4]==".eml" }.first
            metadata["target-location"] = "#{folderpath}/#{emailFilename}"
            if metadata["announce"].nil? then
                metadata["announce"] = "[email]"
            end
            metadata["folderpath2metadata:case"] = "cf6f25cb"
            return metadata
        end

        if files.size==0 then
            # There is one open able file in the folder
            metadata["target-type"] = "virtually-empty-wave-folder"
            if metadata["announce"].nil? then
                metadata["announce"] = folderpath
            end
            metadata["folderpath2metadata:case"] = "b6e8ac55"
            return metadata
        end

        if files.size==1 and ( url = extractURLFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "url"
            metadata["url"] = url
            if metadata["announce"].nil? then
                metadata["announce"] = url
            end
            metadata["folderpath2metadata:case"] = "95e7dd30"
            return metadata
        end

        if files.size==1 and ( line = extractLineFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "line"
            metadata["text"] = line
            if metadata["announce"].nil? then
                metadata["announce"] = line
            end
            metadata["folderpath2metadata:case"] = "a888e991"
            return metadata
        end

        if files.size==1 and openableFiles.size==1 then
            filepath = files.first
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filepath
            if metadata["announce"].nil? then
                metadata["announce"] = File.basename(filepath)
            end
            metadata["folderpath2metadata:case"] = "54b1a4b5"
            return metadata
        end

        if files.size==1 and openableFiles.size!=1 then
            filepath = files.first
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "One non-openable file in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "439bba64"
            return metadata
        end

        if files.size > 1 and filesWithoutTheDescription.size==1 and fileIsOpenable.call(filesWithoutTheDescription.first) then
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filesWithoutTheDescription.first
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "29d2dc25"
            return metadata
        end

        if files.size > 1 then
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "f6a683b0"
            return metadata
        end
    end

    def self.openActionOnMetadata(metadata)
        if metadata["target-type"]=="folder" then
            if File.exists?(metadata["target-location"]) then
                system("open '#{metadata["target-location"]}'")
            else
                puts "Error: folder #{metadata["target-location"]} doesn't exist."
                LucilleCore::pressEnterToContinue()
            end
        end
        if metadata["target-type"]=="openable-file" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="line" then

        end
        if metadata["target-type"]=="url" then
            if CommonsUtils::isLucille18() then
                system("open '#{metadata["url"]}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{metadata["url"]}'")
            end
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then

        end
    end
end

# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::adaptedTimespanInSeconds(uuid)
# GenericTimeTracking::metric2(uuid, low, high, hourstoMinusOne)
# GenericTimeTracking::timings(uuid)

class GenericTimeTracking
    def self.status(uuid)
        JSON.parse(FKVStore::getOrDefaultValue("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.start(uuid)
        status = GenericTimeTracking::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = GenericTimeTracking::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        MiniFIFOQ::push("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
        status = [false, nil]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.adaptedTimespanInSeconds(uuid)
        adaptedTimespanInSeconds = MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = GenericTimeTracking::adaptedTimespanInSeconds(uuid)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end

    def self.timings(uuid)
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end

# CatalystDevOps::today()
# CatalystDevOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystDevOps::getFilepathAgeInDays(filepath)

# CatalystDevOps::getArchiveTimelineSizeInMegaBytes()
# CatalystDevOps::archivesTimelineGarbageCollectionStandard(): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollection(): Array[String]

# CatalystDevOps::eventsTimelineGarbageCollection()

class CatalystDevOps

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    CatalystDevOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------
    # Archives

    def self.getArchiveTimelineSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.archivesTimelineGarbageCollectionStandard()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        lines
    end

    def self.archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes)
        lines = []
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        line
    end

    def self.archivesTimelineGarbageCollection()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            CatalystDevOps::archivesTimelineGarbageCollectionFast(CatalystDevOps::getArchiveTimelineSizeInMegaBytes())
                .each{|line| lines << line }
        end
        lines
    end

    # -------------------------------------------
    # Events Timeline

    def self.canRemoveEvent(head, tail)
        if head["event-type"] == "Catalyst:Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object"]["uuid"] }
        end
        if head["event-type"] == "Catalyst:Destroy-Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object-uuid"] }
        end
        if head["event-type"] == "Catalyst:Metadata:DoNotShowUntilDateTime:1" then
            return DateTime.parse(head["datetime"]).to_time.to_i < Time.new.to_i
        end
        if head["event-type"] == "Flock:KeyValueStore:Set:1" then
            return tail.any?{|e| e["event-type"]=="Flock:KeyValueStore:Set:1" and e["key"]==head["key"] }
        end
        raise "Don't know how to garbage collect head: \n#{JSON.pretty_generate(head)}"
    end

    def self.eventsTimelineGarbageCollection()
        lines = []
        events = EventsManager::eventsEnumerator().to_a
        while events.size>=2 do
            event = events.shift
            if CatalystDevOps::canRemoveEvent(event, events) then
                eventfilepath = event[":filepath:"]
                lines << eventfilepath
                FileUtils.rm(eventfilepath)
            end
        end
        lines
    end
end

# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# OperatorCollections::collectionsFolderpaths()
# OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)
# OperatorCollections::folderPath2CollectionName(folderpath)
# OperatorCollections::folderPath2CollectionObject(folderpath)
# OperatorCollections::collectionUUID2FolderpathOrNull(uuid)
# OperatorCollections::collectionsUUIDs()
# OperatorCollections::collectionsNames()
# OperatorCollections::collectionUUID2NameOrNull(collectionuuid)

# OperatorCollections::textContents(collectionuuid)
# OperatorCollections::documentsFilenames(collectionuuid)

# OperatorCollections::createNewCollection_WithNameAndStyle(collectionname, style)

# OperatorCollections::addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
# OperatorCollections::addObjectUUIDToCollectionInteractivelyChosen(objectuuid, threaduuid)
# OperatorCollections::collectionCatalystObjectUUIDs(threaduuid)
# OperatorCollections::collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
# OperatorCollections::allCollectionsCatalystUUIDs()

# OperatorCollections::setCollectionStyle(collectionuuid, style)
# OperatorCollections::getCollectionStyle(collectionuuid)

# OperatorCollections::transform()
# OperatorCollections::sendCollectionToBinTimeline(uuid)
# OperatorCollections::dailyCommitmentInHours()

# OperatorCollections::ui_loopDiveCollectionObjects(collectionuuid)
# OperatorCollections::ui_mainDiveIntoCollection_v2(collectionuuid)

class OperatorCollections

    # ---------------------------------------------------
    # Utils

    def self.collectionsFolderpaths()
        Dir.entries(CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH)
            .select{|filename| filename[0,1]!="." }
            .sort
            .map{|filename| "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{filename}" }
    end

    def self.collectionsUUIDs()
        OperatorCollections::collectionsFolderpaths().map{|folderpath| OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath) }
    end

    def self.collectionsNames()
        OperatorCollections::collectionsFolderpaths().map{|folderpath| OperatorCollections::folderPath2CollectionName(folderpath) }
    end

    def self.folderPath2CollectionUUIDOrNull(folderpath)
        IO.read("#{folderpath}/collection-uuid")
    end

    def self.folderPath2CollectionName(folderpath)
        IO.read("#{folderpath}/collection-name")
    end

    def self.collectionUUID2FolderpathOrNull(uuid)
        OperatorCollections::collectionsFolderpaths()
            .each{|folderpath|
                return folderpath if OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.collectionUUID2NameOrNull(uuid)
        OperatorCollections::collectionsFolderpaths()
            .each{|folderpath|
                return IO.read("#{folderpath}/collection-name").strip if OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    # ---------------------------------------------------
    # text and documents

    def self.textContents(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return "" if folderpath.nil?
        IO.read("#{folderpath}/collection-text.txt")
    end    

    def self.documentsFilenames(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return [] if folderpath.nil?
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }
    end

    # ---------------------------------------------------
    # creation

    def self.createNewCollection_WithNameAndStyle(collectionname, style)
        collectionuuid = SecureRandom.hex(4)
        foldername = LucilleCore::timeStringL22()
        folderpath = "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{foldername}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/collection-uuid", "w"){|f| f.write(collectionuuid) }
        File.open("#{folderpath}/collection-name", "w"){|f| f.write(collectionname) }
        File.open("#{folderpath}/collection-catalyst-uuids.json", "w"){|f| f.puts(JSON.generate([])) }
        FileUtils.touch("#{folderpath}/collection-text.txt")
        FileUtils.mkpath "#{folderpath}/documents"
        self.setCollectionStyle(collectionuuid, style)
        collectionuuid
    end

    # ---------------------------------------------------
    # collections uuids

    def self.addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(threaduuid)
        arrayFilepath = "#{folderpath}/collection-catalyst-uuids.json"
        array = JSON.parse(IO.read(arrayFilepath))
        array << objectuuid 
        array = array.uniq
        File.open(arrayFilepath, "w"){|f| f.puts(JSON.generate(array)) }
    end

    def self.addObjectUUIDToCollectionInteractivelyChosen(objectuuid)
        collectionsuuids = OperatorCollections::collectionsUUIDs()
        collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collections", collectionsuuids, lambda{ |collectionuuid| OperatorCollections::collectionUUID2NameOrNull(collectionuuid) })
        if collectionuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new collection ? ") then
                collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
                style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
                collectionuuid = OperatorCollections::createNewCollection_WithNameAndStyle(collectionname, style)
            else
                return
            end
        end
        OperatorCollections::addCatalystObjectUUIDToCollection(objectuuid, collectionuuid)
        collectionuuid
    end

    def self.collectionCatalystObjectUUIDs(collectionuuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
        JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json"))
    end

    def self.collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
        a1 = OperatorCollections::collectionCatalystObjectUUIDs(collectionuuid)
        a2 = FlockOperator::flockObjects().map{|object| object["uuid"] }
        a1 & a2
    end

    def self.allCollectionsCatalystUUIDs()
        OperatorCollections::collectionsFolderpaths()
            .map{|folderpath| JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json")) }
            .flatten
    end

    # ---------------------------------------------------
    # style

    def self.setCollectionStyle(collectionuuid, style)
        if !["THREAD", "PROJECT"].include?(style) then
            raise "Incorrect Style: #{style}, should be THREAD or PROJECT"
        end
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        File.open(filepath, "w"){|f| f.write(style) }
    end

    def self.getCollectionStyle(collectionuuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        IO.read(filepath).strip        
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = self.allCollectionsCatalystUUIDs()
        FlockOperator::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end

    def self.sendCollectionToBinTimeline(uuid)
        sourcefilepath = OperatorCollections::collectionUUID2FolderpathOrNull(uuid)
        return if sourcefilepath.nil?
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        puts "source: #{sourcefilepath}"
        puts "target: #{targetFolder}"
        LucilleCore::copyFileSystemLocation(sourcefilepath, targetFolder)
        LucilleCore::removeFileSystemLocation(sourcefilepath)
    end

    def self.dailyCommitmentInHours()
        6
    end

    def self.ui_loopDiveCollectionObjects(collectionuuid)
        loop {
            objects = OperatorCollections::collectionCatalystObjectUUIDs(collectionuuid)
                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            break if objects.empty?
            object = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object:", objects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
            break if object.nil?
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.ui_mainDiveIntoCollection_v2(collectionuuid)
        loop {
            style = OperatorCollections::getCollectionStyle(collectionuuid)
            textContents = OperatorCollections::textContents(collectionuuid)
            documentsFilenames = OperatorCollections::documentsFilenames(collectionuuid)
            catalystobjects = OperatorCollections::collectionCatalystObjectUUIDs(collectionuuid)
                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuStringsOrCatalystObjects = catalystobjects + ["open text file (#{textContents.strip.size})", "visit documents (#{documentsFilenames.size})", "recast as project", "destroy" ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    CommonsUtils::object2Line_v0(object)
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == "open text file (#{textContents.strip.size})" then
                folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/collection-text.txt'")
                next
            end
            if menuChoice == "visit documents (#{documentsFilenames.size})" then
                folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/documents'")
                next
            end
            if menuChoice == "destroy" then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this #{style.downcase} ? ") and LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Seriously ? ") then
                    if catalystobjects.size>0 then
                        puts "You now need to destroy all the objects"
                        LucilleCore::pressEnterToContinue()
                        loop {
                            catalystobjects = OperatorCollections::collectionCatalystObjectUUIDs(collectionuuid)
                                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                                .compact
                                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                                .reverse
                            break if catalystobjects.size==0
                            object = catalystobjects.first
                            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                        }
                    end
                    puts "Moving collection folder to bin timeline"
                    collectionfolderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
                    targetFolder = CommonsUtils::newBinArchivesFolderpath()
                    FileUtils.mv(collectionfolderpath, targetFolder)
                end
                return
            end
            if menuChoice == "recast as project" then
                OperatorCollections::setCollectionStyle(collectionuuid, "PROJECT")
                return
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

end

# -------------------------------------------------------------
