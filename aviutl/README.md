# Uta AviUtl Scripts
yay they're here now.

# Installation
hey hi uhh... just rename the whole folder to Uta and put it in `your AviUtl folder/Script`
basically

```
AviUtl
|   <aviutl-files>
|   aviutl.exe
|   </aviutl-files>
+---<aviutl-folders>
+---Script
|   +---<script-folders>
|   +---Uta
|   |       @3D Projections.anm
|   |       ...
|   |       vector.lua
|   \---</script-folders>
\---</aviutl-folders>
```

## @Uta's Test Pixel Sort
so you just download [this](https://github.com/MaverickTse/PixelSorter_s/releases/tag/1.6EN) and put the dll in the script folder. or look at this video for guidance.

https://user-images.githubusercontent.com/29729824/228882722-df2b8350-d91d-4d10-b644-58fb2a37b847.mp4


## @3D Shapies
okay so there's the Points and Faces argument right... just put Points and Faces after what i'm gonna list.
also example here ig basically for Points u put `tetrahedronPoints` and for Faces u put `tetrahedronFaces`

just look the names up they're funky shapes.

| | | | |
|:---:|:---:|:---:|:---:|
|`tetrahedron`|`cube`|`octahedron`|`dodecahedron`|
|`icosahedron`|`truncatedTetrahedron`|`cuboctahedron`|`truncatedOctahedron`|
|`rhombicuboctahedron`|`icosidodecahedron`|\*`snubCube`|`truncatedIcosahedron`|
|`rhombicosidodecahedron`|`triakisTetrahedron`|`triakisOctahedron`|`tetrakisHexahedron`|
|`rhombicDodecahedron`|`rhombicTriacontahedron`|`deltoidalIcositetrahedron`|`pentagonalIcositetrahedron`|

\*`snubCube` has `snubCubePoints2` for the reflected version. it still uses `snubCubeFaces`
