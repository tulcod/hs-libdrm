{-# LANGUAGE RecordWildCards #-}

module System.DRM.KMS.Crtc (Crtc(..),getCrtc) where

import Foreign
import Foreign.C.Error

import System.DRM.C.KMS.Crtc
import System.DRM.KMS.ModeInfo
import System.DRM.C.KMS.ModeInfo
import System.DRM.Types

data Crtc drm = ConnectedCrtc
                { crtcId ∷ CrtcId drm
                , crtcFbId ∷ FbId drm
                , crtcPosition ∷ (Word32,Word32)
                , crtcPxSize ∷ (Word32,Word32)
                , crtcMode ∷ ModeInfo
                , crtcGammaSize ∷ Int
                } |
                DisconnectedCrtc
                { crtcId ∷ CrtcId drm
                , crtcPosition ∷ (Word32,Word32)
                , crtcPxSize ∷ (Word32,Word32)
                , crtcGammaSize ∷ Int
                } deriving (Show)

cToCrtc ∷ C'drmModeCrtc → Crtc drm
cToCrtc (C'drmModeCrtc{c'drmModeCrtc'buffer_id = 0, ..}) =
  DisconnectedCrtc
  (CrtcId c'drmModeCrtc'crtc_id)
  (c'drmModeCrtc'x,c'drmModeCrtc'y)
  (c'drmModeCrtc'width,c'drmModeCrtc'height)
  (fromIntegral c'drmModeCrtc'gamma_size)
cToCrtc (C'drmModeCrtc{..}) |modeValid =
  ConnectedCrtc
  (CrtcId c'drmModeCrtc'crtc_id)
  (FbId c'drmModeCrtc'buffer_id)
  (c'drmModeCrtc'x,c'drmModeCrtc'y)
  (c'drmModeCrtc'width,c'drmModeCrtc'height)
  (cToModeInfo c'drmModeCrtc'mode)
  (fromIntegral c'drmModeCrtc'gamma_size)
                            |otherwise =
                              error "Connected CRTC mode not valid"
  where modeValid = toBool c'drmModeCrtc'mode_valid

getCrtc ∷ (RDrm drm) ⇒
           CrtcId drm → IO (Crtc drm)
getCrtc cId = do
  ptr ← throwErrnoIfNull "drmModeGetCrtc" $
         applyDrm c'drmModeGetCrtc cId
  crtc ← fmap cToCrtc $ peek ptr
  c'drmModeFreeCrtc ptr
  return crtc