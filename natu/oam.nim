## Object Attribute Memory functions
## =================================

{.warning[UnusedImport]: off.}

import ./math
import private/[common, types, memdef]
from private/core import oamSizes
from private/memmap import objMem, objAffMem
from private/utils import writeFields

export objMem, objAffMem
export ObjAttr, ObjAffine, ObjAttrPtr, ObjAffinePtr

{.compile(toncPath & "/src/tonc_oam.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}

{.pragma: tonc, header: "tonc_oam.h".}

type
  ObjMode* {.size:2.} = enum
    omReg = ATTR0_REG
    omAff = ATTR0_AFF
    omHide = ATTR0_HIDE
    omAffDbl = ATTR0_AFF_DBL
  
  ObjFxMode* {.size:2.} = enum
    fxNone = 0
      ## Normal object, no special effects.
    fxBlend = ATTR0_BLEND
      ## Alpha blending enabled.
      ## The object is effectively placed into the `bldcnt.a` layer to be blended
      ## with the `bldcnt.b` layer using the coefficients from `bldalpha`,
      ## regardless of the current `bldcnt.mode` setting.
    fxWindow = ATTR0_WINDOW
      ## The sprite becomes part of the object window.
  
  ObjSize* {.size:2.} = enum
    ## Sprite size constants, high-level interface.
    ## Each corresponds to a pair of fields (`size` in attr0, `shape` in attr1)
    s8x8, s16x16, s32x32, s64x64,
    s16x8, s32x8, s32x16, s64x32,
    s8x16, s8x32, s16x32, s32x64

{.push inline.}

func setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint16) =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

func setAttr*(obj: var ObjAttr; a0, a1, a2: uint16) =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2


# Obj affine procedures
# ---------------------

proc init(oaff: ObjAffinePtr; pa, pb, pc, pd: Fixed) {.importc: "obj_aff_set", tonc.}
proc setToIdentity(oaff: ObjAffinePtr) {.importc: "obj_aff_identity", tonc.}
proc setToScale(oaff: ObjAffinePtr; sx, sy: Fixed) {.importc: "obj_aff_scale", tonc.}
proc setToShearX(oaff: ObjAffinePtr; hx: Fixed) {.importc: "obj_aff_shearx", tonc.}
proc setToShearY(oaff: ObjAffinePtr; hy: Fixed) {.importc: "obj_aff_sheary", tonc.}
proc setToRotation(oaff: ObjAffinePtr; alpha: uint16) {.importc: "obj_aff_rotate", tonc.}
proc setToScaleAndRotation(oaff: ObjAffinePtr; sx, sy: Fixed; alpha: uint16) {.importc: "obj_aff_rotscale", tonc.}
proc setToScaleAndRotation(oaff: ObjAffinePtr; affSrc: ptr AffSrc) {.importc: "obj_aff_rotscale2", tonc.}
proc preMul(dst: ObjAffinePtr, src: ObjAffinePtr) {.importc: "obj_aff_premul", tonc.}
proc postMul(dst: ObjAffinePtr, src: ObjAffinePtr) {.importc: "obj_aff_postmul", tonc.}
proc rotscaleEx(obj: var ObjAttr; oaff: ObjAffinePtr; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", tonc.}
proc setToScaleInv(oa: ObjAffinePtr; wx, wy: Fixed) {.importc: "obj_aff_scale_inv", tonc.}
proc setToRotationInv(oa: ObjAffinePtr; theta: uint16) {.importc: "obj_aff_rotate_inv", tonc.}
proc setToShearXInv(oa: ObjAffinePtr; hx: Fixed) {.importc: "obj_aff_shearx_inv", tonc.}
proc setToShearYInv(oa: ObjAffinePtr; hy: Fixed) {.importc: "obj_aff_sheary_inv", tonc.}

proc init*(oaff: var ObjAffine; pa, pb, pc, pd: Fixed) =
  init(addr oaff, pa, pb, pc, pd)
  ## Set the elements of an object affine matrix.

proc setToIdentity*(oaff: var ObjAffine) {.importc: "obj_aff_identity", tonc.}
  ##  Set an object affine matrix to the identity matrix.

proc setToScale*(oaff: var ObjAffine; sx, sy: Fixed) {.importc: "obj_aff_scale", tonc.}
  ## Set an object affine matrix for scaling.
  
proc setToShearX*(oaff: var ObjAffine; hx: Fixed) {.importc: "obj_aff_shearx", tonc.}

proc setToShearY*(oaff: var ObjAffine; hy: Fixed) {.importc: "obj_aff_sheary", tonc.}

proc setToRotation*(oaff: var ObjAffine; alpha: uint16) {.importc: "obj_aff_rotate", tonc.}
  ## Set obj matrix to counter-clockwise rotation.
  ## `oaff`  Object affine struct to set.
  ## `alpha` CCW angle. full-circle is 10000h.
  
proc setToScaleAndRotation*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) {.importc: "obj_aff_rotscale", tonc.}
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## `oaff`  Object affine struct to set.
  ## `sx`    Horizontal scale (zoom). .8 fixed point.
  ## `sy`    Vertical scale (zoom). .8 fixed point.
  ## `alpha` CCW angle. full-circle is 10000h.

proc setToScaleAndRotation*(oaff: var ObjAffine; affSrc: ptr AffSrc) {.importc: "obj_aff_rotscale2", tonc.}
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## `oaff` Object affine struct to set.
  ## `as`   Struct with scales and angle.

proc preMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_premul", tonc.}
  ## Pre-multiply the matrix `dst` by `src`
  ## i.e. ::
  ##   dst = src * dst

proc postMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_postmul", tonc.}
  ## Post-multiply the matrix `dst` by `src`
  ## i.e. ::
  ##   dst = dst * src

template preMul*(dst: var ObjAffine, src: ObjAffine) = preMul(dst, unsafeAddr src)
template postMul*(dst: var ObjAffine, src: ObjAffine) = postMul(dst, unsafeAddr src)

proc rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", tonc.}
  ## Rot/scale an object around an arbitrary point.
  ## Sets up `obj` and `oaff` for rot/scale transformation around an arbitrary point using the `asx` data.
  ## `obj`  Object to set.
  ## `oaff` Object affine data to set.
  ## `asx`  Affine source data: screen and texture origins, scales and angle.

template rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: AffSrcEx) =
  rotscaleEx(obj, oaff, unsafeAddr asx)

#  inverse (object -> screen) functions, could be useful
proc setToScaleInv*(oa: var ObjAffine; wx, wy: Fixed) {.importc: "obj_aff_scale_inv", tonc.}

proc setToRotationInv*(oa: var ObjAffine; theta: uint16) {.importc: "obj_aff_rotate_inv", tonc.}

proc setToShearXInv*(oa: var ObjAffine; hx: Fixed) {.importc: "obj_aff_shearx_inv", tonc.}

proc setToShearYInv*(oa: var ObjAffine; hy: Fixed) {.importc: "obj_aff_sheary_inv", tonc.}


# SPRITE GETTERS/SETTERS
# ----------------------

# copy attr0,1,2 from one object into another
func setAttr*(obj: ObjAttrPtr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)
func setAttr*(obj: var ObjAttr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)
func clear*(obj: ObjAttrPtr) {.inline, deprecated:"Use obj.init() to clear".} = setAttr(obj, 0, 0, 0)
func clear*(obj: var ObjAttr) {.inline, deprecated:"Use obj.init() to clear".} = setAttr(addr obj, 0, 0, 0)

# getters

func x*(obj: ObjAttr): int = (obj.attr1 and ATTR1_X_MASK).int
func y*(obj: ObjAttr): int = (obj.attr0 and ATTR0_Y_MASK).int
func pos*(obj: ObjAttr): Vec2i = vec2i(obj.x, obj.y)
func mode*(obj: ObjAttr): ObjMode = (obj.attr0 and ATTR0_MODE_MASK).ObjMode
func fx*(obj: ObjAttr): ObjFxMode = (obj.attr0 and (ATTR0_BLEND or ATTR0_WINDOW)).ObjFxMode
func mos*(obj: ObjAttr): bool = (obj.attr0 and ATTR0_MOSAIC) != 0
func is8bpp*(obj: ObjAttr): bool = (obj.attr0 and ATTR0_8BPP) != 0
func aff*(obj: ObjAttr): int = ((obj.attr1 and ATTR1_AFF_ID_MASK) shr ATTR1_AFF_ID_SHIFT).int
func size*(obj: ObjAttr): ObjSize = (((obj.attr0 and ATTR0_SHAPE_MASK) shr 12) or (obj.attr1 shr 14)).ObjSize
func hflip*(obj: ObjAttr): bool = (obj.attr1 and ATTR1_HFLIP) != 0
func vflip*(obj: ObjAttr): bool = (obj.attr1 and ATTR1_VFLIP) != 0
func tid*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_ID_MASK) shr ATTR2_ID_SHIFT).int
func pal*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_PALBANK_MASK) shr ATTR2_PALBANK_SHIFT).int
func prio*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_PRIO_MASK) shr ATTR2_PRIO_SHIFT).int

# ptr setters

func `x=`*(obj: ObjAttrPtr, x: int) =
  obj.attr1 = (x.uint16 and ATTR1_X_MASK) or (obj.attr1 and not ATTR1_X_MASK)

func `y=`*(obj: ObjAttrPtr, y: int) =
  obj.attr0 = (y.uint16 and ATTR0_Y_MASK) or (obj.attr0 and not ATTR0_Y_MASK)

func `pos=`*(obj: ObjAttrPtr, v: Vec2i) =
  obj.x = v.x
  obj.y = v.y

func `tid=`*(obj: ObjAttrPtr, tid: int) =
  obj.attr2 = ((tid.uint16 shl ATTR2_ID_SHIFT) and ATTR2_ID_MASK) or (obj.attr2 and not ATTR2_ID_MASK)

func `pal=`*(obj: ObjAttrPtr, pal: int) =
  obj.attr2 = ((pal.uint16 shl ATTR2_PALBANK_SHIFT) and ATTR2_PALBANK_MASK) or (obj.attr2 and not ATTR2_PALBANK_MASK)

func `hflip=`*(obj: ObjAttrPtr, v: bool) =
  obj.attr1 = (v.uint16 shl 12) or (obj.attr1 and not ATTR1_HFLIP)
  
func `vflip=`*(obj: ObjAttrPtr, v: bool) =
  obj.attr1 = (v.uint16 shl 13) or (obj.attr1 and not ATTR1_VFLIP)

func `mode=`*(obj: ObjAttrPtr, v: ObjMode) =
  obj.attr0 = (v.uint16) or (obj.attr0 and not ATTR0_MODE_MASK)

func `fx=`*(obj: ObjAttrPtr, v: ObjFxMode) =
  obj.attr0 = (v.uint16) or (obj.attr0 and not (ATTR0_BLEND or ATTR0_WINDOW))

func `mos=`*(obj: ObjAttrPtr, v: bool) =
  obj.attr0 = (v.uint16 shl 12) or (obj.attr0 and not ATTR0_MOSAIC)

func `is8bpp=`*(obj: ObjAttrPtr, v: bool) =
  obj.attr0 = (v.uint16 shl 13) or (obj.attr0 and not ATTR0_8BPP)

func `aff=`*(obj: ObjAttrPtr, aff: int) =
  obj.attr1 = ((aff.uint16 shl ATTR1_AFF_ID_SHIFT) and ATTR1_AFF_ID_MASK) or (obj.attr1 and not ATTR1_AFF_ID_MASK)

func `size=`*(obj: ObjAttrPtr, v: ObjSize) =
  let shape = (v.uint16 shl 12) and ATTR0_SHAPE_MASK
  let size = (v.uint16 shl 14)
  obj.attr0 = shape or (obj.attr0 and not ATTR0_SHAPE_MASK)
  obj.attr1 = size or (obj.attr1 and not ATTR1_SIZE_MASK)
  
func `prio=`*(obj: ObjAttrPtr, prio: int) =
  obj.attr2 = ((prio.uint16 shl ATTR2_PRIO_SHIFT) and ATTR2_PRIO_MASK) or (obj.attr2 and not ATTR2_PRIO_MASK)


# var setters

func `x=`*(obj: var ObjAttr, x: int) = (addr obj).x = x
func `y=`*(obj: var ObjAttr, y: int) = (addr obj).y = y
func `pos=`*(obj: var ObjAttr, pos: Vec2i) = (addr obj).pos = pos
func `tid=`*(obj: var ObjAttr, tid: int) = (addr obj).tid = tid
func `pal=`*(obj: var ObjAttr, pal: int) = (addr obj).pal = pal
func `hflip=`*(obj: var ObjAttr, hflip: bool) = (addr obj).hflip = hflip
func `vflip=`*(obj: var ObjAttr, vflip: bool) = (addr obj).vflip = vflip
func `mode=`*(obj: var ObjAttr, mode: ObjMode) = (addr obj).mode = mode
func `fx=`*(obj: var ObjAttr, fx: ObjFxMode) = (addr obj).fx = fx
func `mos=`*(obj: var ObjAttr, mos: bool) = (addr obj).mos = mos
func `is8bpp=`*(obj: var ObjAttr, is8bpp: bool) = (addr obj).is8bpp = is8bpp
func `size=`*(obj: var ObjAttr, size: ObjSize) = (addr obj).size = size
func `aff=`*(obj: var ObjAttr, aff: int) = (addr obj).aff = aff
func `prio=`*(obj: var ObjAttr, prio: int) = (addr obj).prio = prio

template initObj*(args: varargs[untyped]): ObjAttr =
  var obj: ObjAttr
  writeFields(obj, args)
  obj

template init*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Initialise an object.
  ## 
  ## Omitted fields will default to zero.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   objMem[0].init:
  ##     pos = vec2i(100, 100)
  ##     size = s32x32
  ##     tid = 0
  ##     pal = 3
  obj.setAttr(0, 0, 0)
  writeFields(obj, args)

template edit*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Update some fields of an object.
  ## 
  ## Like `obj.init`, but omitted fields will be left unchanged.
  ## 
  writeFields(obj, args)


template dup*(obj: ObjAttr, args: varargs[untyped]): ObjAttr =
  var tmp = obj
  writeFields(tmp, args)
  tmp


# Size helpers:

func getSize*(size: ObjSize): tuple[w, h: int] =
  ## Get the width and height in pixels of an `ObjSize` enum value.
  {.noSideEffect.}:
    let sizes = cast[ptr array[ObjSize, array[2, uint8]]](unsafeAddr oamSizes)
    let arr = sizes[size]
    (arr[0].int, arr[1].int)
  
func getWidth*(size: ObjSize): int =
  ## Get the width in pixels of an `ObjSize` enum value.
  {.noSideEffect.}:
    let sizes = cast[ptr array[ObjSize, array[2, uint8]]](unsafeAddr oamSizes)
    sizes[size][0].int

func getHeight*(size: ObjSize): int =
  ## Get the height in pixels of an `ObjSize` enum value.
  {.noSideEffect.}:
    let sizes = cast[ptr array[ObjSize, array[2, uint8]]](unsafeAddr oamSizes)
    sizes[size][1].int

func getSize*(obj: ObjAttr | ObjAttrPtr): tuple[w, h: int] =
  ## Get the width and height of an object in pixels.
  getSize(obj.size)
  
func getWidth*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the width of an object in pixels.
  getWidth(obj.size)
  
func getHeight*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the height of an object in pixels.
  getHeight(obj.size)


func hide*(obj: var ObjAttr) =
  ## Hide an object.
  ## 
  ## Equivalent to ``obj.mode = omHide``
  ## 
  obj.mode = omHide

func unhide*(obj: var ObjAttr; mode = omReg) =
  ## Unhide an object.
  ## 
  ## Equivalent to ``obj.mode = mode``
  ## 
  ## **Parameters:**
  ## 
  ## obj
  ##   Object to unhide.
  ## 
  ## mode
  ##   Object mode to unhide to. Necessary because this affects the affine-ness of the object.
  ## 
  obj.mode = mode

{.pop.}
