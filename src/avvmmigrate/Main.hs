{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import           Data.Aeson           (FromJSON (..), withObject, (.:))
import qualified Data.Aeson           as A
import qualified Data.ByteString.Lazy as BSL
import           Data.HashMap.Strict  (HashMap)
import qualified Data.HashMap.Strict  as HM
import           System.Directory     (createDirectoryIfMissing)
import           System.FilePath      (takeDirectory)
import           Universum

import qualified Pos.Binary           as Bi
import           Pos.Crypto           (parseFullPublicKey)
import           Pos.Genesis          (GenesisData (..), StakeDistribution (..))
import           Pos.Types            (Address, Coin, makePubKeyAddress, unsafeAddCoin,
                                       unsafeIntegerToCoin)

main :: IO ()
main = do
    [fpath, outpath] <- getArgs
    jsonfile <- BSL.readFile fpath
    case A.eitherDecode jsonfile of
        Left err       -> panic (toText err)
        Right avvmData -> do
            let genesis = genGenesis avvmData
            createDirectoryIfMissing True (takeDirectory outpath)
            BSL.writeFile outpath (Bi.encode genesis)

type AvvmData = [AvvmEntry]

data AvvmCoin = AvvmCoin {
    coinAmount :: Integer,
    coinColor  :: Integer }
    deriving (Show, Generic)

instance FromJSON AvvmCoin where
    parseJSON = withObject "coin" $ \o -> do
        coinAmount <- o .: "coinAmount"
        coinColor <- o .: "coinColor" >>= (.: "getColor")
        return AvvmCoin{..}

data AvvmEntry = AvvmEntry {
    coin    :: AvvmCoin,
    address :: Text }
    deriving (Show, Generic)

instance FromJSON AvvmEntry

genGenesis :: AvvmData -> GenesisData
genGenesis avvm = GenesisData
    { gdAddresses = HM.keys balances
    , gdDistribution = ExplicitStakes balances
    , gdVssCertificates = mempty
    }
  where
    balances :: HashMap Address Coin
    balances = HM.fromListWith (unsafeAddCoin) $ do
        AvvmEntry{..} <- avvm
        let pk = case parseFullPublicKey address of
                Just x  -> x
                Nothing -> panic ("couldn't decode address " <> address)
        let addr = makePubKeyAddress pk
        return (addr, unsafeIntegerToCoin (coinAmount coin))

{-

    let distr = TestnetStakes
            { sdTotalStake = mkCoin koTotalStake
            , sdRichmen    = koRichmen
            , sdPoor       = koStakeholders - koRichmen
            }
        genesisAddrs = map (makePubKeyAddress . fst) genesisList
        genesisVssCerts = HM.fromList
                          $ map (_1 %~ addressHash)
                          $ take (fromIntegral koRichmen) genesisList
        genData = GenesisData
            { gdAddresses = genesisAddrs
            , gdDistribution = distr
            , gdVssCertificates = genesisVssCerts
            }
    BSL.writeFile koGenesisFile $ encode genData

-}
