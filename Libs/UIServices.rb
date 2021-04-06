# encoding: UTF-8

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item("Calendar", lambda { Calendar::main() })

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })            

            ms.item("new quark", lambda { Quarks::getQuarkPossiblyArchitectedOrNull(nil, nil) })    

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Calendar::ns16s() + Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        [
            GenericTodoFile::ns16s("[work]".green, "/Users/pascal/Galaxy/Encyclopaedia Timeline/2016/Occupations/The Guardian/Pascal Work/B-In Progress.txt"),
            UIServices::waveLikeNS16s(),
            GenericTodoFile::ns16s("[todo]", "/Users/pascal/Desktop/Todo.txt"),
            Quarks::ns16s()
        ].flatten
    end
end


