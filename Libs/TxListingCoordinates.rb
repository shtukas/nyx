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
end
