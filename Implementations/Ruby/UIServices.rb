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

            ms.item("DxThreads", lambda { DxThreads::main() })

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
end


