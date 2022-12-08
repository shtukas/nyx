# encoding: UTF-8

class NyxNetworkIO

    # NyxNetworkIO::getLinkedUUIDs(uuid)
    def self.getLinkedUUIDs(uuid)
        filepath = "#{Config::pathToNyx()}/02-Network/#{uuid}.json"
        return [] if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxNetworkIO::putLinkedUUIDs(uuid, linkedUUIDs)
    def self.putLinkedUUIDs(uuid, linkedUUIDs)

    end
end