
class NonBoardItemToBoardMapping

    # NonBoardItemToBoardMapping::hasValue(item)
    def self.hasValue(item)
        !Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"]).nil?
    end

    # NonBoardItemToBoardMapping::getBoardOrNull(item)
    def self.getBoardOrNull(item)
        Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
    end

    # NonBoardItemToBoardMapping::belongsToThisBoard(item, board or nil)
    def self.belongsToThisBoard(item, board)
        if board.nil? then
            !NonBoardItemToBoardMapping::hasValue(item)
        else
            b2 = NonBoardItemToBoardMapping::getBoardOrNull(item)
            return false if b2.nil?
            b2["uuid"] == board["uuid"]
        end
    end

    # NonBoardItemToBoardMapping::toStringSuffix(item)
    def self.toStringSuffix(item)
        board = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
        return "" if board.nil?
        " (board: #{board["description"]})".green
    end
end