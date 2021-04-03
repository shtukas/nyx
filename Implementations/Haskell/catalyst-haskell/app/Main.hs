module Main where

import UserInterface.Types as UI

main :: IO ()
main = do
        putStrLn "[]"
        putStrLn $ show $ UI.NS16 "d0efe9b6-886d-4295-b4f2-f756fd9cf355" "Testing from Haskell"
