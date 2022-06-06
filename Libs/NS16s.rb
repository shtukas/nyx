
# encoding: UTF-8

class NS16s

    # NS16s::ns16s(universe)
    def self.ns16s(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(universe),
            TxProjects::ns16s(universe),
            [Streaming::rstreamToken()],
            TxTodos::ns16s(universe),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end
