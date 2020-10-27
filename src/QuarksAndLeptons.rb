
# encoding: UTF-8

class Quark

    # Quark::quarks()
    def self.quarks()
        NyxObjects2::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # Quark::issueLine(line)
    def self.issueLine(line)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepth = Lepton::leptonFilenameToFilepath(leptonfilename)
        Lepton::createLeptonLine(leptonfilepth, line)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quark::issueUrl(url)
    def self.issueUrl(url)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepth = Lepton::leptonFilenameToFilepath(leptonfilename)
        Lepton::createLeptonUrl(leptonfilepth, url)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quark::toString(quark)
    def self.toString(quark)
        leptonfilename = quark["leptonfilename"]
        "[quark] #{leptonfilename}"
    end

    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            source = Arrows::getSourcesForTarget(quark)
            source.each{|source|
                mx.item(
                    "source: #{NyxObjectInterface::toString(source)}",
                    lambda { NyxObjectInterface::landing(source) }
                )
            }

            puts ""

            puts Quark::toString(quark).green

            puts ""

            Arrows::getTargetsForSource(quark).each{|target|
                menuitems.item(
                    "target: #{NyxObjectInterface::toString(target)}",
                    lambda { NyxObjectInterface::landing(target) }
                )
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end

class Lepton

    # Lepton::createLeptonLine(filepath, line)
    def self.createLeptonLine(filepath, line)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "line"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", line]
        db.close
    end

    # Lepton::createLeptonUrl(filepath, url)
    def self.createLeptonUrl(filepath, url)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "url"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", url]
        db.close
    end

    # Lepton::leptonFilenameToFilepath(filename)
    def self.leptonFilenameToFilepath(filename)
        "/Users/pascal/Galaxy/Leptons/#{filename}"
    end

end