
# encoding: UTF-8

class Nx54

    # Nx54::makeNew()
    def self.makeNew()
        {
            "type"   => "target-recovery-time",
            "value"  => 1
        }
    end

    # Nx54::toString(nx54)
    def self.toString(nx54)
        JSON.generate(nx54)
    end
end
