-- |
-- This module provides Hspec's core primitives.  It is less stable than other
-- parts of the API.  For most use cases "Test.Hspec" is more suitable.
module Test.Hspec.Core (
-- * Types
  SpecTree
, Example (..)
, Params (..)
, Result (..)
, Pending

-- * Defining a spec
, describe
, it
, pending

-- * Running a spec
, hspec
, hspecWith
, Summary (..)

-- * Deprecated types and functions
, Spec
, Specs
, hspecB
, hspecX
, hHspec
) where

import           Control.Applicative
import           System.IO (Handle)

import           Test.Hspec.Internal hiding (Spec)
import           Test.Hspec.Pending
import qualified Test.Hspec.Runner as Runner
import           Test.Hspec.Runner (Summary(..), Config(..), defaultConfig)
import           Test.Hspec.Monadic (fromSpecList)

hspec :: [SpecTree] -> IO ()
hspec = Runner.hspec . fromSpecList

-- | Create a document of the given specs and write it to stdout.
--
-- Return `True` if all examples passe, `False` otherwise.
hspecWith :: Config -> [SpecTree] -> IO Summary
hspecWith c = Runner.hspecWith c . fromSpecList

{-# DEPRECATED hspecX "use `hspec` instead" #-}           -- since 1.2.0
hspecX :: [SpecTree] -> IO ()
hspecX = hspec

{-# DEPRECATED hspecB "use `hspecWith` instead" #-}       -- since 1.4.0
hspecB :: [SpecTree] -> IO Bool
hspecB spec = (== 0) . summaryFailures <$> hspecWith defaultConfig spec

{-# DEPRECATED hHspec "use `hspecWith` instead" #-}       -- since 1.4.0
hHspec :: Handle -> [SpecTree] -> IO Summary
hHspec h = hspecWith defaultConfig {configHandle = h}

{-# DEPRECATED Spec "use `SpecTree` instead" #-}          -- since 1.4.0
type Spec = SpecTree

{-# DEPRECATED Specs "use `[SpecTree]` instead" #-}       -- since 1.4.0
type Specs = [SpecTree]
