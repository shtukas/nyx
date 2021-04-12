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

    # UIServices::thatFunnyOrdering1(objects, keyValue)
    def self.thatFunnyOrdering1(objects, keyValue)
        return [] if objects.empty?
        average = objects.map{|object| object[keyValue]}.inject(0, :+).to_f/objects.size
        objs1, objs2 = objects.partition { |object| object[keyValue] >= average }

        objs2 = objs2.sort{|o1, o2| o1[keyValue] <=> o2[keyValue] }.reverse
        objs1 = objs1.sort{|o1, o2| o1[keyValue] <=> o2[keyValue] }

        objs2 + objs1
    end

    # UIServices::stuffToDoNS16s()
    def self.stuffToDoNS16s()
        objs1 = GenericTodoFile::ns16s("[todo]", "/Users/pascal/Desktop/Todo.txt")
        objs2 = Quarks::ns16s()
        # We expect a ket called recoveryTimeInHours
        UIServices::thatFunnyOrdering1(objs1 + objs2.take([10-objs1.size, 0].max), "recoveryTimeInHours")
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        [
            UIServices::waveLikeNS16s(),
            isWorkTime ? GenericTodoFile::ns16s("[work]".green, "/Users/pascal/Desktop/Work.txt") : [],
            UIServices::stuffToDoNS16s()
        ].flatten
    end
end


