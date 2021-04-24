# encoding: UTF-8

class LowOrbitals

    # LowOrbitals::register(filename)
    def self.register(filename)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/LowOrbitals.txt", "a"){|f| f.puts(filename) }
    end

    # LowOrbitals::filenames()
    def self.filenames()
        IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/LowOrbitals.txt")
            .lines
            .map{|l| l.strip}
            .select{|l| l.size > 0}
    end

    # LowOrbitals::getQuarksMarbles()
    def self.getQuarksMarbles()
        LowOrbitals::filenames()
            .map{|filename|
                filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks/#{filename}"
                if File.exists?(filepath) then
                    Marble.new(filepath)
                else
                    nil
                end
            }
            .compact
    end

    # LowOrbitals::ns17s()
    def self.ns17s()
        LowOrbitals::getQuarksMarbles()
            .map{|marble| Quarks::marbleToNS16(marble, nil) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|ns16| Quarks::ns16ToNS17(ns16) }
    end

    # LowOrbitals::isLowOrbital(filename)
    def self.isLowOrbital(filename)
        LowOrbitals::filenames().include?(filename)
    end
end


