
# encoding: UTF-8

class Tags

    # Tags::make(payload)
    def self.make(payload)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "4643abd2-fec6-4184-a9ad-5ad3df3257d6",
            "unixtime"   => Time.new.to_f,
            "payload"    => payload
        }
    end

    # Tags::issue(payload)
    def self.issue(payload)
        object = Tags::make(payload)
        NyxObjects::put(object)
        object
    end

    # Tags::tags()
    def self.tags()
        NyxObjects::getSet("4643abd2-fec6-4184-a9ad-5ad3df3257d6")
    end

    # Tags::getTagsForSource(source)
    def self.getTagsForSource(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["4643abd2-fec6-4184-a9ad-5ad3df3257d6"])
    end

    # Tags::destroyTag(tag)
    def self.destroyTag(tag)
        NyxObjects::destroy(tag)
    end
end
