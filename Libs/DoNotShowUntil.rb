# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DNSUIO

    # DNSUIO::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/DoNotShowUntil2")
            .select{|filepath| filepath[-5, 5] == ".json" }
    end

    # DNSUIO::filepathsForUuid(uuid) # filepaths for this uuid (possibly empty)
    def self.filepathsForUuid(uuid)
        DNSUIO::filepaths()
            .select{|filepath|
                data = JSON.parse(IO.read(filepath))
                data["uuid"] == uuid
            }
    end

    # DNSUIO::unixtimeOrNull(uuid)
    def self.unixtimeOrNull(uuid)

        key1 = "26f5a1eb-3568-4e77-87a9-b29d56732fbd:#{DNSUIO::filepaths().join(":")}:#{uuid}"
        unixtime = XCache::getOrNull(key1)
        return unixtime.to_f if unixtime

        unixtime = DNSUIO::filepathsForUuid(uuid).reduce(nil){|m, u|
            u = JSON.parse(IO.read(u))["unixtime"]
            if m then
                [m, u].max
            else
                u
            end
        }

        if unixtime then
            XCache::set(key1, unixtime)
        end

        unixtime
    end

    # DNSUIO::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        DNSUIO::filepathsForUuid(uuid)
            .each{|filepath| FileUtils.rm(filepath)}

        data = {
            "uuid"     => uuid,
            "unixtime" => unixtime,
            "random"   => SecureRandom.hex
        }
        contents = JSON.generate(data)
        filename = "#{Digest::SHA1.hexdigest(contents)}.json"
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil2/#{filename}"
        File.open(filepath, "w") {|f| f.puts(contents) }
    end

end

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        DNSUIO::setUnixtime(uuid, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        DNSUIO::unixtimeOrNull(uuid)
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        return nil if Time.new.to_i >= unixtime.to_i
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
