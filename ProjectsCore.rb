
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------
# Utils

# ProjectsCore::projectsUUIDs()
# ProjectsCore::projectUUID2NameOrNull(projectuuid)

# -------------------------------------------------------------
# creation

# ProjectsCore::createNewProject(projectname)

# -------------------------------------------------------------
# projects uuids

# ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
# ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(objectuuid, projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)

# -------------------------------------------------------------
# isGuardianTime?(projectuuid)

# ProjectsCore::isGuardianTime?(projectuuid)
# ProjectsCore::setTimePointGenerator(projectuuid, periodInSeconds, timepointDurationInSeconds)
# ProjectsCore::getTimePointGeneratorOrNull(projectuuid): [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
# ProjectsCore::resetTimePointGenerator(projectuuid)

# -------------------------------------------------------------
# Misc

# ProjectsCore::transform()
# ProjectsCore::deleteProject2(uuid)

# -------------------------------------------------------------
# User Interface

# ProjectsCore::interactivelySelectProjectUUIDOrNUll()
# ProjectsCore::ui_projectsDive()
# ProjectsCore::ui_projectDive(projectuuid)
# ProjectsCore::deleteProject2(projectuuid)

# -------------------------------------------------------------

class ProjectsCore
    # ---------------------------------------------------
    # Utils

    def self.fs_location2UUID(location)
        if File.directory?(location) then
            uuidFilepath = "#{location}/.uuid"
            if !File.exists?(uuidFilepath) then
                File.open(uuidFilepath, "w"){|f| f.write(SecureRandom.hex(4)) }
            end
            IO.read(uuidFilepath).strip
        else
            Digest::SHA1.hexdigest("3fa3a298-8941-4c9e-8b59-f1bc867e517d:#{location}")[0,8]
        end
    end

    def self.fs_locations()
        Dir.entries("/Galaxy/Projects")
            .select{|filename| (filename[0,1] != ".") and (filename != 'Icon'+["0D"].pack("H*")) }
            .map{|filename| "/Galaxy/Projects/#{filename}" }
    end

    def self.fs_uuidIsFileSystemProject(uuid)
        ProjectsCore::fs_locations()
            .any?{|location| uuid == ProjectsCore::fs_location2UUID(location) }
    end

    def self.projectsUUIDs()
        uuids1 = JSON.parse(FKVStore::getOrDefaultValue(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, "[]"))
        uuids2 = ProjectsCore::fs_locations()
            .map{|location| ProjectsCore::fs_location2UUID(location) }
        uuids1 + uuids2
    end

    def self.projectUUID2NameOrNull(projectuuid)
        ProjectsCore::fs_locations()
            .select{|location| projectuuid == ProjectsCore::fs_location2UUID(location) }
            .each{|location|
                return File.basename(location)
            }
        FKVStore::getOrNull("AE2252BF-4915-4170-8435-C8C05EA4283C:#{projectuuid}")
    end

    # ---------------------------------------------------
    # creation

    def self.setProjectName(projectuuid, projectname)
        FKVStore::set("AE2252BF-4915-4170-8435-C8C05EA4283C:#{projectuuid}", projectname)
    end

    def self.createNewProject(projectname)
        projectuuid = SecureRandom.hex(4)
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(ProjectsCore::projectsUUIDs()+[projectuuid]))
        ProjectsCore::setProjectName(projectuuid, projectname)
        projectuuid
    end

    # ---------------------------------------------------
    # projects objects

    def self.addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        uuids = ( ProjectsCore::projectCatalystObjectUUIDs(projectuuid) + [objectuuid] ).uniq
        FKVStore::set("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", JSON.generate(uuids))
    end

    def self.addObjectUUIDToProjectInteractivelyChosen(objectuuid)
        projectuuid = ProjectsCore::interactivelySelectProjectUUIDOrNUll()
        if projectuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new project ? ") then
                projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                projectuuid = ProjectsCore::createNewProject(projectname)
            else
                return
            end
        end
        ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        projectuuid
    end

    def self.projectCatalystObjectUUIDs(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .select{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
    end

    def self.projectCatalystObjects(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .map{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
            .compact
    end



    # ---------------------------------------------------
    # Time management & isGuardianTime?(projectuuid)

    def self.isGuardianTime?(projectuuid)
        answer = FKVStore::getOrNull("80f13003-e618-490c-9307-a2b6aecb69c5:#{projectuuid}")
        if answer.nil? then
            answer = LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("#{ProjectsCore::projectUUID2NameOrNull(projectuuid)} is Guardian time? ")
            FKVStore::set("80f13003-e618-490c-9307-a2b6aecb69c5:#{projectuuid}", JSON.generate([answer]))
        else
            answer = JSON.parse(answer)[0]
        end
        answer
    end

    def self.setTimePointGenerator(projectuuid, periodInSeconds, timepointDurationInSeconds)
        FKVStore::set("5AB553E7-B9E1-4F7C-B183-D0388538C940:#{projectuuid}", JSON.generate([Time.new.to_i, periodInSeconds, timepointDurationInSeconds]))      
    end

    def self.getTimePointGeneratorOrNull(projectuuid)
        generator = FKVStore::getOrNull("5AB553E7-B9E1-4F7C-B183-D0388538C940:#{projectuuid}")
        return nil if generator.nil?
        JSON.parse(generator)
    end

    def self.resetTimePointGenerator(projectuuid)
        # This function is called by AgentTimeGenesis when a new time point is issued
        generator = getTimePointGeneratorOrNull(projectuuid)
        return if generator.nil?
        self.setTimePointGenerator(projectuuid, generator[1], generator[2])
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = ProjectsCore::projectsUUIDs()
            .map{|projectuuid| ProjectsCore::projectCatalystObjectUUIDs(projectuuid) }
            .flatten
        TheFlock::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
                TheFlock::addOrUpdateObject(object)
            end
        }
    end

    def self.deleteProject2(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You cannot complete this project because it has objects"
            LucilleCore::pressEnterToContinue()
            return
        end
        if ProjectsCore::fs_uuidIsFileSystemProject(projectuuid) then
            puts "You cannot complete this project because it is a file system based project"
            LucilleCore::pressEnterToContinue()
            return
        end
        projectuuids = ( ProjectsCore::projectsUUIDs() - [projectuuid] ).uniq
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(projectuuids))
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_projectTimePointGeneratorAsStringContantLength(projectuuid)
        timePointGenerator = ProjectsCore::getTimePointGeneratorOrNull(projectuuid)
        if timePointGenerator then
            "#{"%4.2f" % (timePointGenerator[2].to_f/3600)} hours / #{"%4.2f" % (timePointGenerator[1].to_f/86400)} days"
        else
            "                      "
        end
    end

    def self.ui_projectDive(projectuuid)
        puts "-> #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
        loop {
            catalystobjects = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                .map{|objectuuid| TheFlock::flockObjects().select{|object| object["uuid"]==objectuuid }.first }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem3 = "operation : set name" 
            menuItem4 = "operation : set time generator"  
            menuItem5 = "operation : destroy"            
            menuStringsOrCatalystObjects = catalystobjects
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem3, menuItem4, menuItem5 ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    "object    : #{CommonsUtils::object2Line_v0(object)}"
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == menuItem3 then
                ProjectsCore::setProjectName(
                    projectuuid, 
                    LucilleCore::askQuestionAnswerAsString("Name: "))
                next
            end
            if menuChoice == menuItem4 then
                ProjectsCore::setTimePointGenerator(
                        projectuuid, 
                        LucilleCore::askQuestionAnswerAsString("Period in days: ").to_f*86400, 
                        LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f*3600)
                next
            end
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this project ? ") then
                    ProjectsCore::ui_deleteProject1(projectuuid)
                end
                next
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.projectTimePoints(projectuuid)
        TimePointsCore::getTimePoints().select{|timepoint| timepoint["domain"]==projectuuid }
    end

    def self.projectTimeDueInHours(projectuuid)
        ProjectsCore::projectTimePoints(projectuuid)
            .map{|timepoint| TimePointsCore::timepointToLiveDueinHours(timepoint) }
            .inject(0, :+)
    end

    def self.ui_projectsDive()
        ProjectsCore::projectsUUIDs().each{|projectuuid|
            ProjectsCore::isGuardianTime?(projectuuid)
        }
        loop {
            toString = lambda{ |projectuuid| 
                "#{ProjectsCore::ui_projectTimePointGeneratorAsStringContantLength(projectuuid)} | #{ ProjectsCore::isGuardianTime?(projectuuid) ? "guardian" : "        " } | #{ProjectsCore::fs_uuidIsFileSystemProject(projectuuid) ? "fs" : "  " } | #{"%5.2f" % ProjectsCore::projectTimeDueInHours(projectuuid)} | #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}" 
            }
            projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", ProjectsCore::projectsUUIDs().sort{|projectuuid1, projectuuid2| ProjectsCore::projectTimeDueInHours(projectuuid1) <=> ProjectsCore::projectTimeDueInHours(projectuuid2) }.reverse, toString)
            break if projectuuid.nil?
            ProjectsCore::ui_projectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

    def self.ui_deleteProject1(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You now need to destroy all the objects"
            LucilleCore::pressEnterToContinue()
            loop {
                objects = projectCatalystObjectUUIDs(projectuuid)
                break if objects.size==0
                objects.each{|object|
                        CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                    }
            }
        end
        puts "ProjectsCore::deleteProject2"
        ProjectsCore::deleteProject2(projectuuid)
    end
end