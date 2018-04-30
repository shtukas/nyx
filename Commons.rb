#!/usr/bin/ruby

# encoding: UTF-8

CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Archives-Timeline"
CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER = "/Galaxy/DataBank/Catalyst/Stream"

# Saturn::currentHour()
# Saturn::currentDay()

class Saturn
    def self.currentHour()
        Time.new.to_s[0,13]
    end
    def self.currentDay()
        Time.new.to_s[0,10]
    end
end

# DoNotShowUntil::set(uuid, datetime)
# DoNotShowUntil::transform(objects)

class DoNotShowUntil
    @@mapping = {}

    def self.init()
        @@mapping = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/do-not-show-until.json"))
    end

    def self.set(uuid, datetime)
        @@mapping[uuid] = datetime
        File.open("/Galaxy/DataBank/Catalyst/do-not-show-until.json", "w"){|f| f.puts(JSON.pretty_generate(@@mapping)) }
    end

    def self.isactive(object)
        return true if @@mapping[object["uuid"]].nil?
        return true if DateTime.now() >= DateTime.parse(@@mapping[object["uuid"]])
        false
    end

    def self.transform(objects)
        objects.map{|object|
            if !DoNotShowUntil::isactive(object) then
                object["do-not-show-metric"] = object["metric"]
                object["do-not-show-until-datetime"] = @@mapping[object["uuid"]]
                # next we try to promote any do-not-show-until-datetime contained in a shceduler of a wave item, with a target in the future
                if object["do-not-show-until-datetime"].nil? and object["schedule"] and object["schedule"]["do-not-show-until-datetime"] and (Time.new.to_s < object["schedule"]["do-not-show-until-datetime"]) then
                    object["do-not-show-until-datetime"] = object["schedule"]["do-not-show-until-datetime"]
                end
                object["metric"] = 0
            end
            object
        }
    end
end

class RequirementsOperator

    @@pathToDataFile = nil
    @@data = nil

    def self.init()
        @@pathToDataFile = "/Galaxy/DataBank/Catalyst/requirements/requirements-structure.json"
        @@data = JSON.parse(IO.read(@@pathToDataFile))
    end

    def self.saveDataToDisk()
        File.open(@@pathToDataFile, 'w') {|f| f.puts(JSON.pretty_generate(@@data)) }
    end

    def self.getObjectRequirements(uuid)
        @@data['items-requirements-distribution'][uuid] || []
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        @@data['requirements-status-timeline'][requirement].nil? or @@data['requirements-status-timeline'][requirement]
    end

    def self.meetRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.addObjectRequirement(uuid,requirement)
        requirements = @@data['items-requirements-distribution'][uuid] || []
        requirements << requirement
        requirements = requirements.uniq.sort
        @@data['items-requirements-distribution'][uuid] = requirements
        RequirementsOperator::saveDataToDisk()
    end

    def self.setRequirementOn(requirement)
        @@data['requirements-status-timeline'][requirement] = true
        RequirementsOperator::saveDataToDisk()
    end

    def self.setRequirementOff(requirement)
        @@data['requirements-status-timeline'][requirement] = false
        RequirementsOperator::saveDataToDisk()
    end

    def self.allRequirements()
        @@data['items-requirements-distribution'].values.flatten.uniq
    end

    def self.currentlyUnsatisfifiedRequirements()
        RequirementsOperator::allRequirements().select{|requirement| !RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end
end
