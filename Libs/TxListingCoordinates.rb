class TxListingCoordinates

    # TxListingCoordinates::interactivelySelectTxListingCoordinatesTypeOrNull()
    def self.interactivelySelectTxListingCoordinatesTypeOrNull()
        types = ["staged", "ordinal"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", types)
    end

    # TxListingCoordinates::interactivelySelectTxListingCoordinatesType()
    def self.interactivelySelectTxListingCoordinatesType()
        loop {
            type = TxListingCoordinates::interactivelySelectTxListingCoordinatesTypeOrNull()
            return type if type
        }
    end

    # TxListingCoordinates::interactivelyMakeNewTxListingCoordinates()
    def self.interactivelyMakeNewTxListingCoordinates()
        type = TxListingCoordinates::interactivelySelectTxListingCoordinatesType()

        if type == "staged" then
            return {
                "mikuType" => "TxListingCoordinates",
                "type"     => "staged",
                "unixtime" => Time.new.to_f
            }
        end

        if type == "ordinal" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            return {
                "mikuType" => "TxListingCoordinates",
                "type"     => "ordinal",
                "ordinal"  => ordinal
            }
        end

    end
end
