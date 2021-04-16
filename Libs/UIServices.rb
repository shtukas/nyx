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
        s1 = ns17s.first(6)
        s2 = ns17s.drop(6)

        s1Actives = s1.select{|ns17| ns17["rt"] > 0}
        s1Zero    = s1.select{|ns17| ns17["rt"] == 0}

        if s1Zero.empty? then
            return (s1Actives.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + s2).reject{|ns17| ns17["synthetic"] }
        end

        if s1Actives.empty? then
            return s1Zero + s2
        end

        s1Actives = s1Actives.sort{|o1, o2| o1["rt"] <=> o2["rt"] }

        if s1Actives[0]["synthetic"] then
            s1Zero + s1Actives + s2
        else
            s1Actives + s1Zero + s2
        end
    end

    # UIServices::todoNS16s()
    def self.todoNS16s()
        ns17s = [Synthetic::ns17()] + GenericTodoFile::ns17s("[todo]", "/Users/pascal/Desktop/Todo.txt") + Quarks::ns17s()
        UIServices::orderNS17s(ns17s).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        isWorkTime = (isWorkTime and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        [
            isWorkTime ? [] : UIServices::waveLikeNS16s(),
            isWorkTime ? GenericTodoFile::ns16s("[work]".green, "/Users/pascal/Desktop/Work.txt") : [],
            isWorkTime ? UIServices::waveLikeNS16s() : [] ,
            UIServices::todoNS16s()
        ].flatten
    end
end


