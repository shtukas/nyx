
# encoding: UTF-8

class NyxNavigationPoints

    # ------------------------------------------------
    # Database

    # NyxNavigationPoints::issueNewNavigationPoint(uuid, type, description)
    def self.issueNewNavigationPoint(uuid, type, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _navigationpoints_ where _uuid_=?", [uuid]
        db.execute "insert into _navigationpoints_ (_uuid_, _unixtime_, _type_, _description_) values (?,?,?,?)", [uuid, Time.new.to_i, type, description]
        db.commit 
        db.close
    end

    # NyxNavigationPoints::updateNavigationPointDescription(uuid, description)
    def self.updateNavigationPointDescription(uuid, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "update _navigationpoints_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NyxNavigationPoints::getNavigationPoints()
    def self.getNavigationPoints()
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _navigationpoints_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # NyxNavigationPoints::getNavigationPointByUUIDOrNull(uuid)
    def self.getNavigationPointByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _navigationpoints_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # NyxNavigationPoints::destroy(navpoint)
    def self.destroy(navpoint)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _navigationpoints_ where _uuid_=?", [navpoint["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # NyxNavigationPoints::typeXs()
    def self.typeXs()
        [
            {
                "type" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "name" => "Label"
            },
            {
                "type" => "30991912-a9f2-426d-9b62-ec942c16c60a",
                "name" => "Curated Listing"
            },
            {
                "type" => "ea9f4f69-1c8c-49c9-b644-8854c1be75d8",
                "name" => "Date"
            },
            {
                "type" => "95c02a05-f289-4bf7-ac3a-4c76c2434f11",
                "name" => "Location"
            }
        ]
    end

    # NyxNavigationPoints::interactivelySelectNavigationPointTypeXOrNull()
    def self.interactivelySelectNavigationPointTypeXOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("navigation point type: ", NyxNavigationPoints::typeXs(), lambda{|item| item["name"] })
    end

    # NyxNavigationPoints::interactivelyIssueNewNavigationPointOrNull()
    def self.interactivelyIssueNewNavigationPointOrNull()
        typeX = NyxNavigationPoints::interactivelySelectNavigationPointTypeXOrNull()
        return nil if typeX.nil?
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        NyxNavigationPoints::issueNewNavigationPoint(uuid, typeX["uuid"], description)
        NyxNavigationPoints::getNavigationPointByUUIDOrNull(uuid)
    end

    # NyxNavigationPoints::toString(navpoint)
    def self.toString(navpoint)
        typename = NyxNavigationPoints::typeXs().select{|typex| typex["type"] == navpoint["type"] }.map{|typex| typex["name"] }.first
        raise "b373b8d6-454e-4710-85e4-41160372395a" if typename.nil?
        "[navpoint: #{typename}] #{navpoint["description"]}"
    end

    # NyxNavigationPoints::nyxSearchItems()
    def self.nyxSearchItems()
        NyxNavigationPoints::getNavigationPoints()
            .map{|navpoint|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NyxNavigationPoints::toString(navpoint)}",
                    "payload"  => navpoint
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # NyxNavigationPoints::selectNavigationPointOrNull()
    def self.selectNavigationPointOrNull()
        CatalystUtils::selectOneObjectOrNullUsingInteractiveInterface(NyxNavigationPoints::getNavigationPoints(), lambda{|navpoint| NyxNavigationPoints::toString(navpoint)})
    end

    # NyxNavigationPoints::landing(navpoint)
    def self.landing(navpoint)

        loop {

            return if NyxNavigationPoints::getNavigationPointByUUIDOrNull(navpoint["uuid"]).nil? # could have been destroyed at the previous run

            navpoint = NyxNavigationPoints::getNavigationPointByUUIDOrNull(navpoint["uuid"])

            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts NyxNavigationPoints::toString(navpoint).green
            puts "uuid: #{navpoint["uuid"]}".yellow

            puts ""

            Network::getLinkedObjects(navpoint).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("update description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                NyxNavigationPoints::updateNavigationPointDescription(navpoint["uuid"], description)
            })

            mx.item("link to network architected".yellow, lambda { 
                Patricia::linkToArchitectedNode(navpoint)
            })

            mx.item("select and remove related".yellow, lambda {
                Patricia::selectAndRemoveLinkedNode(navpoint)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NyxNavigationPoints::destroy(navpoint)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
