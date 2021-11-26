# encoding: UTF-8

class NS16sOperator

    # NS16sOperator::ns16s(domain, structure)
    def self.ns16s(domain, structure)
        [
            (domain == "(eva)") ? Anniversaries::ns16s() : nil,
            (domain == "(eva)") ? Calendar::ns16s() : nil,
            (domain == "(eva)") ? JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`) : nil,
            (domain == "(eva)") ? JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`) : nil,
            (domain == "(eva)") ? DrivesBackups::ns16s() : nil,
            Waves::ns16s(domain),
            (domain == "(eva)") ? Inbox::ns16s() : nil,
            structure["Dated"],
            structure["Tail"]
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end
