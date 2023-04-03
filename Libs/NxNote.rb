
class NxNote

    # NxNote::items()
    def self.items()
        N3Objects::getMikuType("NxNote")
    end

    # NxNote::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxNote::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxNote::issue(line)
    def self.issue(line)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxNote",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => line
        }
        puts JSON.pretty_generate(item)
        NxNote::commit(item)
        item
    end
end