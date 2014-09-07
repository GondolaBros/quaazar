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

data Light
  = Omni LightProperties
    deriving (Eq,Show)

data LightProperties = LightProperties {
    -- |
    _ligColor     :: Color
    -- |
  , _ligShininess :: Float
    -- |
  , _ligPower     :: Float
  } deriving (Eq,Show)

makeLenses ''LightProperties
