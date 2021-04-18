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

    # UIServices::orderNS17s(ns17s, synthetic)
    def self.orderNS17s(ns17s, synthetic)
        depth = 3
        if synthetic["rt"] < ns17s.first(depth).map{|ns17| ns17["rt"] }.min then
            # need to do some zero
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            zeros.first(depth) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(depth)
        else
            # normal ops
            f1, f2    = ns17s.first(depth).partition{|ns17| ns17["rt"] > 0}
            if f1.size > 0 then
                (f1 + [synthetic]).sort{|o1, o2| o1["rt"] <=> o2["rt"] } + f2 + ns17s.drop(depth)
            else
                ns17s
            end
        end
    end

    # UIServices::todoNS16s()
    def self.todoNS16s()
        makeSyntheticNs17 = lambda {|syntheticRT|
            ns16 = {
                "uuid"     => SecureRandom.hex,
                "announce" => "(#{"%5.3f" % syntheticRT}) #{"(/◕ヮ◕)/".green} Synthetic 🚀 🌝",
                "start"    => lambda { },
                "done"     => lambda { }
            }
            {
                "ns16"      => ns16,
                "rt"        => syntheticRT,
                "synthetic" => true
            }
        }
        UIServices::orderNS17s(Quarks::ns17s(), makeSyntheticNs17.call(Synthetic::getRecoveryTimeInHours())).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        isWorkTime = (isWorkTime and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        [
            isWorkTime ? [] : UIServices::waveLikeNS16s(),
            isWorkTime ? WorkTxt::ns16s() : [],
            isWorkTime ? UIServices::waveLikeNS16s() : [] ,
            UIServices::todoNS16s()
        ].flatten
    end
end


