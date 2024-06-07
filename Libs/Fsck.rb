
# encoding: UTF-8

class Fsck

    # Fsck::fsck(item)
    def self.fsck(item)
        if item["mikuType"] == "NxDot41" then
            NxDot41s::fsck(item)
            return
        end
        if item["mikuType"] == "NxType1FileSystemNode" then
            NxType1FileSystemNodes::fsck(item)
            return
        end
        if item["mikuType"] == "NxType3NavigationNode" then
            return
        end
        raise "could not fsck: #{item}"
    end
end
