
# encoding: UTF-8

class CuratedListings

    # ------------------------------------------------
    # Database

    # CuratedListings::issueNewCuratedListing(uuid, description)
    def self.issueNewCuratedListing(uuid, description)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _curatedlistings_ where _uuid_=?", [uuid]
        db.execute "insert into _curatedlistings_ (_uuid_, _description_) values (?,?)", [uuid, description]
        db.commit 
        db.close
    end

    # CuratedListings::getCuratedListings()
    def self.getCuratedListings()
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _curatedlistings_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "30991912-a9f2-426d-9b62-ec942c16c60a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # CuratedListings::getCuratedListingByUUIDOrNull(uuid)
    def self.getCuratedListingByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _curatedlistings_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "30991912-a9f2-426d-9b62-ec942c16c60a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # CuratedListings::destroy(curatedListing)
    def self.destroy(curatedListing)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _curatedlistings_ where _uuid_=?", [curatedListing["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # CuratedListings::interactivelyIssueNewCuratedListingOrNull()
    def self.interactivelyIssueNewCuratedListingOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        CuratedListings::issueNewCuratedListing(uuid, description)
        CuratedListings::getCuratedListingByUUIDOrNull(uuid)
    end

    # CuratedListings::toString(curatedListing)
    def self.toString(curatedListing)
        "[curatedListing] #{curatedListing["description"]}"
    end

    # CuratedListings::nyxSearchItems()
    def self.nyxSearchItems()
        CuratedListings::getCuratedListings()
            .map{|curatedListing|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{CuratedListings::toString(curatedListing)}",
                    "type"         => "curatedListing",
                    "payload"      => curatedListing
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # CuratedListings::selectCuratedListingOrNull()
    def self.selectCuratedListingOrNull()
        NyxUtils::selectOneOrNull(CuratedListings::getCuratedListings(), lambda{|curatedListing| CuratedListings::toString(curatedListing)})
    end

    # CuratedListings::architectOrNull()
    def self.architectOrNull()
        curatedListing = CuratedListings::selectCuratedListingOrNull()
        return curatedListing if curatedListing
        CuratedListings::interactivelyIssueNewCuratedListingOrNull()
    end

    # CuratedListings::landing(curatedListing)
    def self.landing(curatedListing)

        locpaddingsize = 11

        loop {
            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            return if CuratedListings::getCuratedListingByUUIDOrNull(curatedListing["uuid"]).nil? # could have been destroyed at the previous run

            puts CuratedListings::toString(curatedListing).green
            puts "uuid: #{curatedListing["uuid"]}".yellow

            puts ""

            NyxArrows::getParentsUUIDs(curatedListing["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            NyxArrows::getChildrenUUIDs(curatedListing["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            puts ""

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                Patricia::architectAddParentForDX7(curatedListing)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                Patricia::architectAddChildForDX7(curatedListing)
            })

            mx.item("select and remove parent".yellow, lambda {
                Patricia::selectAndRemoveOneParentFromDX7(curatedListing)
            })

            mx.item("select and remove child".yellow, lambda {
                Patricia::selectAndRemoveOneChildFromDX7(curatedListing)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    CuratedListings::destroy(curatedListing)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
