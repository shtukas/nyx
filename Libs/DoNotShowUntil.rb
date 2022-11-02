# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil/#{uuid}.info"
        File.open(filepath, "w"){|f| f.puts(unixtime) }
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil/#{uuid}.info"
        return nil if !File.exists?(filepath)
        IO.read(filepath).strip.to_f
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
