-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2014 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
--
-- Lighting is required in order to see non-emissive objects.
--
-- 'Light' exposes the light type. You can find these types of light:
--
--   - 'Omni': omni lights – a.k.a. point lights – are lights that emit in
--     all directions
--
-- Whatever the type of a light, it holds lighting information via a value
-- of type 'LightProperties'.
----------------------------------------------------------------------------

module Photon.Core.Light (
    -- * Light
    Light(..)
    -- * Light properties
  , LightProperties(LightProperties)
  , ligColor
  , ligShininess
  , ligPower
  ) where

import Control.Lens
import Photon.Core.Color ( Color )

-- |Light. Extra information (cuttoff angle for instance) can be added
-- regarding the type of the light.
data Light
  = Omni LightProperties -- ^ Omni light
    deriving (Eq,Show)

-- |Lighting properties. This type is shared by lights.
data LightProperties = LightProperties {
    -- |Color of the light.
    _ligColor     :: Color
    -- |Shininess of the light. That property directly affects the
    -- specular aspect of the light. The greater it is, the intense
    -- the specular effect is.
  , _ligShininess :: Float
    -- |Power of the light – a.k.a. radius. Used to alter the attenuation
    -- of the light over distance.
  , _ligPower     :: Float
  } deriving (Eq,Show)

makeLenses ''LightProperties
