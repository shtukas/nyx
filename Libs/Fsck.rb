
class Fsck

    # Fsck::fsckItemNotesAttribute(item)
    def self.fsckItemNotesAttribute(item)
        return if item["notes"].nil?
        if item["notes"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s notes is not an array"
        end
        item["notes"].each{|note|
            NxNotes::fsck(note)
        }
    end

    # Fsck::fsckItemTagsAttribute(item)
    def self.fsckItemTagsAttribute(item)
        return if item["tags"].nil?
        if item["tags"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s tags is not an array"
        end
    end

    # Fsck::fsckItemPx44Attribute(item)
    def self.fsckItemPx44Attribute(item)
        return if item["px44s"].nil?
        if item["px44s"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s px44s is not an array"
        end
        if item["px44s"].any?{|px44| px44.class.to_s != "Hash" } then
            puts "I have a node with what appears to be an incorrect px44s array"
            puts "node:"
            puts JSON.pretty_generate(item)
            if LucilleCore::askQuestionAnswerAsBoolean("Should I repair the array by discarding the non hash elements ? ") then
                item["px44s"] = item["px44s"].select{|element| element.class.to_s == "Hash" }
                puts "node (updated):"
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                Items::setAttribute(item["uuid"], "px44s", item["px44s"])
            end
        end
        item["px44s"].each{|px44|
            uuid = item["uuid"]
            Px44::fsck(uuid, px44)
        }
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        NxNode::items().each{|item|
            if item["mikuType"] == "Nx27" then
                puts "fsck: item: #{item["uuid"]}"
                NxNode::fsckItem(item)
            end
        }
        puts "fsck completed"
    end
end
