# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class UIServices

    # UIServices::ns17sToNS16s(ns17s)
    def self.ns17sToNS16s(ns17s)
        ns17s.sort{|i1, i2| i1["ratio"] <=> i2["ratio"] }.map{|item| item["ns16s"] }.flatten
    end

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Priority1::ns16OrNull(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16sHighPriority(),
            NxFloat::ns16s(),
            UIServices::ns17sToNS16s(Work::ns17s() + Waves::ns17sLowPriority() + Nx50s::ns17s())
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::ns16sToTrace(ns16s)
    def self.ns16sToTrace(ns16s)
        ns16s.first(3).map{|item| item["uuid"] }.join(";")
    end

    # UIServices::programmableListingDisplay(getItems: Lambda: () -> Array[NS16], processItems: Lambda: Array[NS16] -> Status)
    def self.programmableListingDisplay(getItems, processItems)
        loop {
            items = getItems.call()
            status = processItems.call(items)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end

    # UIServices::operationalInterface()
    def self.operationalInterface()
        puts "new float / wave / ondate / calendar item / todo / work item | ondates | floats | anniversaries | calendar | waves | work | search | ns17s | >nyx".yellow
        command = LucilleCore::askQuestionAnswerAsString("> ")
    
        return if command == ""

        if Interpreting::match("new float", command) then
            float = NxFloat::interactivelyCreateNewOrNull()
            puts JSON.pretty_generate(float)
        end

        if Interpreting::match("new wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("new ondate", command) then
            nx31 = Nx31s::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(nx31)
        end

        if Interpreting::match("new calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("new todo", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            end
        end

        if Interpreting::match("new todo priority", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            else
                exit
            end
            nx50["unixtime"] = ([Time.new.to_i] + CoreDataTx::getObjectsBySchema("Nx50").map{|n| n["unixtime"] }).min - 1
            CoreDataTx::commit(nx50)
        end

        if Interpreting::match("new work item", command) then
            Work::interactvelyIssueNewItem()
        end

        if Interpreting::match("floats", command) then
            NxFloat::main()
        end

        if Interpreting::match("ondates", command) then
            Nx31s::main()
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::main()
        end

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            Waves::main()
        end

        if Interpreting::match("work", command) then
            Work::main()
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match(">nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/x-make-new")
        end
    end
end
