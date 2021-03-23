# encoding: UTF-8

class UIServices

    # UIServices::explore()
    def self.explore()
        loop {
            system("clear")
            typex = NyxClassifiers::interactivelySelectClassifierTypeXOrNull()
            break if typex.nil?
            loop {
                system("clear")
                classifiers = NyxClassifiers::getClassifierDeclarations()
                                .select{|classifier| classifier["type"] == typex["type"] }
                                .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
                classifier = CatalystUtils::selectOneOrNull(classifiers, lambda{|classifier| NyxClassifiers::toString(classifier) })
                break if classifier.nil?
                NyxClassifiers::landing(classifier)
            }
        }
    end

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

            ms.item("dangerously edit a TodoCoreData object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = TodoCoreData::getOrNull(uuid)
                return if object.nil?
                object = CatalystUtils::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                TodoCoreData::put(object)
            })

            ms.item("dangerously delete a TodoCoreData object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = TodoCoreData::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                TodoCoreData::destroy(object)
            })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::nyxMain()
    def self.nyxMain()
        loop {
            system("clear")
            puts "Nyx 🗺"
            ops = ["Search", "Explore", "Issue New"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
            break if operation.nil?
            if operation == "Search" then
                Patricia::generalSearchLoop()
            end
            if operation == "Explore" then
                UIServices::explore()
            end
            if operation == "Issue New" then
                node = Patricia::makeNewNodeOrNull()
                next if node.nil?
                Patricia::landing(node)
            end
        }
    end

    # UIServices::todayNS16s()
    def self.todayNS16s()
        announce = IO.read("/Users/pascal/Desktop/Today.txt")
                        .split('@separation-efd2f62e-5ffe-4658-a3e6-c38bdea08136')
                        .first
                        .lines
                        .first(6)
                        .join()
                        .strip
        return [] if announce == ""

        todoNS16 = {
            "uuid"     => "e9e42746-0da1-4b81-b0f9-8ca0b159e280",
            "announce" => announce,
            "commands" => "done (destroy quark and nereid element) | >nyx | landing",
            "lambda"   => lambda{ 

                system("clear")
                puts announce

                context = {}
                actions = [
                    [".", ". (reload)", lambda{|context, command|
                
                    }],
                    ["[]", "[] Next transformation", lambda{|context, command|
                        CatalystUtils::applyNextTransformationToFile("/Users/pascal/Desktop/Today.txt")
                    }],
                    ["edit", "edit", lambda{|context, command|
                        system("open '/Users/pascal/Desktop/Today.txt'")
                    }],
                    ["++", "++ (postpone today by one hour)", lambda{|context, command|
                        DoNotShowUntil::setUnixtime("e9e42746-0da1-4b81-b0f9-8ca0b159e280", Time.new.to_i+3600)
                    }],
                ]

                returnvalue = Interpreting::interpreter(context, actions, {
                    "displayHelpInLineAtIntialization" => true
                })

            }
        }

        [todoNS16]
    end

    # UIServices::waveLikeNS16()
    def self.waveLikeNS16()
        Calendar::displayItemsNS16() + Anniversaries::displayItemsNS16() + Waves::displayItemsNS16()
    end

    # UIServices::CatalystUINS16s()
    def self.CatalystUINS16s()

        todayItems = UIServices::todayNS16s()
        waveLikeItems = UIServices::waveLikeNS16()
        streamItems = Quarks::nx16s()

        if Time.new.hour < 9 and !waveLikeItems.empty? then
            return waveLikeItems
        end

        if Time.new.hour < 9 and waveLikeItems.empty? then
            return streamItems
        end

        if Time.new.hour >= 9 and Time.new.hour < 17 then
            return todayItems + waveLikeItems + streamItems
        end

        if Time.new.hour >= 17 then
            return waveLikeItems + streamItems
        end

    end
end


