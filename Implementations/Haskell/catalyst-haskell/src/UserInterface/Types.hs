module UserInterface.Types where

{-

NS16 {
    "uuid"        : String # used by DoNotShowUntil
    "announce"    : String
}

-}

type UUID = String
type Announce = String

data NS16 = NS16 UUID Announce
                deriving (Show)

