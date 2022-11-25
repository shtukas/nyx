
# encoding: UTF-8

class Nyx

    # Nyx::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            entity = SearchNyx::nyxFoxTerrier()
            return entity if entity
            return Nx7::interactivelyIssueNewOrNull()
        end
        if operation == "new" then
            return Nx7::interactivelyIssueNewOrNull()
        end
    end

    # Nyx::program()
    def self.program()
        SearchNyx::nyx()
    end
end
