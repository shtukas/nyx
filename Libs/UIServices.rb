# encoding: UTF-8

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {

            ms = LCoreMenuItemsNX1.new()

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewMarbleQuarkOrNull(Quarks::computeLowL22()) })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::orderNS17s(ns17s)
    def self.orderNS17s(ns17s)
        ns17s1 = ns17s.first(10) # The first 10
        ns17s2 = ns17s.drop(10)  # Everything after 10

        ns17s11, ns17s12 = ns17s1.partition{|o| o["rt"] > 1.5 }
        # ns17s11 within first 10, those with a rt > 1.5
        # ns17s12 within first 10, those with a rt <= 1.5

        ns17s11 = ns17s11
                        .sort{|o1, o2| o1["rt"] <=> o2["rt"] }

        ns17s12 = ns17s12
                        .sort{|o1, o2| o1["rt"] <=> o2["rt"] }
                        .reverse

        ns17s12 + ns17s11 + ns17s2
    end

    # UIServices::todoNS16s()
    def self.todoNS16s()
        ns17s = GenericTodoFile::ns17s("[todo]", "/Users/pascal/Desktop/Todo.txt") + Quarks::ns17s()
        UIServices::orderNS17s(ns17s).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        [
            isWorkTime ? [] : UIServices::waveLikeNS16s(),
            isWorkTime ? GenericTodoFile::ns16s("[work]".green, "/Users/pascal/Desktop/Work.txt") : [],
            UIServices::todoNS16s()
        ].flatten
    end
end


