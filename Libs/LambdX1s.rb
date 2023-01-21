# encoding: UTF-8

class LambdX1s

    # LambdX1s::make(uuid, announce, l)
    def self.make(uuid, announce, l)
        {
            "uuid"     => uuid,
            "mikuType" => "LambdX1",
            "announce" => announce,
            "lambda"   => l
        }
    end
end
