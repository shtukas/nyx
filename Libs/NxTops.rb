
class NxTops

    # NxTops::items()
    def self.items()
        ObjectStore2::objects("NxTops")
    end

    # NxTops::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTops", item)
    end

    # NxTops::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTops", uuid)
    end

    # NxTops::interactivelyDecideOrdinalOrNull(board)
    def self.interactivelyDecideOrdinalOrNull(board)
        if board.nil? then
            existingItems = NxTops::itemsInOrder()
            return 1 if existingItems.empty?
            existingItems.each{|item|
                puts NxTops::toString(item)
            }
            LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        else
            existingItems = NxTops::itemsForBoard(board)
            return 1 if existingItems.empty?
            existingItems.each{|item|
                puts NxTops::toString(item)
            }
            LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        end
    end

    # NxTops::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        board = NxBoards::interactivelySelectOneOrNull()
        ordinal = NxTops::interactivelyDecideOrdinalOrNull(board)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ordinal"     => ordinal
        }
        puts JSON.pretty_generate(item)
        NxTops::commit(item)
        NonBoardItemToBoardMapping::attach(item, board)
        item
    end

    # NxTops::toString(item)
    def self.toString(item)
        "(top) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxTops::itemsInOrder()
    def self.itemsInOrder()
        NxTops::items().sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # NxTops::itemsForBoard(board or nil)
    def self.itemsForBoard(board)
        NxTops::itemsInOrder()
            .select{|item| NonBoardItemToBoardMapping::belongsToThisBoard(item, board) }
    end

    # NxTops::listingItems(board or nil)
    def self.listingItems(board)
        NxTops::itemsForBoard(board)
    end
end