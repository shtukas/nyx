
# encoding: UTF-8

class Tags
    # Tags::makeTag(targetuuid, payload)
    def self.makeTag(targetuuid, payload)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "4643abd2-fec6-4184-a9ad-5ad3df3257d6",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "payload"    => payload
        }
    end

    # Tags::issueTag(targetuuid, payload)
    def self.issueTag(targetuuid, payload)
        object = Tags::makeTag(targetuuid, payload)
        NyxObjects::put(object)
        object
    end

    # Tags::getTagsForTargetUUID(targetuuid)
    def self.getTagsForTargetUUID(targetuuid)
        NyxObjects::getSet("4643abd2-fec6-4184-a9ad-5ad3df3257d6")
            .select{|tag| tag["targetuuid"] == targetuuid }
    end

    # Tags::destroyTag(tag)
    def self.destroyTag(tag)
        NyxObjects::destroy(tag["uuid"])
    end
end
