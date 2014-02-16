module Test.Hspec.Core.Hooks (
  before
, beforeAll
, beforeAllWith
, after
, after_
, afterAll
, around
, around_
, aroundWith
) where

import           Control.Exception (finally)
import           Control.Concurrent.MVar

import           Test.Hspec.Core.Type

-- | Run a custom action before every spec item.
before :: IO a -> SpecWith a -> Spec
before action = around (action >>=)

-- | Run a custom action before the first spec item.
beforeAll :: IO a -> SpecWith a -> Spec
beforeAll action spec = do
  mvar <- runIO (newMVar Nothing)
  let action_ = memoize mvar action
  before action_ spec

memoize :: MVar (Maybe a) -> IO a -> IO a
memoize mvar action = modifyMVar mvar $ \ma -> case ma of
  Just a -> return (ma, a)
  Nothing -> do
    a <- action
    return (Just a, a)

-- | Run a custom action before all spec items.
beforeAllWith :: (b -> IO a) -> SpecWith a -> SpecWith b
beforeAllWith action spec = do
  mvar <- runIO (newMVar Nothing)
  let action_ = memoize mvar . action
  aroundWith (\e x -> action_ x >>= e) spec

-- | Run a custom action after every spec item.
after :: ActionWith a -> SpecWith a -> SpecWith a
after action = aroundWith $ \e x -> e x `finally` action x

-- | Run a custom action after every spec item.
after_ :: IO () -> Spec -> Spec
after_ action = after $ \() -> action

-- | Run a custom action before and/or after every spec item.
around :: (ActionWith a -> IO ()) -> SpecWith a -> Spec
around action = aroundWith $ \e () -> action e

-- | Run a custom action after the last spec item.
afterAll :: IO () -> Spec -> Spec
afterAll action spec = runIO (runSpecM spec) >>= fromSpecList . return . SpecWithCleanup action

-- | Run a custom action before and/or after every spec item.
around_ :: (IO () -> IO ()) -> Spec -> Spec
around_ action = around $ action . ($ ())

-- | Run a custom action before and/or after every spec item.
aroundWith :: (ActionWith a -> ActionWith b) -> SpecWith a -> SpecWith b
aroundWith action = mapAround (. action)

mapAround :: ((ActionWith b -> IO ()) -> ActionWith a -> IO ()) -> SpecWith a -> SpecWith b
mapAround f = mapSpecItem $ \i@Item{itemExample = e} -> i{itemExample = (. f) . e}