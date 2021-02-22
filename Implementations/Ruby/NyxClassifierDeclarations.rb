
# encoding: UTF-8

class NyxClassifierDeclarations

    # ------------------------------------------------
    # Database

    # NyxClassifierDeclarations::issueNewDeclaration(uuid, type, description, payload1)
    def self.issueNewDeclaration(uuid, type, description, payload1)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _uuid_=?", [uuid]
        db.execute "insert into _classifiers_ (_uuid_, _unixtime_, _type_, _description_, _payload1_) values (?,?,?,?,?)", [uuid, Time.new.to_i, type, description, payload1]
        db.commit 
        db.close
    end

    # NyxClassifierDeclarations::updateClassifierDescription(uuid, description)
    def self.updateClassifierDescription(uuid, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "update _classifiers_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NyxClassifierDeclarations::getClassifierDeclarations()
    def self.getClassifierDeclarations()
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_'],
                "payload1"       => row['_payload1_'],
            }
        end
        db.close
        answer
    end

    # NyxClassifierDeclarations::getClassifierByUUIDOrNull(uuid)
    def self.getClassifierByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _classifiers_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_'],
                "payload1"       => row['_payload1_'],
            }
        end
        db.close
        answer
    end

    # NyxClassifierDeclarations::destroy(classifier)
    def self.destroy(classifier)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _uuid_=?", [classifier["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # NyxClassifierDeclarations::typeXs()
    def self.typeXs()
        [
            {
                "type" => "ea9f4f69-1c8c-49c9-b644-8854c1be75d8",
                "name" => "Timeline Item"
            },
            {
                "type" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "name" => "Tag"
            },
            {
                "type" => "30991912-a9f2-426d-9b62-ec942c16c60a",
                "name" => "Curated Listing"
            }
        ]
    end

    # NyxClassifierDeclarations::interactivelySelectClassifierTypeXOrNull()
    def self.interactivelySelectClassifierTypeXOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("classifier type: ", NyxClassifierDeclarations::typeXs(), lambda{|item| item["name"] })
    end

    # NyxClassifierDeclarations::interactivelyIssueNewClassiferOrNull()
    def self.interactivelyIssueNewClassiferOrNull()
        typeX = NyxClassifierDeclarations::interactivelySelectClassifierTypeXOrNull()
        return nil if typeX.nil?
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        payload1 = nil
        if typeX["type"] == "ea9f4f69-1c8c-49c9-b644-8854c1be75d8" then
           payload1 = LucilleCore::askQuestionAnswerAsString("date: ") 
        end
        NyxClassifierDeclarations::issueNewDeclaration(SecureRandom.uuid, typeX["uuid"], description, payload1)
    end

    # NyxClassifierDeclarations::toString(classifier)
    def self.toString(classifier)
        typename = NyxClassifierDeclarations::typeXs().select{|typex| typex["type"] == classifier["type"] }.map{|typex| typex["name"] }.first
        raise "b373b8d6-454e-4710-85e4-41160372395a" if classifier.nil?
        date = (classifier["type"] == "ea9f4f69-1c8c-49c9-b644-8854c1be75d8") ? " #{classifier["payload1"]}" : nil
        "[classifier / #{typename}]#{date ? " (date: #{date})" : ""} #{classifier["description"]}"
    end

    # NyxClassifierDeclarations::nyxSearchItems()
    def self.nyxSearchItems()
        NyxClassifierDeclarations::getClassifierDeclarations()
            .map{|classifier|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NyxClassifierDeclarations::toString(classifier)}",
                    "payload"  => classifier
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # NyxClassifierDeclarations::selectClassifierOrNull()
    def self.selectClassifierOrNull()
        CatalystUtils::selectOneOrNull(NyxClassifierDeclarations::getClassifierDeclarations(), lambda{|classifier| NyxClassifierDeclarations::toString(classifier)})
    end

    # NyxClassifierDeclarations::architectNodeOrNull()
    def self.architectNodeOrNull()
        classifier = NyxClassifierDeclarations::selectClassifierOrNull()
        return classifier if classifier
        NyxClassifierDeclarations::interactivelyIssueNewClassiferOrNull()
    end

    # NyxClassifierDeclarations::landing(classifier)
    def self.landing(classifier)

        loop {

            return if NyxClassifierDeclarations::getClassifierByUUIDOrNull(classifier["uuid"]).nil? # could have been destroyed at the previous run

            classifier = NyxClassifierDeclarations::getClassifierByUUIDOrNull(classifier["uuid"])

            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts NyxClassifierDeclarations::toString(classifier).green
            puts "uuid: #{classifier["uuid"]}".yellow

            puts ""

            Network::getLinkedObjects(classifier).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("update description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                NyxClassifierDeclarations::updateClassifierDescription(classifier["uuid"], description)
            })

            mx.item("link to network architected".yellow, lambda { 
                Patricia::linkToArchitectedNode(classifier)
            })

            mx.item("select and remove related".yellow, lambda {
                Patricia::selectAndRemoveLinkedNode(classifier)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NyxClassifierDeclarations::destroy(classifier)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
