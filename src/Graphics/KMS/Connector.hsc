module Graphics.KMS.Connector where

import Foreign
import Foreign.C
import System.Posix

#include<stdint.h>
#include<xf86drmMode.h>

import Graphics.KMS.Types
import Graphics.KMS.ModeInfo
import Graphics.KMS.Utils

data Connector = Connector
                  { connectorId :: ConnectorId
                  , connectorCurrentEncoder :: EncoderId
                  , connectorType :: ConnectorType
                  , connectorTypeId :: Word32
                  , connectorConnection :: Connection
                  , mmSize :: (Word32,Word32)
                  , connectorSubpixel :: SubPixel
                  , connectorModeInfo :: [ModeInfo]
                  , connectorProperties :: [Property]
                  , connectorEncoders :: [EncoderId]
                  } deriving (Show)

#define hsc_p(field) hsc_peek(drmModeConnector, field)

peekConnector :: Ptr Connector -> IO Connector
peekConnector ptr = do
  cId <- (#p connector_id) ptr
  currEncoder <- (#p encoder_id) ptr
  cType <- (#p connector_type) ptr
  typeId <- (#p connector_type_id) ptr
  connection <- (#p connection) ptr
  width <- (#p mmWidth) ptr
  height <- (#p mmHeight) ptr
  subpixel <- (#p subpixel) ptr
  modes <- lPeekArray ptr (#p count_modes) (#p modes)
  propertiesCount <- (#p count_props) ptr
  let properties = replicate propertiesCount ()
  encoders <- lPeekArray ptr (#p count_encoders) (#p encoders)
  return $ Connector cId currEncoder cType typeId connection
    (width,height) subpixel modes properties encoders

getConnector :: (?drm :: Drm) ⇒ ConnectorId -> IO Connector
getConnector cId = do
  ptr <- throwErrnoIfNull "drmModeGetConnector" (drmModeGetConnector ?drm cId)
  connector <- peekConnector ptr
  drmModeFreeConnector ptr
  return connector

data Connection = Connected | Disconnected | UnknownConnection deriving (Show, Eq)

connectionEnum :: [(CInt,Connection)]
connectionEnum = [
  ((#const DRM_MODE_CONNECTED), Connected) ,
  ((#const DRM_MODE_DISCONNECTED), Disconnected) ,
  ((#const DRM_MODE_UNKNOWNCONNECTION), UnknownConnection) ]

instance Storable Connection where
  sizeOf _ = sizeOf (undefined :: CInt)
  alignment _ = alignment (undefined :: CInt)
  peek = peekEnum connectionEnum
  poke = undefined

isConnected :: Connector -> Bool
isConnected = (== Connected) . connectorConnection

data SubPixel = UnknownSubPixel | HorizontalRGB | HorizontalBGR | VerticalRGB | VerticalBGR | None deriving (Show, Eq)

subpixelEnum :: [(CInt,SubPixel)]
subpixelEnum = [
  ((#const DRM_MODE_SUBPIXEL_UNKNOWN), UnknownSubPixel) ,
  ((#const DRM_MODE_SUBPIXEL_HORIZONTAL_RGB), HorizontalRGB) ,
  ((#const DRM_MODE_SUBPIXEL_HORIZONTAL_BGR), HorizontalBGR) ,
  ((#const DRM_MODE_SUBPIXEL_VERTICAL_RGB), VerticalRGB) ,
  ((#const DRM_MODE_SUBPIXEL_VERTICAL_BGR), VerticalBGR) ,
  ((#const DRM_MODE_SUBPIXEL_NONE), None) ]

instance Storable SubPixel where
  sizeOf _ = sizeOf (undefined :: CInt)
  alignment _ = alignment (undefined :: CInt)
  peek = peekEnum subpixelEnum
  poke = undefined

data ConnectorType = UnknownConnectorType | VGA | DVII | DVID | DVIA | Composite | SVIDEO | LVDS | Component | NinePinDIN | DisplayPort | HDMIA | HDMIB | TV | EDP deriving (Show, Eq)

connectorTypeEnum :: [(Word32,ConnectorType)]
connectorTypeEnum = [
  ((#const DRM_MODE_CONNECTOR_Unknown), UnknownConnectorType) ,
  ((#const DRM_MODE_CONNECTOR_VGA), VGA) ,
  ((#const DRM_MODE_CONNECTOR_DVII), DVII) ,
  ((#const DRM_MODE_CONNECTOR_DVID), DVID) ,
  ((#const DRM_MODE_CONNECTOR_DVIA), DVIA) ,
  ((#const DRM_MODE_CONNECTOR_Composite), Composite) ,
  ((#const DRM_MODE_CONNECTOR_SVIDEO), SVIDEO) ,
  ((#const DRM_MODE_CONNECTOR_LVDS), LVDS) ,
  ((#const DRM_MODE_CONNECTOR_Component), Component) ,
  ((#const DRM_MODE_CONNECTOR_9PinDIN), NinePinDIN) ,
  ((#const DRM_MODE_CONNECTOR_DisplayPort), DisplayPort) ,
  ((#const DRM_MODE_CONNECTOR_HDMIA), HDMIA) ,
  ((#const DRM_MODE_CONNECTOR_HDMIB), HDMIB) ,
  ((#const DRM_MODE_CONNECTOR_TV), TV) ,
  ((#const DRM_MODE_CONNECTOR_eDP), EDP) ]

instance Storable ConnectorType where
  sizeOf _ = sizeOf (undefined :: Word32)
  alignment _ = alignment (undefined :: Word32)
  peek = peekEnum connectorTypeEnum
  poke = undefined

type Property = ()

foreign import ccall "drmModeGetConnector"
  drmModeGetConnector :: Drm -> ConnectorId -> IO (Ptr Connector)
foreign import ccall "drmModeFreeConnector"
  drmModeFreeConnector :: Ptr Connector -> IO ()