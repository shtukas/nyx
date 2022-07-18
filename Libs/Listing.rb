
class Listing

    # Listing::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/listing.sqlite3"
    end

    # Listing::insert(uuid, zone, ordinal, announce, object, createdAt)
    def self.insert(uuid, zone, ordinal, announce, object, createdAt)
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _listing_ where _uuid_=?", [uuid]
            db.execute "insert into _listing_ (_uuid_, _zone_, _ordinal_, _announce_, _object_, _createdAt_) values (?, ?, ?, ?, ?, ?)", [uuid, zone, ordinal, announce, JSON.generate(object), createdAt]
            db.close
        }
    end

    # Listing::entries()
    def self.entries()
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            entries = []
            db.execute("select * from _listing_ order by _ordinal_", []) do |row|
                entries << row
            end
            db.close
            entries
        }
    end

    # Listing::lowestOrdinal()
    def self.lowestOrdinal()
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            value = 0
            db.execute("select min(_ordinal_) as ordinal from _listing_", []) do |row|
                value = row["ordinal"]
            end
            db.close
            value
        }
    end

    # Listing::highestOrdinal()
    def self.highestOrdinal()
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            value = 0
            db.execute("select max(_ordinal_) as ordinal from _listing_", []) do |row|
                value = row["ordinal"]
            end
            db.close
            value
        }
    end

    # Listing::ordinalsdrop()
    def self.ordinalsdrop()
        lowest = Listing::lowestOrdinal()
        return if lowest < 10
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "update _listing_ set _ordinal_=_ordinal_-10", []
            db.close
        }
    end

    # Listing::nextOrdinal()
    def self.nextOrdinal()
        Listing::highestOrdinal() + 1
    end

    # Listing::rotate()
    def self.rotate()
        entries = Listing::entries()
        return if entries.empty?
        entry = entries.first
        nextOrdinal = Listing::nextOrdinal()
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "update _listing_ set _ordinal_=? where _uuid_=?", [nextOrdinal, entry["_uuid_"]]
            db.close
        }
    end

    # Listing::removeFirstEntry()
    def self.removeFirstEntry()
        entries = Listing::entries()
        return if entries.empty?
        entry = entries.first
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _listing_ where _uuid_=?", [entry["_uuid_"]]
            db.close
        }
    end

    # Listing::publishAverageAgeInDays()
    def self.publishAverageAgeInDays()
        numbers = Listing::entries()
                    .map{|entry| Time.new.to_i-entry["_createdAt_"] }
        return if numbers.empty?
        average = (numbers.inject(0, :+).to_f/86400)/numbers.size
        XCache::set("6ee981a4-315f-4f82-880f-5806424c904f", average)
    end

    # Listing::remove(itemuuid)
    def self.remove(itemuuid)
        $listing_database_semaphore.synchronize {
            db = SQLite3::Database.new(Listing::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _listing_ where _uuid_=?", [itemuuid]
            db.close
        }
    end

    # Listing::insert2(zone, item, ordinal, createdAt)
    def self.insert2(zone, item, ordinal, createdAt)
        Listing::insert(item["uuid"], zone, ordinal, LxFunction::function("toString", item), item, createdAt)
    end

    # Listing::insertOrReInsert(zone, item)
    def self.insertOrReInsert(zone, item)
        existingEntry = Listing::entries()
                            .select{|entry| entry["_uuid_"] == item["uuid"] }
                            .first
        if existingEntry then
            Listing::insert2(zone, item, existingEntry["_ordinal_"], existingEntry["_createdAt_"])
        else
            # Instead of using next ordinal here, we could interactively ask for it.
            Listing::insert2(zone, item, Listing::nextOrdinal(), Time.new.to_i)
        end
    end
end
