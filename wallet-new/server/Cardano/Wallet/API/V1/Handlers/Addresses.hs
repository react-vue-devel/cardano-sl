{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}
module Cardano.Wallet.API.V1.Handlers.Addresses where

import           Universum

import qualified Cardano.Wallet.API.V1.Addresses as Addresses
import           Cardano.Wallet.API.V1.Types

import           Servant

handlers :: Server Addresses.API
handlers =  listAddresses
       :<|> newAddress

listAddresses :: Maybe Page
              -> Maybe PerPage
              -> Maybe Bool
              -> Maybe Text
              -> Handler (OneOf [Address] (ExtendedResponse [Address]))
listAddresses _ _ mbExtended _ =
  case mbExtended of
    Just True  -> return $ OneOf $ Right $
      ExtendedResponse {
        extData = [Address "deadBeef", Address "123AABBCC"]
      , extMeta = Metadata {
          metaTotalPages = 1
        , metaPage = 1
        , metaPerPage = 20
        , metaTotalEntries = 2
      }
      }
    _ -> return $ OneOf $ Left  [Address "deadBeef", Address "123AABBCC"]

newAddress :: Address -> Handler Address
newAddress a = return a
