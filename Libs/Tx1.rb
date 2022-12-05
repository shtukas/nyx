class Tx1

    # Tx1::types()
    def self.types()
        ["regular", "unique-string"]
    end

    # Tx1::interactivelySelectTx1TypeOrNull()
    def self.interactivelySelectTx1TypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Tx1::types())
    end

    # Tx1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        type = Tx1::interactivelySelectTx1TypeOrNull()
        return nil if type.nil?
        if type == "regular" then
            return {
                "type" => "regular"
            }
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring == ""
            return {
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
    end
end
