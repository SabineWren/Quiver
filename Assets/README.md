Textures must be `.tga`:
- Origin top left
- No RLE compression
- Use powers of 2 for both X and Y dimensions (prefer 32x32 for icons)
- Never smaller than 16x16

Can convert SVGs to tga using GIMP:
1. Open as arbitrarily large (ex. 512x512). Larger means less feathering for bucket fill.
2. White means opaque and black transparent. Most icon libraries use black, so bucket fill to white.
3. Crop as needed
4. Rescale to 32x32
5. Export as `.tga`
