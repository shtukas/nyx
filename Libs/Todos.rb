
# encoding: UTF-8

class Todos

    # Todos::ns16s()
    def self.ns16s()
        focus = DomainsX::focus()
        if focus == "eva" then
            return TxTodos::ns16s()
        end
        if focus == "work" then
            return TxWorkItems::ns16s()
        end
        raise "c5588216-b70f-45b2-8af1"
    end
end
