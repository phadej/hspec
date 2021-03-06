{-# LANGUAGE DeriveFunctor #-}

{-# LANGUAGE CPP #-}
#if MIN_VERSION_base(4,8,1)
#define HAS_SOURCE_LOCATIONS
{-# LANGUAGE ImplicitParams #-}
#endif

-- |
-- Stability: unstable
module Test.Hspec.Core.Tree (
  SpecTree
, Tree (..)
, Item (..)
, specGroup
, specItem
) where

#ifdef HAS_SOURCE_LOCATIONS
#if !MIN_VERSION_base(4,9,0)
import           GHC.SrcLoc
#endif
import           GHC.Stack
#endif

import           Prelude ()
import           Test.Hspec.Compat

import           Test.Hspec.Core.Example

-- | Internal tree data structure
data Tree c a =
    Node String [Tree c a]
  | NodeWithCleanup c [Tree c a]
  | Leaf a
  deriving Functor

instance Foldable (Tree c) where -- Note: GHC 7.0.1 fails to derive this instance
  foldMap = go
    where
      go :: Monoid m => (a -> m) -> Tree c a -> m
      go f t = case t of
        Node _ xs -> foldMap (foldMap f) xs
        NodeWithCleanup _ xs -> foldMap (foldMap f) xs
        Leaf x -> f x

instance Traversable (Tree c) where -- Note: GHC 7.0.1 fails to derive this instance
  sequenceA = go
    where
      go :: Applicative f => Tree c (f a) -> f (Tree c a)
      go t = case t of
        Node label xs -> Node label <$> sequenceA (map go xs)
        NodeWithCleanup action xs -> NodeWithCleanup action <$> sequenceA (map go xs)
        Leaf a -> Leaf <$> a

-- | A tree is used to represent a spec internally.  The tree is parametrize
-- over the type of cleanup actions and the type of the actual spec items.
type SpecTree a = Tree (ActionWith a) (Item a)

-- |
-- @Item@ is used to represent spec items internally.  A spec item consists of:
--
-- * a textual description of a desired behavior
-- * an example for that behavior
-- * additional meta information
--
-- Everything that is an instance of the `Example` type class can be used as an
-- example, including QuickCheck properties, Hspec expectations and HUnit
-- assertions.
data Item a = Item {
  -- | Textual description of behavior
  itemRequirement :: String
  -- | Source location of the spec item
, itemLocation :: Maybe Location
  -- | A flag that indicates whether it is safe to evaluate this spec item in
  -- parallel with other spec items
, itemIsParallelizable :: Bool
  -- | Example for behavior
, itemExample :: Params -> (ActionWith a -> IO ()) -> ProgressCallback -> IO Result
}

-- | The @specGroup@ function combines a list of specs into a larger spec.
specGroup :: String -> [SpecTree a] -> SpecTree a
specGroup s = Node msg
  where
    msg
      | null s = "(no description given)"
      | otherwise = s

-- | The @specItem@ function creates a spec item.
#ifdef HAS_SOURCE_LOCATIONS
specItem :: (?loc :: CallStack, Example a) => String -> a -> SpecTree (Arg a)
#else
specItem :: Example a => String -> a -> SpecTree (Arg a)
#endif
specItem s e = Leaf $ Item requirement location False (evaluateExample e)
  where
    requirement
      | null s = "(unspecified behavior)"
      | otherwise = s

    location :: Maybe Location
#ifdef HAS_SOURCE_LOCATIONS
    location = case reverse (getCallStack ?loc) of
      (_, loc) : _ -> Just (Location (srcLocFile loc) (srcLocStartLine loc) (srcLocStartCol loc) ExactLocation)
      _ -> Nothing
#else
    location = Nothing
#endif
