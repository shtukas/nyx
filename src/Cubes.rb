
# encoding: UTF-8

=begin
{
    "uuid"          : String
    "nyxNxSet"      : "06071daa-ec51-4c19-a4b9-62f39bb2ce4f"
    "unixtime"      : Float # Unixtime with decimals
    "description"   : String
    "location"      : String # Folder path to the listing
}
=end

class Cubes

    def self.issueCube(description, location)
        cube = {
            "uuid"          => SecureRandom.hex,
            "nyxNxSet"      => "06071daa-ec51-4c19-a4b9-62f39bb2ce4f",
            "unixtime"      => Time.new.to_f, # Unixtime with decimals
            "description"   => description,
            "location"      => location # Folder path to the listing
        }
    end
end
