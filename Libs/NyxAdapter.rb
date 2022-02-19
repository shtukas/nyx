
# encoding: UTF-8

class NyxAdapter

    # NyxAdapter::locationToNyx(location)
    def self.locationToNyx(location)
        puts "location: #{location}"
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""

        atom = CoreData5::issueAionPointAtomUsingLocation(location)

        puts JSON.pretty_generate(atom)

        LibrarianObjects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx31",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }

        puts JSON.pretty_generate(item)

        LibrarianObjects::commit(item)

        # THe Nx31 has been created, we just need to land on it for linkings

        system("/Users/pascal/Galaxy/Software/Nyx/binaries/nyx-landing #{uuid}")
    end
end
