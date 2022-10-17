# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil/#{uuid}.data"
        File.open(filepath, "w"){|f| f.write(unixtime) }
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil/#{uuid}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath).to_f
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
