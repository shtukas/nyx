
# encoding: UTF-8

class Ordinals

    # Ordinals::filepath()
    def self.filepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/ordinals.json"
    end

    # Ordinals::getDistribution()
    def self.getDistribution()
        JSON.parse(IO.read(Ordinals::filepath()))
    end

    # Ordinals::newOrdinal()
    def self.newOrdinal()
        ordinals = [0] + Ordinals::getDistribution().values
        ordinals.max.floor + 1
    end

    # Ordinals::getOrdinalForUID(uid)
    def self.getOrdinalForUID(uid)
        distribution = Ordinals::getDistribution()
        return distribution[uid] if distribution[uid]
        distribution[uid] = Ordinals::newOrdinal()
        File.open(Ordinals::filepath(), "w"){|f| f.puts(JSON.pretty_generate(distribution)) }
        distribution[uid]
    end
end
