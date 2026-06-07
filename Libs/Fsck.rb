
class Fsck

    # Fsck::fsckItem(item)
    def self.fsckItem(item)
        if item["mikuType"] == "Nx27" then
            Nx27::fsck(item)
        end
        if item["mikuType"] == "Px44" then
            Px44::fsck(item)
        end
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        Items::getItems().each{|item|
            puts "fsck: #{JSON.pretty_generate(item)}"
            Fsck::fsckItem(item)
        }
        puts "fsck completed"
    end
end
