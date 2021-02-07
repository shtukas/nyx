
# encoding: UTF-8

class Tags

    # ------------------------------------------------
    # Database

    # Tags::issueNewTag(uuid, description)
    def self.issueNewTag(uuid, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _tags_ where _uuid_=?", [uuid]
        db.execute "insert into _tags_ (_uuid_, _description_) values (?,?)", [uuid, description]
        db.commit 
        db.close
    end

    # Tags::getTags()
    def self.getTags()
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _tags_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Tags::getTagByUUIDOrNull(uuid)
    def self.getTagByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _tags_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Tags::getTagsForDescription(description)
    def self.getTagsForDescription(description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _tags_ where _description_=?", [description]) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "nyxElementType" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # Tags::destroy(tags)
    def self.destroy(tags)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _tags_ where _uuid_=?", [tags["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # Tags::interactivelyIssueNewTagOrNull()
    def self.interactivelyIssueNewTagOrNull()
        uuid = SecureRandom.hex
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        Tags::issueNewTag(uuid, description)
        Tags::getTagByUUIDOrNull(uuid)
    end

    # Tags::toString(tags)
    def self.toString(tags)
        "[tags] #{tags["description"]}"
    end

    # Tags::nyxSearchItems()
    def self.nyxSearchItems()
        Tags::getTags()
            .map{|tag|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{Tags::toString(tag)}",
                    "type"         => "tag",
                    "payload"      => tag
                }
            }
    end

    # ------------------------------------------------
    # Interface

    # Tags::selectTagOrNull()
    def self.selectTagOrNull()
        CatalystUtils::selectOneOrNull(Tags::getTags(), lambda{|tags| Tags::toString(tags)})
    end

    # Tags::architectOrNull()
    def self.architectOrNull()
        tags = Tags::selectTagOrNull()
        return tags if tags
        Tags::interactivelyIssueNewTagOrNull()
    end

    # Tags::landing(tags)
    def self.landing(tags)

        locpaddingsize = 11

        loop {
            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            return if Tags::getTagByUUIDOrNull(tags["uuid"]).nil? # could have been destroyed at the previous run

            puts Tags::toString(tags).green
            puts "uuid: #{tags["uuid"]}".yellow

            puts ""

            Arrows::getParentsUUIDs(tags["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            Arrows::getChildrenUUIDs(tags["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            puts ""

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                Patricia::architectAddParentForDX7(tags)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                Patricia::architectAddChildForDX7(tags)
            })

            mx.item("select and remove parent".yellow, lambda {
                Patricia::selectAndRemoveOneParentFromDX7(tags)
            })

            mx.item("select and remove child".yellow, lambda {
                Patricia::selectAndRemoveOneChildFromDX7(tags)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    Tags::destroy(tags)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
