{-# LANGUAGE ScopedTypeVariables #-}

-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2014 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
----------------------------------------------------------------------------

module Photon.Resource.Loader (
    -- * Resource loaders
    loadMesh
  , loadMaterial
  , loadLight
    -- * More complex loaders
  , loadLights
  , loadMeshes
  , loadObjectsPerMaterial
  , loadObjects
  , loadSceneRel
  ) where

import Control.Applicative
import Control.Monad ( MonadPlus(..) )
import Control.Monad ( liftM )
import Control.Monad.Trans ( MonadIO, liftIO )
import Data.ByteString.Lazy as B ( readFile )
import Data.Aeson
import Photon.Core.Light ( Light )
import Photon.Core.Material ( Material )
import Photon.Core.Mesh ( Mesh )
import Photon.Core.Projection ( Projection )
import Photon.Core.Scene ( SceneRel(..) )
import Photon.Utils.Log
import System.FilePath

loadJSON :: (FromJSON a,MonadIO m) => FilePath -> m (Either String a)
loadJSON path = liftM eitherDecode (liftIO $ B.readFile path)

loadMesh :: (MonadIO m,MonadLogger m,MonadPlus m) => String -> m Mesh
loadMesh n = loadJSON path >>= either loadError ok 
  where
    path        = "meshes" </> n <.> "ymsh"
    loadError e = do
      err CoreLog $ "failed to load mesh '" ++ path ++ "': " ++ e
      mzero
    ok msh      = do
      info CoreLog $ "loaded mesh '" ++ path ++ "'"
      return msh

loadMaterial :: (MonadIO m,MonadLogger m,MonadPlus m) => String -> m Material
loadMaterial n = loadJSON path >>= either loadError return
  where
    path        = "materials" </> n <.> "ymdl"
    loadError e = do
      err CoreLog $ "failed to load material '" ++ path ++ "': " ++ e
      mzero

loadLight :: (MonadIO m,MonadLogger m,MonadPlus m) => String -> m Light
loadLight n = loadJSON path >>= either loadError return
  where
    path        = "lights" </> n <.> "ylig"
    loadError e = do
      err CoreLog $ "failed to load light '" ++ path ++ "': " ++ e
      mzero

-- FIXME: GHC 7.10 Applicative-Monad proposal
loadLights :: (Applicative m,MonadIO m,MonadLogger m,MonadPlus m) => [String] -> m [(String,Light)]
loadLights = fmap <$> zip <*> mapM loadLight

loadMeshes :: (Applicative m,MonadIO m,MonadLogger m,MonadPlus m) => [String] -> m [(String,Mesh)]
loadMeshes = fmap <$> zip <*> mapM loadMesh

loadObjectsPerMaterial :: (Applicative m,MonadIO m,MonadLogger m,MonadPlus m) => String -> [String] -> m (Material,[(String,Mesh)])
loadObjectsPerMaterial mat objs = (,) <$> loadMaterial mat <*> loadMeshes objs

loadObjects :: (Applicative m,MonadIO m,MonadLogger m,MonadPlus m) => [(String,[String])] -> m [(Material,[(String,Mesh)])]
loadObjects = mapM (uncurry loadObjectsPerMaterial)

loadSceneRel :: (Applicative m,MonadIO m,MonadLogger m,MonadPlus m) => [String] -> [(String,[String])] -> Projection -> m (SceneRel String)
loadSceneRel ligs objs proj = SceneRel proj <$> loadLights ligs <*> loadObjects objs
