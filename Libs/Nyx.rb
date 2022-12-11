
# encoding: UTF-8

class Nyx

    # Nyx::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            entity = nil
            return entity if entity
            return nil
        end
        if operation == "new" then
            return nil
        end
    end
end
