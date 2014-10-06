-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2014 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
--
-- This module exports everything you need to describe and act with your
-- scene. Up to now, a few objects of the scene are supported:
-- 
--   - *camera*, which are simple projections;
--   - *lights*, which are 'Light's;
--   - *models*, which are 'Model's attached to 'Mesh'es.
--
-- Additionally, you’ll find 'IndexPath'. That is a special type used to
-- replace your name type used in your scene (commonly a 'String').
----------------------------------------------------------------------------

module Photon.Core.Scene (
    -- * Scene
    Scene(Scene)
  , scene
  , camera
  , lights
  , models
    -- * Scene relations
  , SceneRel(SceneRel)
  , sceneCamera
  , sceneLights
  , sceneMaterials
    -- * Optimized name
  , IndexPath(..)
  , indexPath
  ) where

import Control.Lens
import Data.Map as M ( Map, fromList )
import Data.Tuple ( swap )
import Data.Vector as V ( Vector, fromList )
import Photon.Core.Entity ( Entity )
import Photon.Core.Light ( Light )
import Photon.Core.Material ( Material )
import Photon.Core.Mesh ( Mesh )
import Photon.Core.Projection ( Projection )

-- |Store scene’s relations. Up to now, it gathers relationships between:
--
--   - camera;
--   - objects;
--   - materials;
--   - lights.
data SceneRel a = SceneRel {
    -- |
    _cameraRel  :: Projection
    -- |
  , _lightsRel  :: [(a,Light)]
    -- |
  , _objectsRel :: [(Material,[(a,Mesh)])]
  } deriving (Eq,Show)

-- |Names are unique identifiers used to identify objects in a scene. For
-- instance, 'Scene String' has 'String' names. 'Scene Integer' has 'Integer'
-- names, and so on. That representation is handy, but it will obviously not
-- fit realtime expectations.
--
-- So comes 'IndexPath', a special name. It’s especially great because it comes
-- with a set of built-in properties. First, it enables you to access scene
-- objects in amortized constant time (*O(1)*). Secondly, any type of name used
-- in a scene can be converted to an 'IndexPath'. This is an extremely great
-- property, and means you can use any kind of name you want in your scene, you
-- still have the possibility to optimize the names away and use 'IndexPath'es.
--
-- Note: you can’t build 'IndexPath' on your own. Feel free to read the
-- documentation of the 'indexPath' function for further details.
newtype IndexPath = IndexPath { unIndexPath :: [Int] } deriving (Eq,Ord,Show)

makeLenses ''SceneRel
makeLenses ''IndexPath

-- |Map a name to its 'IndexPath' representation. That function should be
-- partially applied in order to get a mapping function
-- ('a -> Maybe IndexPath'):
--
--     indexPath scene
--
-- You can then use that to change all names of your scene at once or change
-- similar structure’s names (see 'EntityGraph').
--
--     fmap (fromJust . indexPath scene) scene
indexPath :: (Ord a) => SceneRel a -> Map a IndexPath
indexPath sc = M.fromList (scligs ++ scobjs)
  where
    scligs   = map (fmap ip1 . swap) . ixed . map fst $ sc^.lightsRel
    scobjs   = concatMap (\(i0,nmsh) -> map (fmap (ip2 i0) . swap) . ixed $ map fst nmsh) . ixed . map snd $ sc^.objectsRel
    ixed     = zip [0..]
    ip1 i    = IndexPath [i]
    ip2 i0 i = IndexPath [i0,i]

-- |Entities are stored in a `Scene`.
data Scene a = Scene {
    -- |Active camera.
    _camera  :: Entity a
    -- |All objects.
  , _objects :: Vector (Entity a)
    -- |All lights.
  , _lights  :: Vector (Entity a)
  } deriving (Eq,Functor,Show)

makeLenses ''Scene

-- |Build a scene.
scene :: Entity a -> [Entity a] -> [Entity a] -> Scene a
scene c m l = Scene c (V.fromList m) (V.fromList l)
