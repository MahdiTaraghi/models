extensions [palette]

patches-own
[
  old-temperature  ;; the temperature of the patch the last time thru go
  temperature  ;; the current temperature of the patch
]

globals
[
  plate-size  ;; the size of the plate on which heat is diffusing
  ;; Used for scaling the color of the patches
  min-temp  ;; the minimum temperature at setup time
  max-temp  ;; the maximum temperature at setup time
  hsb-colors ;; the colors to use with the hsb pallette
]


;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  ;; initialize variables
  set plate-size round (0.6 * max-pxcor)  ;; use 0.6 to make a nice sized plate
  set hsb-colors [[238 98 36] [193 70 53] [181 100 100] [121 100 100] [103 250 100]
    [95 100 100] [75 100 100] [59 100 100] [26 100 100] [2 100 100] [0 100 100]]
  ;; set up the plate
  ask patches
  [
    set pcolor gray
    set-initial-temperatures
    set-edge-temperatures
    set old-temperature temperature
  ]
  set min-temp min [old-temperature] of patches
  set max-temp max [old-temperature] of patches
  draw-legend
  ask patches [ draw-plate ]
  reset-ticks
end

;; Sets the temperature for inside of the plate
to set-initial-temperatures  ;; Patch Procedure
  if ((abs pycor) < plate-size) and ((abs pxcor) < plate-size)
  [set temperature initial-plate-temp]
end

;; Draws the Color Scale Legend
to draw-legend
  let x (1 + min-pxcor)
  repeat 3
  [
    let y 0
    repeat 10
    [
      ask patch (x + 4) (y * 2 - 11) [ set temperature (y * 10) ]
      ask patch (x + 4) (y * 2 - 10) [ set temperature (y * 10) ]
      set y y + 1
    ]
    set x x + 1
  ]

  set x (1 + min-pxcor)
  repeat 3
  [
    let y 0
    repeat 10
    [
      ask patch (x + 4) (y * 2 - 11) [color-patch ]
      ask patch (x + 4) (y * 2 - 10) [color-patch ]
      set y y + 1
    ]
    set x x + 1
  ]

  set x (1 + min-pxcor)
  repeat 3
  [
    let y 0
    repeat 11
    [
      if (x = (3 + min-pxcor)) [ ask patch  x (y * 2 - 12) [ set plabel (y * 10) ] ]
    set y y + 1
    ]
    set x x + 1
  ]
end

;; Sets the temperatures of the plate edges and corners
to set-edge-temperatures  ;; patch procedure
  ;; set the temperatures of the edges
  if (pxcor >= plate-size) and ((abs pycor) < plate-size)
  [set temperature right-temp]
  if (pxcor <= (- plate-size)) and ((abs pycor) < plate-size)
  [set temperature left-temp]
  if (pycor >= plate-size) and ((abs pxcor) < plate-size)
  [set temperature top-temp]
  if (pycor <= (- plate-size)) and ((abs pxcor) < plate-size )
  [set temperature bottom-temp]

  ;; set the temperatures of the corners
  if (pxcor >= plate-size) and (pycor >= plate-size)
  [set temperature 0.5 * (right-temp + top-temp)]
  if (pxcor >= plate-size) and (pycor <= (- plate-size))
  [set temperature 0.5 * (right-temp + bottom-temp)]
  if (pxcor <= (- plate-size)) and (pycor >= plate-size)
  [set temperature 0.5 * (left-temp + top-temp)]
  if (pxcor <= (- plate-size)) and (pycor <= (- plate-size))
  [set temperature 0.5 * (left-temp + bottom-temp)]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Runtime Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Runs the simulation through a loop
to go
  ask patches
  [
    ;; diffuse the heat of a patch with its neighbors
    set temperature (heat-diffusivity * (sum [old-temperature] of neighbors4)) + ((1 - ( 4 * heat-diffusivity )) * old-temperature)
    ;; set the edges back to their constant heat
    set-edge-temperatures
    set old-temperature temperature
    draw-plate
  ]
  tick
end

;; Draws the patches that are within the plate
to draw-plate  ;; Patch Procedure
  if ((abs pycor) <= plate-size) and ((abs pxcor) <= plate-size)
  [color-patch]
end

;; color the patch based on its temperature
to color-patch  ;; Patch Procedure
  ;; color patches a shade of red, darker red is hotter
  if color-scheme = "red" [ set pcolor scale-color red temperature (max-temp + 9) (min-temp - 9) ]
  ;; color patches using a list of hsb colors
  if color-scheme = "hsb" [
    ;; calculate the index into the list of hsb colors
    let index (ceiling (10 * ((temperature - min-temp) / (1.1 * (max-temp - min-temp)))))
    let approximate-temp item index hsb-colors
    set pcolor hsb (first approximate-temp) (item 1 approximate-temp)(item 2 approximate-temp)
  ]
  ;; color patches using a gradient of rgb colors generated by the palette extension
  if color-scheme = "rgb" [
    ;; use palette extension to make a gradient of rgb colors
    set pcolor palette:scale-gradient [[0 0 255] [0 255 0] [255 255 0] [255 0 0]] temperature min-temp max-temp
  ]
  ;; color patches using a divergent color scheme generated by the palette extension
  if color-scheme = "divergent" [ set pcolor (palette:scale-scheme "Divergent" "Spectral" 9 temperature 100 0) ]
end

;; report the heat diffusivity constant that we use for the calculations
to-report heat-diffusivity
  ;; a few notes on the constants used here:
  ;; --we use .25 as a time step that causes the heat to diffuse at a reasonable pace
  ;; --we use alpha + .3 instead of just alpha here since alpha would be too
  ;; small to view any changes between some of the preset materials
  ;; --these constants are necessary since this model uses an Euler approximation to
  ;; calculate the temperature.  the approximation is only valid within a certain range
  ;; of time-steps and this range changes depending upon the value of alpha.
  report .25 * e ^ (-1 / (alpha + .3))
end

;; Sets the material
to update-alpha
  ifelse (material-type = "wood")
  [ set alpha 0.00128 ]
  [
    ifelse (material-type = "stone")
    [ set alpha 0.012 ]
    [
      ifelse (material-type = "iron")
      [ set alpha 0.2034 ]
      [
        ifelse (material-type = "aluminum")
        [ set alpha 0.8418 ]
        [
          ifelse (material-type = "silver")
          [ set alpha 1.7004 ]
          [ user-message "Choose your own value for alpha!" ]
        ]
      ]
    ]
  ]
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
290
120
555
406
25
25
5.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
5
90
140
123
alpha
alpha
0.0010
10.0
0.00128
1.0E-4
1
NIL
HORIZONTAL

SLIDER
345
80
500
113
top-temp
top-temp
1.0
100.0
65
1.0
1
NIL
HORIZONTAL

SLIDER
560
185
593
340
right-temp
right-temp
1.0
100.0
100
1.0
1
NIL
VERTICAL

SLIDER
345
410
505
443
bottom-temp
bottom-temp
1.0
100.0
15
1.0
1
NIL
HORIZONTAL

SLIDER
5
50
140
83
initial-plate-temp
initial-plate-temp
1.0
100.0
87
1.0
1
NIL
HORIZONTAL

BUTTON
230
10
295
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
250
190
283
345
left-temp
left-temp
1.0
100.0
1
1.0
1
NIL
VERTICAL

BUTTON
5
10
121
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
137
10
210
43
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
149
137
247
170
Update Alpha
update-alpha
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
5
130
140
175
material-type
material-type
"wood" "stone" "iron" "aluminum" "silver" "other"
0

CHOOSER
6
205
145
250
color-scheme
color-scheme
"red" "hsb" "rgb" "divergent"
3

TEXTBOX
151
62
337
136
Choose a material and then\npress UPDATE ALPHA based\non that material, or set ALPHA\ndirectly from the slider.
11
0.0
1

@#$#@#$#@
## ACKNOWLEDGMENT

This model is an alternate visualization of the Heat Diffusion model from the Chemistry & Physics section of the NetLogo Models Library. It uses visualization techniques as recommended in the paper:

* Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation (JASSS), 12(2), 1. http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.

## WHAT IS IT?

This model simulates transient and steady-state temperature distribution of a thin plate. This version of the model uses a more intuitive visualization of the gradient of heat than the original model.

The View shows a square thin plate as viewed from above.  The plate is thermally isolated on the two faces parallel to the view such that heat can flow only in and out from the perimeter of the plate and not into or out of the world.  Heat is kept constant at the edges.  As the simulation runs, heat is transmitted from warmer parts of the plate to cooler parts of the plate as shown by the varying color of the plate.  Therefore, the temperature of the plate begins to change immediately and possibly differently at different locations, gradually converging to a stable state.  Overall, the temperature distribution over the plate is a function of time and location.  In addition to this simple use of the model, you are encouraged to control various paramaters, such as the temperature of each edge edge of the plate and of the center of the plate before--and even while--the model is running.

Heat diffuses ("spreads") at different rates through different media.  These rates can be determined and are called the Thermal Diffusivity of the material.  The Greek letter alpha is often associated with this value.  The diffusivity of a material does not change based on how much of the material there is.  It is always the same.  Below is a table containing several different materials with different diffusivity rates.  See that wood (bottom row) has a lower heat diffusivity than, say, iron.  This means that it takes a longer for heat to spread through a wooden object than an iron one.  That is one reason why the handles of iron saucepans are wooden, and not the other way round.  Also, think of a marble table with iron legs that has just been put out in the sun in a street-side cafe.  Which material part of the table do you expect will warm up faster?  The model allows you to change thermal diffusivity of the plate in two ways.  You can directly change the value of ALPHA to any value you like, or you can indirectly change ALPHA by selecting a material.

### Thermal diffusivity of selected materials

<table border>
<tr><th>Material<th>Thermal diffusivity<br>(alpha cm*cm/s)
<tr><td>Wood (Maple)<td>0.00128
<tr><td>Stone (Marble)<td>0.0120
<tr><td>Iron<td>0.2034
<tr><td>Aluminum<td>0.8418
<tr><td>Silver<td>1.7004
</table>

## HOW IT WORKS

Initialize the plate and edges to have temperatures that equal their respective slider values.  Each time through the GO procedure, diffuse the heat on each patch in the following way.  Have each patch set its current temperature to the sum of the 4 neighbors' old temperature times a constant based on alpha plus a weighted version of the patch's old temperature.  (For those interested, the updated temperature is calculated by using a Forward Euler Method.)  Then the edges are set back to the specified values and the old temperature is updated to the current temperature.  Then the plate is redrawn.

## HOW TO USE IT

There are five temperature sliders which enable users to set four fixed edge temperatures and one initial plate temperature:
-- TOP-TEMP - Top edge temperature
-- BOTTOM-TEMP - Bottom edge temperature
-- INITIAL-PLATE-TEMP - Initial plate temperature
-- LEFT-TEMP - Left edge temperature
-- RIGHT-TEMP - Right edge temperature

There is a slider and a chooser that govern the thermal diffusivity of the plate. Selecting a material in the chooser, then pressing the UPDATE ALPHA button will set the value of ALPHA based on the material selected:
-- ALPHA - The alpha constant of thermal diffusivity
-- MATERIAL-TYPE - The value of the chooser is a material from the above chart.  You must press UPDATE ALPHA for this to change the value of ALPHA.


There are four buttons with the following functions:
-- SETUP - Initializes the model
-- GO - Runs the simulation indefinitely
-- GO ONCE - Runs the simulation for 1 time step
-- UPDATE ALPHA - press this if you want to set ALPHA to a preset value based on the material selected by the MATERIAL-TYPE chooser

VISUALIZATION
There is also a chooser, COLOR-SCHEME, which determines what scheme is used for coloring the plate. It has 4 values:
RED - colors the plate a shade of red based on its temperature, uses NetLogo's SCALE-COLOR primitive (white is coldest, black is hottest)
RGB - colors the plate from a spectrum of RGB colors based on its temperature, uses the Palette extension
HSB - colors the plate from a spectrum of HSB colors based on its temperature
DIVERGENT - colors the plate from a spectrum of colors from a divergent palette based on its temperature, uses the Palette extension

## THINGS TO NOTICE

How does the equilibrium temperature distribution vary for different edge temperature settings?

Notice how an equilibrium (the steady-state condition) is reached.

Keep track of the units:

<table border>
<tr><th>Variables<th>Units
<tr><td>time<td>0.1 second
<tr><td>temperature<td>degrees Celsius
<tr><td>length<td>centimeters
<tr><td>diffusivity<td>square centimeters per second
</table>

How do the different color schemes map to the gradient of heat?
The palette extension enables us to use divergent color schemes.

## THINGS TO TRY

Set the parameters on the temperature sliders.  Pick a value for ALPHA (or pick MATERIAL-TYPE and press UPDATE ALPHA).  After you have changed all the sliders to values you like, press SETUP followed by GO or GO ONCE.

Try different materials to observe the heat transfer speed.  How does this compare to physical experiments?

Try the following sample settings:
- Top:100, Bottom:0,   Left:0,   Right:0
- Top:0,   Bottom:100, Left:100, Right:100
- Top:0,   Bottom:66,  Left:99,  Right:33
- Top:25,  Bottom:25,  Left:100, Right:0

## EXTENDING THE MODEL

This model simulates a classic partial differential equation problem (that of heat diffusion). The thin square plate is a typical example, and the simplest model of the behavior.  Try changing the shape or thickness of the plate (e.g. a circular or elliptical plate), or adding a hole in the center (the plate would then be a slice of a torus, a doughnut-shaped geometric object).

Add a slider to alter this thickness.

Try modeling derivative or combined boundary conditions.

## NETLOGO  FEATURES

The bundled palette extension is used to create color schemes from the widely-used ColorBrewer standard ([http://colorbrewer2.org/](http://colorbrewer2.org/)). Here we use a divergent spectral color scheme.

## CREDITS AND REFERENCES

Thanks to Weiguo Yang for his work on this model.

The visualizations of the plate are described in:
Kornhauser, D.,  Wilensky, U. & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation, JASSS, 12(2), 1.
http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf .

The palette extension uses the ColorBrewer color schemes (Harrower & Brewer 2003). It enables  convenient selection and mapping of ColorBrewer Schemes in NetLogo.
The ColorBrewer webpage (http://colorbrewer2.org/) shows the different color schemes.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Heat Diffusion - Alternative Visualization model.  http://ccl.northwestern.edu/netlogo/models/HeatDiffusion-AlternativeVisualization.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 1998 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 6.0-M5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
