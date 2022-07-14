
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxLine")
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        item = {
          "uuid"      => SecureRandom.uuid,
          "variant"   => SecureRandom.uuid,
          "mikuType"  => "NxLine",
          "unixtime"  => Time.new.to_f,
          "line"      => line,
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["line"]}"
    end

    # NxLines::section2()
    def self.section2()
        NxLines::items().select{|item| !TxProjects::uuidIsProjectElement(item["uuid"]) }
    end
end
