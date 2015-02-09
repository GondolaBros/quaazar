{-# LANGUAGE RankNTypes #-}

-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2014 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
--
----------------------------------------------------------------------------

module Quaazar.Render.PostFX where

import Control.Monad.Error.Class ( MonadError )
import Control.Monad.Trans ( MonadIO(..) )
import Quaazar.Core.PostFX
import Quaazar.Render.GL.Texture
import Quaazar.Render.GL.Shader ( Uniformable )
import Quaazar.Render.Shader
import Quaazar.Utils.Log ( Log, MonadLogger )

data GPUPostFX a = GPUPostFX { usePostFX :: Texture2D -> a -> IO () }

-- TODO
{-
instance GPU PostFX (GPUPostFX a) where
  gpu pfx = evalJournalT $ do
    gpupfx <- gpuPostFX pfx
    sinkLogs
    return gpupfx
-}

gpuPostFX :: (MonadIO m,MonadLogger m,MonadError Log m)
          => PostFX
          -> ((forall u. (Uniformable u) => String -> IO (Maybe u -> IO ())) -> IO (a -> IO ()))
          -> m (GPUPostFX a)
gpuPostFX (PostFX src) uniforms = do
    gpuprogram <- gpuProgram vsSrc Nothing src uniforms
    return $ GPUPostFX (use gpuprogram)
  where
    use gpuprogram sourceTex a = do
      bindTextureAt sourceTex 0
      useProgram gpuprogram a

gpuPostFXFree :: (MonadIO m,MonadLogger m,MonadError Log m)
              => PostFX
              -> m (GPUPostFX ())
gpuPostFXFree pfx = gpuPostFX pfx $ \_ -> return $ \_ -> return ()

vsSrc :: String
vsSrc = unlines
    [
    "#version 430 core"
  , "out vec2 uv;"
  , "vec2[4] v = vec2[]("
  , "    vec2(-1,  1)"
  , "  , vec2( 1,  1)"
  , "  , vec2(-1, -1)"
  , "  , vec2( 1, -1)"
  , "  );"
  , "void main() {"
  , "  uv = (v[gl_VertexID] + 1) * 0.5;"
  , "  gl_Position = vec4(v[gl_VertexID], 0., 1.);"
  , "}"
  ]