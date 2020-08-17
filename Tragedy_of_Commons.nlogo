; Tragedy of the Commons
; Joseph Bernardi, JD Gayer, Alexander Hura, Matthieu Collin
; ECON-450
;ai: Thank you for adding tests.

; source for original model: https://www.openabm.org/model/3051/version/1/view
; author: J. Schindler
; code modifications by Alan G. Isaac (mostly just for NetLogo 6 compatability)
; Supporting article: http://jasss.soc.surrey.ac.uk/15/1/4.html

; Source of study regarding the correlation between perceived scarcity and panic shopping (with toilet paper used as an example good) -JB
; Authors: Lisa Garbe, Richard Rau, Theo Toppe -JB
; Article Link: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0234232 -JB

globals [
  Veg                    ;(int): number of patches with supplies on them
  K                      ;ai: sum ki (was total of herd sizes, but now is total of consumers)
  supplies-initial-consumers     ;(int): numbr of patches with supplies on them before consumers eat
  supplies-after-consumers       ;(int): number of patches with supplies on them after consumers eat
  cost-of-action         ;(real): cost to household of owning a consumer based on the cost of the consumer, how much consumers eat, & consumer forage requirement
  reward-list            ;
  cover                  ;(float): proportion (%) of pasture covered with supplies
]

;jd: slider globals:

;food-resupply-rate: regrowth rate of supplies
;consumer-minimum-food-needed: annual forage requirement of consumers on patches
;initial-supply-of-food: percent of world covered in supplies at startup
;cost-of-living-per-person: price per consumer
;total-consumers: total number of consumers at startup
;total-households: total number of households at startup
;learning-factor: how fast households react to a change in the world

;selfishness:          how much a household values acting in a way that benefits themselves
;cooperativeness:      how much a household values acting in a way that benefits the group as a whole
;fairness-to-myself:   how much a household values being fair to themselves
;fairness-to-others:   how much a household values being fair to other households
;positive-reciprocity: to what degree a households will react with positivity to other households acting positively
;negative-reciprocity: to what degree a households will react with negativity to other households acting negatively
;conformity:           to what degree does a household value doing what the group has done in the past
;risk-aversion:        to what degree does a household prefer to take actions that reduce financial risk

;JB: perceived-scarcity: what consumers imagine scarcity will be like in the future term
;JB: unstandardized-beta-of-PS: for every increase in perceived scarcity, proportionally what impact will be had on shopping behavior?

;jd: maxcapacity: maximum number of consumers in the world (to simulate maximum capacity rules at stores during the pandemic)
;jd: updated interface to include plot of number of consumers
;ai: good idea; & also you can use this value for your experiments

turtles-own [
  forage              ;(int): number of patches of supplies foraged
  owner               ;(household): which household owns that consumer
  xi                  ;(int): individual choices made by households, based on time steps
  ki                  ;(int): consumers owned by herder i
  C                   ;(int): initial number of consumers
  reward              ;(real): aggregate reward based on value of socio-psychological slider globals & their associated rewards
  Prob-add            ;(real): probability of a household adding a consumer
  Prob-subtract       ;(real): probability of a household subtracting a consumer
  fin-reward-coop    ;(real): reward to household for cooperating
  fin-reward-single  ;(real): reward to household for acting selfishly
  reward-single      ;(-1 or 1): reward or punishment for acting selfishly (based on sign of fin-reward-single)
  reward-coop        ;(-1 or 1): reward or punishment for cooperating (based on sign of fin-reward-coop)
  reward-fairme      ;(-1 or 1): reward or punishment for distributing agents in a way that is fair to oneself
  reward-fairother   ;(-1 or 1): reward or punishment for distributing agents in a way that is fair to other households
  reward-posrec      ;(-1 or 1); reward or punishment for acting with positive reciprocity
                     ;positive reciprocity: when one agent acts in a way that is positive for another agent, that second agent
                     ;acts in a way that is positive for the first agent in return.
  reward-negrec      ;(-1 or 1); reward or punishment for acting with negative reciprocity
                     ;negative reciprocity: when one agent acts in a way that is negative for another agent, that second agent
                     ;acts in a way that is negative for the first agent in return.
  reward-conf        ;(-1 or 1): reward for acting according to past behaviors of the group of households; punishment for acting otherwise
  reward-risk        ;(-1 or 1): reward for taking actions that reduce financial risk; punishment for acting otherwise
  id
]
breed [ consumers consumer ]
breed [ households household ]

; added startup procedure -JB
;ai: thank you; this is important
to startup
  set selfishness 1
  set cooperativeness 0
  set fairness-to-myself 0
  set fairness-to-others 0
  set positive-reciprocity 0
  set negative-reciprocity 0
  set conformity 0
  set risk-aversion 0
  set food-resupply-rate 0.008; set additional startup values -JB
  set consumer-minimum-food-needed 1
  set initial-supply-of-food 94
  set cost-of-living-per-person 98
  set total-consumers 314
  set total-households 6
  set learning-factor 0.74
  set maxCapacity 900
  set unstandardized-beta-of-PS 0.76 ; was found by the Garbe, Rau, and Toppe study (cited above) that perceived scarcity held an unstandardized beta of around 0.76 when observing changes in consumer behavior -JB
  set perceived-scarcity 0
end

to setup
  ca
  ask n-of round (initial-supply-of-food / 100 * count patches) patches [ set pcolor green ]
  create-households total-households [ move-to one-of patches set color white set size 2 set shape "house" ] ; Made visual changes: households and people instead of household and consumers
  create-consumers total-consumers [ move-to one-of patches set color white set size 2 set shape "person" ]
  while [ any? consumers with [ owner = 0 ] ] [
    ask one-of consumers with [ owner = 0 ] [ set owner one-of households ]
  ]
  ask households [
    set ki count consumers with [ owner = myself ]
    set xi one-of (list -1 1)
    set Prob-add 0.5 set Prob-subtract 0.5
  ]
  update-stock
  reset-ticks
end

;ai: did you want this to become shelf-restocking?
to supplies-regrowth ;ai: patch state is binary; growth determines the number that turn
  set Veg count patches with [ pcolor = green ]
  let _maxVeg count patches  ;ai: changed to local
  ;ai: note that the following can be simplified
  ask n-of min (list round (Veg * (1 + (food-resupply-rate * Veg * (1 - (Veg / _maxVeg)))) - Veg)
  count patches with [ pcolor = black ])
  patches with [ pcolor = black ] [ set pcolor green ]
end

;ai: did you want this to become "to purchase"?
;JB: my apologies professor, this was left as graze by accident
to consume
  ask consumers [ set forage 0 ]
  ask consumers [
    while [(forage < consumer-minimum-food-needed)
           and (any? patches with [ pcolor = green ])] [
      move-to min-one-of patches with [ pcolor = green ] [ distance myself ]
      ask patch-here [ set pcolor black ]
      set forage (forage + 1)
    ]
  ]
  ask consumers [ if (forage < consumer-minimum-food-needed) [ die ] ]
  ask households [ set ki count consumers with [ owner = myself ] ]
  set K sum [ ki ] of households
end

to go
  ;if ticks = 300 [ stop ]
  let _suppliesleft (count patches with [ pcolor = green ]) ; Updated Stop routine - JB
  if ((0 = _suppliesleft) or (3000 = ticks)) [ stop ]
  consume
  plot-data
  supplies-regrowth
  update-stock
  tick
end

to export-data
  file-open "out/%_of_food_leftover.txt"
  file-print count patches with [ pcolor = green ] / count patches * 100
  file-close
end

to plot-data
  set-current-plot "Amount of Food"
  set cover count patches with [ pcolor = green ] / count patches * 100
  plot count patches with [ pcolor = green ] / count patches * 100
  ;ai: turn off the next line since user may not want files written
  ;file-open "out/payoff-sum-random.txt" file-write count consumers file-close
end

to update-stock
  ask households [
    set fin-reward-single (xi * cost-of-living-per-person - cost (K + sum [ xi ] of other households) (K + sum [ xi ] of households))
  ]
  ask households [
    if (fin-reward-single > 0) [ set reward-single 1 ]
    if (fin-reward-single < 0) [ set reward-single -1 ]
  ]

  ask households [
    set fin-reward-coop (sum [ xi ] of households * cost-of-living-per-person / count households - cost (K) (K + sum [ xi ] of households))
  ]

  ask households [
    if (fin-reward-coop > 0) [ set reward-coop 1 ]
    if (fin-reward-coop < 0) [ set reward-coop -1 ]
  ]

  ask households [
    set reward-fairme 0
    set reward-fairother 0
    if ((sum [ ki ] of other households / (count households - 1)) > ki and xi = -1) [ set reward-fairme -1 ]
    if ((sum [ ki ] of other households / (count households - 1)) > ki and xi = 1) [ set reward-fairme 1 ]
    if ((sum [ ki ] of other households / (count households - 1)) < ki and xi = -1) [ set reward-fairother 1 ]
    if ((sum [ ki ] of other households / (count households - 1)) < ki and xi = 1) [ set reward-fairother -1 ]
  ]

  ask households [
    set reward-posrec 0
    set reward-negrec 0
    if (mean [ xi ] of other households < 0 and xi = -1) [ set reward-posrec 1 ]
    if (mean [ xi ] of other households > 0 and xi = 1) [ set reward-negrec 1 ]
    if (mean [ xi ] of other households < 0 and xi = 1) [ set reward-posrec -1 ]
    if (mean [ xi ] of other households > 0 and xi = -1) [ set reward-negrec -1 ]
  ]

  ask households [
    if (mean [ xi ] of other households < 0 and xi = -1) [ set reward-conf 1 ]
    if (mean [ xi ] of other households > 0 and xi = 1) [ set reward-conf 1 ]
    if (mean [ xi ] of other households < 0 and xi = 1) [ set reward-conf -1 ]
    if (mean [ xi ] of other households > 0 and xi = -1) [ set reward-conf -1 ]
  ]

  ask households [
    set reward-risk 0
    if (cost (K) (K + count households) > cost-of-living-per-person and xi = -1) [ set reward-risk 1 ]
    if (cost (K) (K + count households) > cost-of-living-per-person and xi = 1) [ set reward-risk -1 ]
  ]

  ask households [
    set reward selfishness * reward-single + cooperativeness * reward-coop
      + fairness-to-myself * reward-fairme + fairness-to-others * reward-fairother
      + positive-reciprocity * reward-posrec + negative-reciprocity * reward-negrec
      + conformity * reward-conf + risk-aversion * reward-risk + ((1 + unstandardized-beta-of-PS) * perceived-scarcity)
  ]; added perceived scarcity alongside the unstandardized statistical beta, meaning for every additional unit of perceived scarcity, how much proportionally more does that affect shopping behavior -JB
  ; more information on study used can be found above under the startup function -JB


  ask households [
    if (reward > 0 and xi = 1) [ set Prob-add Prob-add + (1 - Prob-add) * learning-factor set Prob-subtract 1 - Prob-add ]
    if (reward < 0 and xi = 1) [ set Prob-add Prob-add * (1 - learning-factor) set Prob-subtract 1 - Prob-add ]
    if (reward > 0 and xi = -1) [ set Prob-subtract Prob-subtract + (1 - Prob-subtract) * learning-factor set Prob-add 1 - Prob-subtract ]
    if (reward < 0 and xi = -1) [ set Prob-subtract Prob-subtract * (1 - learning-factor) set Prob-add 1 - Prob-subtract ]
  ]

  ask households [ ifelse random-float 1.0 < Prob-add [ set xi 1 ] [ set xi -1 ] ]
  ask households [
    ifelse (xi = 1) [
      if k < maxcapacity [                  ;jd: stopping condition for creation of consumers when capacity has been reached
      hatch-consumers 1 [ set owner myself ]
    ] ] [
      if (any? consumers with [ owner = myself ]) [ ask one-of consumers with [ owner = myself ] [ die ] ]
    ]
  ]

  ask consumers [
    move-to one-of patches
    set color brown
    set size 2
    set shape "person"
  ]
  ask households [ ;set household size
    set ki count consumers with [ owner = myself ]
  ]
end

to-report cost [ initial-consumers after-consumers ]
  let Veg1 count patches with [ pcolor = green ] - initial-consumers * consumer-minimum-food-needed
  let Veg2 count patches with [ pcolor = green ] - after-consumers * consumer-minimum-food-needed
  let _maxVeg count patches  ;ai: changed to local
  set supplies-initial-consumers (max list 0 Veg1) * (1 + (food-resupply-rate * Veg1 * (1 - (Veg1 / _maxVeg))))
  set supplies-after-consumers (max list 0 Veg2) * (1 + (food-resupply-rate * Veg2 * (1 - (Veg2 / _maxVeg))))
  set cost-of-action (supplies-initial-consumers - supplies-after-consumers) / (consumer-minimum-food-needed * count households) * cost-of-living-per-person
  report cost-of-action
end

to reset-settings ;(to Hardin's scenario)
  set selfishness 1
  set cooperativeness 0
  set fairness-to-myself 0
  set fairness-to-others 0
  set positive-reciprocity 0
  set negative-reciprocity 0
  set conformity 0
  set risk-aversion 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TEST PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to test-cost ;jd: procedure to test if cost counts patches correctly & evaluates functions correctly
             ;by setting a known value (count patches with [pcolor = green]) to zero. if the cost
             ;function for any two numbers [ initial-consumers after-consumers] does not evaluate to
             ;zero under the condition of 0 green patches, cost is not working.
  type "begin test-cost..."
  ask patches [ set pcolor black ]                                 ;set patches with [pcolor = green] to 0; then
  let _x1 random-float 10                                          ;assign random values between 0 and 1o to the parameters
  let _x2 random-float 10                                          ;used in the cost reporter procedure; then
  if not ( cost _x1 _x2 = 0 ) [error "issue with cost"]            ;if cost != 0 something has gone wrong
  print "cost is ok"                                               ;if cost = 0 all is good.
end

to test-consume ; Function that tests the consume function by determining if set values, which were assigned in the consume function, are correct -JB
  print "Starting test of the consume function..."
  let incorrectcounter 0
  if (K != sum [ ki ] of households) [set incorrectcounter incorrectcounter + 1]
  ask consumers [if (forage < consumer-minimum-food-needed) [set incorrectcounter incorrectcounter + 1]]
  ask households [if (ki != count consumers with [ owner = myself ]) [set incorrectcounter incorrectcounter + 1]]
  if (incorrectcounter > 0) [print (word "consume function is incorrect, and returned " incorrectcounter " errors.")]
  if (incorrectcounter = 0) [print "consume function is working properly!"]
end
to testSetup; meant to test each component of the setup procedure. Still working on a ticks measure and a way
  ; to get households to work. Ah
  setup
  type "Begin test of `setup` ... "
  if (consumers = 0) [ error "false" ]
  if (consumers != 0) [ print "consumers fine"]
End

to test-export-data ; procedure to test if the exportdata function properly prints the output data into the correct file. MC
  type "Begin test of export-data..."
  file-open "out/%_of_food_leftoverTEST.txt"
  file-print count patches with [pcolor = green] / count patches * 100
  file-close
  file-open "out/%_of_food_leftoverTEST.txt"
  let _edtest01 file-read
  file-close
  let _edtest02 (count patches with [pcolor = green] / count patches * 100)
  if (_edtest01 = _edtest02) [print "export-data OK"]
  if not (_edtest01 = _edtest02) [ print "issue with export-data"]
  carefully [file-delete "out/%_of_food_leftoverTEST.txt"] []
end
@#$#@#$#@
GRAPHICS-WINDOW
243
15
614
387
-1
-1
11.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
10
36
226
69
food-resupply-rate
food-resupply-rate
0
0.01
0.008
0.001
1
NIL
HORIZONTAL

SLIDER
11
96
234
129
consumer-minimum-food-needed
consumer-minimum-food-needed
1
5
1.0
.1
1
NIL
HORIZONTAL

SLIDER
12
147
222
180
initial-supply-of-food
initial-supply-of-food
0
100
94.0
1
1
%
HORIZONTAL

SLIDER
13
325
219
358
total-consumers
total-consumers
0
1000
314.0
1
1
NIL
HORIZONTAL

SLIDER
15
268
220
301
cost-of-living-per-person
cost-of-living-per-person
1
200
98.0
1
1
$
HORIZONTAL

SLIDER
639
151
811
184
cooperativeness
cooperativeness
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
13
425
217
458
learning-factor
learning-factor
0
1
0.74
0.01
1
NIL
HORIZONTAL

SLIDER
639
114
811
147
selfishness
selfishness
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
639
188
811
221
fairness-to-myself
fairness-to-myself
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
640
225
812
258
fairness-to-others
fairness-to-others
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
640
262
813
295
positive-reciprocity
positive-reciprocity
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
641
298
814
331
negative-reciprocity
negative-reciprocity
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
641
335
814
368
conformity
conformity
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
641
372
815
405
risk-aversion
risk-aversion
0
1
0.0
0.01
1
NIL
HORIZONTAL

BUTTON
120
200
186
233
NIL
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
41
200
104
233
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
635
60
808
93
NIL
reset-settings
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
10
10
196
38
Grass growth rate near zero:
11
0.0
1

TEXTBOX
13
76
241
104
Patches browsed per consumer per time step:
11
0.0
1

TEXTBOX
14
131
164
149
Initial food supply
11
0.0
1

TEXTBOX
15
251
165
269
NIL
11
0.0
1

TEXTBOX
16
408
166
426
Adaptation speed:
11
0.0
1

TEXTBOX
633
14
873
42
Socio-psychological dispositions (default settings correspond to Hardin's scenario):
11
0.0
1

PLOT
827
60
1096
250
Amount of Food
NIL
NIL
0.0
10.0
50.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
828
267
1000
300
maxCapacity
maxCapacity
0
1000
900.0
10
1
NIL
HORIZONTAL

PLOT
829
315
1029
465
Number of People
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count consumers"

SLIDER
15
371
221
404
total-households
total-households
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
225
448
475
481
perceived-scarcity
perceived-scarcity
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
495
448
750
481
unstandardized-beta-of-PS
unstandardized-beta-of-PS
-1
1
0.76
0.01
1
NIL
HORIZONTAL

TEXTBOX
236
415
457
457
What the consumer perceives scarcity will be in the future term. -JB
11
0.0
1

TEXTBOX
470
406
826
451
The correlation between perceived scarcity and panic buying. Ex, for every unit increase of perceived scarcity, what will be proportional impact of consumer behavior?
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count consumers</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cow-price">
      <value value="76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JD Gayer experiment 1" repetitions="5" runMetricsEveryStep="false">
    <setup>random-seed 10
setup
reset-ticks</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <exitCondition>not any? patches with [ pcolor = green ]</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.002"/>
      <value value="0.004"/>
      <value value="0.006"/>
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JD Gayer experiment 2" repetitions="5" runMetricsEveryStep="false">
    <setup>random-seed 10
setup
reset-ticks</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <exitCondition>not any? patches with [pcolor = green]</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perceived-scarcity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unstandardized-beta-of-PS">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="0"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JB01" repetitions="10" runMetricsEveryStep="true">
    <setup>random-seed behaviorspace-run-number
reset-ticks
setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perceived-scarcity">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unstandardized-beta-of-PS">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MC01" repetitions="10" runMetricsEveryStep="false">
    <setup>random-seed 10
setup
reset-ticks</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <exitCondition>not any? patches with [ pcolor = green ]</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="50"/>
      <value value="150"/>
      <value value="314"/>
      <value value="500"/>
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.006"/>
      <value value="0.008"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perceived-scarcity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unstandardized-beta-of-PS">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Hardin Baseline - AH" repetitions="10" runMetricsEveryStep="false">
    <setup>random seed 10
reset-ticks
startup
setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>ticks</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perceived-scarcity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unstandardized-beta-of-PS">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Neg recip experiment - AH" repetitions="10" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count consumers</metric>
    <metric>count patches with [pcolor = green]</metric>
    <enumeratedValueSet variable="maxCapacity">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-others">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-aversion">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-living-per-person">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-consumers">
      <value value="314"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-resupply-rate">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perceived-scarcity">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="negative-reciprocity" first="0.5" step="0.1" last="1"/>
    <enumeratedValueSet variable="unstandardized-beta-of-PS">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-supply-of-food">
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cooperativeness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumer-minimum-food-needed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conformity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfishness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fairness-to-myself">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-households">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-reciprocity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-factor">
      <value value="0.74"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
