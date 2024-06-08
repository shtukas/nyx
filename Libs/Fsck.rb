
# encoding: UTF-8

class Fsck

    # Fsck::fsck(item)
    def self.fsck(item)
        if item["mikuType"] == "Sx0138" then
            Sx0138s::fsck(item)
            return
        end
        raise "could not fsck: #{item}"
    end
end
