SBS scripts for OBS
===================

Lua scripts to play with SBS format in OBS (Open Broadcaster Software)

Assuming your OBS was compiled with script support, the scripts can be added with `Tools` > `Scripts` menu entry.

- `obs_filter_sbs2a.lua`: adds an effect filter that can be applied to convert from side-by-side to anaglyph presentation formats.
- `obs_filter_sbsadjust.lua`: adds an effect filter that can be applied to make some adjustments on a side-by-side image, like changing the window placement, fixing vertical mislignment and cropping.

Then choose the source you want to apply the effect to, open the effects window, add the effect to the source, choose the values of its settings, and voilà.

Tip: You can apply the effect to a group or the scene itself, to compose your scene with depth.
