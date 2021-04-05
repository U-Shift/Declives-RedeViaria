Speed-Slope factor
================
Rosa Félix

## Cost for bicycle routing models

Bicycle routing models add to car routing modeling a greater complexity
that results essentially from the greater number of degrees of freedom
associated with cycling (i.e., a smaller, lighter and more versatile
vehicle in terms of maneuvering) and the fact that it is human powered
and therefore depending on a limited energy, thus depending on the
effort that is transmitted by the cyclist himself. This results in a
series of specific peculiarities in its riding, namely: a greater number
of variables relevant to the routing cost function, and the existence of
more subjective variables.

A complexity involved in modeling route choice for cyclists represents a
challenge. Even if we understand which variables are determinant for
route choice, models become more accurate if it incorporates the
versatility of the bicycle in urban context, and its ability to
circulate in non-road spaces.

GIS allows modeling a road network in the form of a topological graph,
to which a series of functions and algorithms, including the least cost
path ([Dijkstra 1959](#ref-dijkstra1959)). The application of the least
cost path algorithm assumes the existence of a graph formed by a set of
set of edges and nodes. The edges can be oriented or not and, to these,
a travel cost is associated, with one or more parameters, never less
than zero. Associating a travel cost to each arc in the network, the
route cost is defined as the sum of the costs of the arcs that compose
it.

### Speed

For a **constant** urban cycling speed travel (*factor = 1*), let’s say
15 km/h, we assume that the speed is linear to the edge extension, and
its cost is its travel time.

$$ c\_{speed} = \\frac{length\_{\[m\]}}{speed\_{\[m/s\]}} = time\_{\[s\]}\\tag1$$

Many factors may be determinant for **cycling speed**, such the surface
conditions, traffic, weather, mass, type of bicycle, directness,
confidence, etc ([Hochmair 2007](#ref-hochmair2007); [Félix
2012](#ref-Felix2012); [Broach, Dill, and Gliebe 2012](#ref-broach2012);
[Broach 2016](#ref-broach2016)). Here we will look only to **speed
related with gradient**, from the perspective of a common urban cyclist.

### Slope or gradient

When comes to cycling, the route gradient can be a determinant variable
to chose a route instead of an alternative. It is commonly known that
cyclists are averse to roads with an ascending gradient, and that
cyclists prefer roads with a descending gradient. The **direction** of
the gradient is determinant.

It is also known, by the gravity laws, that an object traveling at a
constant speed, its speed becomes faster when going down the hill, and
slower when going uphill. Buy how does it applies to a human behavior?
How does it varies when effort, fear, stamina, and reward plays a role?
When does a cyclist use the break levers? When does a cyclist slows her
pace?

The slope enters the cost function as a proxy for cyclist effort - the
amount of energy a cyclist must expend to travel on a street with a
given slope - causing the traversing time to increase for uphill routes.
On downhill routes, the effort is reduced and the theoretical speed is
increased, reducing their traversing time.

Also, the extension of the road segment enters in the cost function: for
longer segments at a given gradient, the effort of the cyclist is higher
than for a shorter segment with the same gradient.

Figure 1 shows the maximum lengths of uphill gradient acceptable to
cyclists ([Austroads 2009](#ref-austroads2009)). It considers that over
a 3% slope, the length should be taken into account.

![Fig. 1 - Desirable uphill gradients for ease of cycling (Austroads
2009)](SpeedSlopeFactor_files/austroads2009_gradient.PNG)

Sometimes it is more efficient to travel a longer distance with less
steep gradients rather than a shorter distance on a steep gradient.
Other times the extra distance to ride to overcome the gradient is not
so worthwhile and the cyclist chooses to ride up the steeper gradient by
hand. The maximum crossing cost penalty was considered to be 10 times
for this situation, i.e. for edges with a gradient greater than 20%.

Very steep roads are a problem not only for uphill riding, but also for
downhill riding, because a mechanical failure in the brakes can lead to
a dangerous situation for the rider, who also has to expend some effort
and skill to keep the bike balanced and control the additional risk.

[![World’s steepest street, with a 35% incline for over 161 meters.
Baldwin Street, Dunedin, New Zealand (Photo:
Wikipedia)](https://upload.wikimedia.org/wikipedia/commons/b/b8/DunedinBaldwinStreet_Parked_Car.jpg)](https://en.wikipedia.org/wiki/Baldwin_Street)

Downhill edges mostly result in benefit to the cyclist, increasing its
speed. However, this is not linear, decreasing from slope values above
13%, and may even slow down the speed (relative to the average flat
speed) it too steep.

## Speed Slope Factor

After an iterative process, which considered the cyclist effort as a
function of slope abacuses suggested by [CEAP - Centro de Estudos de
Arquitectura
Paisagista](#ref-ceap-centrodeestudosdearquitecturapaisagista)
([n.d.](#ref-ceap-centrodeestudosdearquitecturapaisagista)),
[AASHTO](#ref-aashto1999) ([1999](#ref-aashto1999)) and
[Austroads](#ref-austroads2009) ([2009](#ref-austroads2009)), p. 41 and
also a cost formula developed by [Price and Entrada/San Juan
Inc.](#ref-price2008) ([2008](#ref-price2008)), a function models the
slope factor based on the slope and length of each roadway segment.This
function, which is non-symmetric and non-monotonic, reproduces the
essential characteristics of the slope/effort relationship.

$$
{Eq. 2}\\tag2
$$

You can also embed plots, for example:

![](SpeedSlopeFactor_files/figure-gfm/pressure-1.png)<!-- -->

Note that the `echo = FALSE` parameter was added to the code chunk to
prevent printing of the R code that generated the plot.

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-aashto1999" class="csl-entry">

AASHTO. 1999. *Guide for the Development of Bicycle Facilities*.
Washington, DC: American Association of State Highway; Transportation
Officials. <http://safety.fhwa.dot.gov/ped_bike/docs/b_aashtobik.pdf>.

</div>

<div id="ref-austroads2009" class="csl-entry">

Austroads. 2009. “Part 6a: Pedestrian and Cyclist Paths.” In. Austroads.

</div>

<div id="ref-broach2016" class="csl-entry">

Broach, Joseph. 2016. “Travel Mode Choice Framework Incorporating
Realistic Bike and Walk Routes.” PhD thesis.

</div>

<div id="ref-broach2012" class="csl-entry">

Broach, Joseph, Jennifer Dill, and John Gliebe. 2012. “Where Do Cyclists
Ride? A Route Choice Model Developed with Revealed Preference GPS Data.”
*Transportation Research Part A: Policy and Practice* 46 (10): 1730–40.
<https://doi.org/10.1016/j.tra.2012.07.005>.

</div>

<div id="ref-ceap-centrodeestudosdearquitecturapaisagista"
class="csl-entry">

CEAP - Centro de Estudos de Arquitectura Paisagista. n.d. “Contributos
Para o Regulamento de Percursos Cicláveis Em Portugal.”

</div>

<div id="ref-dijkstra1959" class="csl-entry">

Dijkstra, E. W. 1959. “A Note on Two Problems in Connexion with Graphs.”
*Numerische Mathematik* 1 (1): 269–71.
<https://doi.org/10.1007/bf01386390>.

</div>

<div id="ref-Felix2012" class="csl-entry">

Félix, Rosa. 2012. “Gestão Da Mobilidade Em Bicicleta: Necessidades,
Factores de Preferência e Ferramentas de Suporte Ao Planeamento e Gestão
de Redes. O Caso de Lisboa.” Master’s thesis, Instituto Superior
Técnico; University of Lisbon.
<https://fenix.tecnico.ulisboa.pt/downloadFile/395144993029/GestaoMobilidadeBicicleta_RosaFelix_IST2012.pdf>.

</div>

<div id="ref-hochmair2007" class="csl-entry">

Hochmair, Hartwig. 2007. “Optimal Route Selection with Route Planners:
Results of a Desktop Usability Study.” In, 5–8. Seattle, Washington: ACM
GIS.

</div>

<div id="ref-price2008" class="csl-entry">

Price, Mike, and Entrada/San Juan Inc. 2008. “Slopes , Sharp Turns , and
Speed: Refining Emergency Response Networks to Accommodate Steep Slopes
and Turn Rules.” *Hands On - ArcUser Spring 2008* 11 (2): 50–57.

</div>

</div>
