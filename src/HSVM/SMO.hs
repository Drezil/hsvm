module HSVM.SMO where

-- | This is an implementation of the Sequential
-- Minimal Optimization-Algorithm
--
-- This is not the fastes Algortihm for optimizing
-- the dual Problem of SVMs, but it is easily
-- implemented and outperforms many other more
-- complicated solutions.
--
-- For more info see:
-- http://research-srv.microsoft.com/pubs/69644/tr-98-14.pdf
-- doi: 10.1.1.43.4376

import SubHask
import SubHask.Algebra.Array
import SubHask.Algebra.Vector
import Data.Primitive
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.Function as F
import Data.Ord (comparing, Down(..))

getGradient :: (Field a, Prim a, ValidScalar a, Logic a ~ Bool, Scalar a ~ a, FreeModule a)
            => (UVector (d::Symbol) a -> UVector (d::Symbol) a -> Scalar a)  -- ^ Kernel-Function
            -> BArray (Labeled' (UVector (d::Symbol) a) Bool)                -- ^ Data-set
            -> Scalar a                                                      -- ^ C
            -> UVector (d::Symbol) a                                         -- ^ resulting gradient
getGradient k xys (c :: Scalar a) =
                let alpha   = (unsafeToModule $ P.replicate numData (zero::a)) :: UVector (n::Symbol) a
                    g       = (unsafeToModule $ P.replicate numDim (one::a))   :: UVector (d::Symbol) a
                    numData = length xys
                    numDim  = dim $ xLabeled' $ xys!0
                in
                getGradient' k xys c alpha g
        where
                getGradient' :: (Field a, Prim a, ValidScalar a, Logic a ~ Bool, Scalar a ~ a, FreeModule a)
                             => (UVector (d::Symbol) a -> UVector (d::Symbol) a -> Scalar a)  -- ^ Kernel-Function
                             -> BArray (Labeled' (UVector (d::Symbol) a) Bool)                -- ^ Data-set
                             -> Scalar a                                                      -- ^ C
                             -> UVector (n::Symbol) a                                         -- ^ alphas
                             -> UVector (d::Symbol) a                                         -- ^ gradients
                             -> UVector (d::Symbol) a                                         -- ^ resulting gradient
                getGradient' k xys c alpha g =
                        let i = fst . P.head . L.sortBy (comparing $        snd) . fmap (\(i,gi) -> (i, y i $ gi)) . P.filter filterI . toIxList $ g
                            j = fst . P.head . L.sortBy (comparing $ Down . snd) . fmap (\(i,gi) -> (i, y i $ gi)) . P.filter filterJ . toIxList $ g
                            filterI (i, _) = (y i $ alpha ! i) < c
                            filterJ (i, _) = (y i $ alpha ! i) > 0
                            x i =           xLabeled' $ xys!i
                            y i = boolToOp (yLabeled' $ xys!i)
                        in
                        g


boolToOp :: Group a => Bool -> a -> a
boolToOp True  = id
boolToOp False = negate

