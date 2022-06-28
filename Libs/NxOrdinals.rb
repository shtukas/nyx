
# encoding: UTF-8

class NxOrdinals

    # ----------------------------------------------------------------------
    # IO

    # NxOrdinals::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxOrdinal")
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxOrdinals::issue(line, ordinal)
    def self.issue(line, ordinal)
        item = {
          "uuid"      => SecureRandom.uuid,
          "variant"   => SecureRandom.uuid,
          "mikuType"  => "NxOrdinal",
          "unixtime"  => Time.new.to_f,
          "line"      => line,
          "ordinal"   => ordinal
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxOrdinals::toString(item)
    def self.toString(item)
        "(ordinal) (#{"%5.2f" % item["ordinal"]}) #{item["line"]}"
    end

    # NxOrdinals::itemsForListing()
    def self.itemsForListing()
        NxOrdinals::items().sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end
end
