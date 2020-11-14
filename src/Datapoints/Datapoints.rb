
# encoding: UTF-8

class Datapoints

    # Datapoints::makeNewDatapointOrNull()
    def self.makeNewDatapointOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["quark/lepton", "NGX15", "container"])
        if type == "quark/lepton" then
            return Quarks::interactivelyIssueQuarkOrNull()
        end
        if type == "NGX15" then
            return NGX15::issueNewNGX15InteractivelyOrNull()
        end
        if type == "container" then
            return DataContainers::issueContainerInteractivelyOrNull()
        end
        nil
    end
end