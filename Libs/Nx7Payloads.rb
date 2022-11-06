# encoding: UTF-8

class Nx7Payloads

    # Nx7Payloads::navigationTypes()
    def self.navigationTypes()
        ["Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # Nx7Payloads::types()
    def self.types()
        ["Data"] + Nx7Payloads::navigationTypes()
    end

    # Nx7Payloads::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx7 payload type", Nx7Payloads::types())
    end

    # Nx7Payloads::interactivelySelectType()
    def self.interactivelySelectType()
        loop {
            type = Nx7Payloads::interactivelySelectTypeOrNull()
            return type if type
        }
    end

    # Nx7Payloads::interactivelyMakePayload(operator)
    def self.interactivelyMakePayload(operator)
        type = Nx7Payloads::interactivelySelectType()

        if type == "Data" then
            state = GridState::interactivelyBuildGridStateOrNull(operator)
            return {
                "mikuType" => "Nx7Payload",
                "type"     => "Data",
                "state"    => state
            }
        end

        if ["Entity", "Concept", "Event", "Person", "Collection", "Timeline"].include?(type) then
            return {
                "mikuType"      => "Nx7Payload",
                "type"          => type,
                "childrenuuids" => []
            }
        end

        raise "(error: 33e315af-bd5c-41f9-adfc-a27e6a660749) unsupported type: #{type}"
    end

    # Nx7Payloads::makeDataFile(operator, filepath)
    def self.makeDataFile(operator, filepath)
        raise "(error: 054eb64a-f37b-4ced-903f-75a6d9532e83) filepath: #{filepath}" if !File.exists?(filepath)
        {
            "mikuType" => "Nx7Payload",
            "type"     => "Data",
            "state"    => GridState::fileGridState(operator, filepath)
        }
    end

    # Nx7Payloads::makeDataNxDirectoryContents(operator, location)
    def self.makeDataNxDirectoryContents(operator, location)
        raise "(error: 551198ba-aa18-49e4-89b7-cb41f6b1c5cd) location: #{location}" if !File.exists?(location)
        {
            "mikuType" => "Nx7Payload",
            "type"     => "Data",
            "state"    => GridState::directoryPathToNxDirectoryContentsGridState(operator, location)
        }
    end
end
