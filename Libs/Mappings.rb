
class NonBoardItemToBoardMapping

    # NonBoardItemToBoardMapping::hasValue(item)
    def self.hasValue(item)
        !Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"]).nil?
    end

    # NonBoardItemToBoardMapping::getBoardOrNull(item)
    def self.getBoardOrNull(item)
        Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
    end

    # NonBoardItemToBoardMapping::toStringSuffix(item)
    def self.toStringSuffix(item)
        board = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
        return "" if board.nil?
        " (board: #{board["description"]})".green
    end
end