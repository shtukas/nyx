
# encoding: UTF-8

class Todos

    # Todos::ns16s()
    def self.ns16s()
        dominant = DomainsX::dominantTT()
        if dominant == "eva" then
            return Nx50s::ns16s()
        end
        if dominant == "work" then
            return Mx51s::ns16s()
        end
        raise "c5588216-b70f-45b2-8af1"
    end
end
