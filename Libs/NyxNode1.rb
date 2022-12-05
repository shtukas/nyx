# encoding: UTF-8

=begin
NyxNode1 {
    "uuid"         : String
    "mikuType"     : "NyxNode1"
    "unixtime"     : Float
    "datetime"     : DateTime Iso 8601 UTC Zulu
    "description"  : String
}
=end

class NyxNode1

    # --------------------------------------------
    # Basic

    # NyxNode1::commit(node)
    def self.commit(node)

    end

    # NyxNode1::getOrNull(uuid)
    def self.getOrNull(uuid)

    end

    # NyxNode1::items()
    def self.items()

    end

    # NyxNode1::destroy(uuid)
    def self.destroy(uuid)

    end

    # --------------------------------------------
    # 

    # NyxNode1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        node = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NyxNode1",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        NyxNode1::commit(node)
        node
    end
end