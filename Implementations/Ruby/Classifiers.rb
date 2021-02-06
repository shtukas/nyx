
# encoding: UTF-8

class Classifiers

    # ------------------------------------------------
    # Database

    # Classifiers::issueNewClassifier(uuid, description)
    def self.issueNewClassifier(uuid, description)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _uuid_=?", [uuid]
        db.execute "insert into _classifiers_ (_uuid_, _description_) values (?, ?)", [uuid, description]
        db.commit 
        db.close
    end

    # Classifiers::getClassifiers()
    def self.getClassifiers()
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Classifiers::getClassifierByUUIDOrNull(uuid)
    def self.getClassifierByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _classifiers_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Classifiers::getClassifiersForDescription(description)
    def self.getClassifiersForDescription(description)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_ where _description_=?", [description]) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Classifiers::destroy(classifier)
    def self.destroy(classifier)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _uuid_=?", [classifier["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # Classifiers::interactivelyIssueNewClassifierOrNull()
    def self.interactivelyIssueNewClassifierOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        Classifiers::issueNewClassifier(uuid, description)
        Classifiers::getClassifierByUUIDOrNull(uuid)
    end

    # Classifiers::toString(classifier)
    def self.toString(classifier)
        "[classifier] #{classifier["description"]}"
    end

    # Classifiers::nyxSearchItems()
    def self.nyxSearchItems()
        Classifiers::getClassifiers()
            .map{|classifier|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{Classifiers::toString(classifier)}",
                    "type"         => "classifier",
                    "payload"      => classifier
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # Classifiers::selectClassifierOrNull()
    def self.selectClassifierOrNull()
        NyxUtils::selectOneOrNull(Classifiers::getClassifiers(), lambda{|classifier| Classifiers::toString(classifier)})
    end

    # Classifiers::architectOrNull()
    def self.architectOrNull()
        classifier = Classifiers::selectClassifierOrNull()
        return classifier if classifier
        Classifiers::interactivelyIssueNewClassifierOrNull()
    end

    # Classifiers::landing(classifier)
    def self.landing(classifier)

        locpaddingsize = 11

        loop {
            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            return if Classifiers::getClassifierByUUIDOrNull(classifier["uuid"]).nil? # could have been destroyed at the previous run

            puts Classifiers::toString(classifier).green
            puts "uuid: #{classifier["uuid"]}".yellow

            puts ""

            NyxArrows::getParentsUUIDs(classifier["uuid"]).each{|uuid1|
                e1 = NyxPatricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{NyxPatricia::dx7toString(e1)}", lambda { 
                    NyxPatricia::dx7landing(e1)
                })
            }

            NyxArrows::getChildrenUUIDs(classifier["uuid"]).each{|uuid1|
                e1 = NyxPatricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{NyxPatricia::dx7toString(e1)}", lambda { 
                    NyxPatricia::dx7landing(e1)
                })
            }

            puts ""

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                NyxPatricia::architectAddParentForDX7(classifier)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                NyxPatricia::architectAddChildForDX7(classifier)
            })

            mx.item("select and remove parent".yellow, lambda {
                NyxPatricia::selectAndRemoveOneParentFromDX7(classifier)
            })

            mx.item("select and remove child".yellow, lambda {
                NyxPatricia::selectAndRemoveOneChildFromDX7(classifier)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    Classifiers::destroy(classifier)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
