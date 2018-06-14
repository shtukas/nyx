
# encoding: UTF-8


# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# ---------------------------------------------------
# Utils

# ProjectsCore::projectsUUIDs()
# ProjectsCore::projectUUID2NameOrNull(projectuuid)

# ---------------------------------------------------
# creation

# ProjectsCore::createNewProject(projectname)

# ---------------------------------------------------
# projects uuids

# ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
# ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(objectuuid, projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
# ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(projectuuid)

# ---------------------------------------------------
# isGuardianTime?(projectuuid)

# ProjectsCore::isGuardianTime?(projectuuid)
# ProjectsCore::setTimePointGenerator(projectuuid, periodInSeconds, timepointDurationInSeconds)
# ProjectsCore::getTimePointGeneratorOrNull(projectuuid): [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
# ProjectsCore::resetTimePointGenerator(projectuuid)

# ---------------------------------------------------
# Misc

# ProjectsCore::transform()
# ProjectsCore::deleteProject(uuid)

# ---------------------------------------------------
# User Interface

# ProjectsCore::interactivelySelectProjectUUIDOrNUll()
# ProjectsCore::ui_ProjectsDive()
# ProjectsCore::ui_ProjectDive(projectuuid)
# ProjectsCore::deleteProject(projectuuid)


class ProjectsCore

    # ---------------------------------------------------
    # Utils

    def self.projectsUUIDs()
        JSON.parse(FKVStore::getOrDefaultValue(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, "[]"))
    end

    def self.projectUUID2NameOrNull(uuid)
        FKVStore::getOrNull("AE2252BF-4915-4170-8435-C8C05EA4283C:#{uuid}")
    end

    # ---------------------------------------------------
    # creation

    def self.createNewProject(projectname)
        projectuuid = SecureRandom.hex(4)
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(ProjectsCore::projectsUUIDs()+[projectuuid]))
        FKVStore::set("AE2252BF-4915-4170-8435-C8C05EA4283C:#{projectuuid}", projectname)
        projectuuid
    end

    # ---------------------------------------------------
    # projects uuids

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
    end

    def self.projectCatalystObjectUUIDsThatAreAlive(projectuuid)
        a1 = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
        a2 = TheFlock::flockObjects().map{|object| object["uuid"] }
        a1 & a2
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

    def self.deleteProject(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(projectuuid).size>0 then
            puts "You cannot complete this item because it has objects"
            LucilleCore::pressEnterToContinue()
            return
        end
        projectuuids = ( ProjectsCore::projectsUUIDs() - [projectuuid] ).uniq
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(projectuuids))
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_destroyProject(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You now need to destroy all the objects"
            LucilleCore::pressEnterToContinue()
            loop {
                break if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size==0
                ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                    .map{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
                    .compact
                    .each{|object|
                        CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                    }
            }
        end
        puts "ProjectsCore::deleteProject"
        ProjectsCore::deleteProject(projectuuid)       
    end

    def self.ui_ProjectDive(projectuuid)
        loop {
            catalystobjects = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                .map{|objectuuid| TheFlock::flockObjects().select{|object| object["uuid"]==objectuuid }.first }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem5 = "operation : destroy"            
            menuStringsOrCatalystObjects = catalystobjects
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem5 ]
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
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this project ? ") and LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Seriously ? ") then
                    ProjectsCore::ui_destroyProject(projectuuid)
                end
                return
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.ui_ProjectsDive()
        loop {
            toString = lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) }
            projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", ProjectsCore::projectsUUIDs(), toString)
            break if projectuuid.nil?
            ProjectsCore::ui_ProjectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

end