//
//
//

// spice.init(stderr());
spice.init();

gnuwins (1);

// constants
usec = 1e-6;
nsec = 1e-9;
msec = 1e-3;
uF = 1e-6;
mohm = 1e-3;
Mohm = 1e6;

// DC sweep parameters
v0 = 1/128;
v1 = 4;
dv = v0;
V_range = [v0:v1:dv]';

ckt0 = <<>>;
ckt0.spice = [ ...
"XLAMP XP E/G - LED WITH FIXED VOLTAGE SUPPLY", ...
"* PARAMETERS", ...
".param rser=0.43895", ...
".param rpar=1e10", ...
".TEMP ${temp}", ...
"v1 1 0 0", ...
"d1 1 0  XPE", ...
"r1 1 0 'rpar'", ...
"* use cree model of their led", ...
".MODEL XPE D", ...
"+ RS=0.43895", ...
"+ IS=520.88E-12", ...
"+ N=5.7846", ...
"+ XTI=62.500", ...
"+ EG=2.5000", ...
".OPTIONS ABSTOL=1e-6 RELTOL=1e-3", ...
".dc v1 ${vstart} ${vend} ${vdelta}", ...
".end", ...
[]];

ckt0.xspice = [ ...
"XLAMP XP E/G - LED WITH FIXED VOLTAGE SUPPLY", ...
"* PARAMETERS", ...
"v1     1 0   0", ...
"vtja   2 0   ${temp}", ...
"a1     1 0 2 xpe", ...
".MODEL xpe cmdiode(RS=0.43895 IS=520.88E-12 N=5.7846 XTI=62.500 EG=2.5000 RP=1e10 TAMB=0)", ...
".OPTIONS ABSTOL=1e-6 RELTOL=1e-3", ...
".dc v1 ${vstart} ${vend} ${vdelta}", ...
".end", ...
[]];


TEMP = 50;
data = <<>>;
dt = <<>>;

for (i in range(V_range))
{
  spinner();

  V0 = V_range[i];
  V1 = V0;
  DV = dv;

  for (s in ["spice", "xspice"])
  {
    if (!exist(data.[s]))
    { data.[s] = []; }

    if (!exist(dt.[s]))
    { dt.[s] = 0; }

    ckt1 = ckt0.[s];

    // temp
    ckt1 = gsub(num2str(TEMP), "${temp}", ckt1).string;

    // v:
    // vstart
    ckt1 = gsub(num2str(V0), "${vstart}", ckt1).string;
    // vend
    ckt1 = gsub(num2str(V1), "${vend}", ckt1).string;
    // dv
    ckt1 = gsub(num2str(DV), "${vdelta}", ckt1).string;

    tic();
    spice.runckt(ckt1);
    while(spice.isrunning())
    { sleep(0.01); }
    dt.[s] = dt.[s] + toc();
    all_vals = spice.getvals();

    irs = -all_vals.data.i_v1;
    v1  =  all_vals.data.v_1;

    data.[s] = [data.[s]; v1, irs];
  }
}

for (s in members(dt))
{
  printf("Case %s: computation lasted %g secs.\n", s, dt.[s]);
}

gnulegend(members(data) + ["/D", "/cmdiode"]...
    + [" (Global Parameter TEMP="+num2str(TEMP)+")", " (Local Parameter TAMB=0, Input VTJA="+num2str(TEMP,"%.0f")+")"]);
gnuscale("lin", "log");
gnuxlabel ("Forward Voltage (V)");
gnuylabel ("Forward Current (A)");
gnuformat ([...
    "with lines lt 1 lw 3 lc rgb 'red'", ...
    "with lines lt 7 lw 6 lc rgb 'blue'", ...
[]]);
gnuplot( data, "fig/xpe_spice_vs_xspice_at_" + num2str(TEMP,"%.0fC") + ".eps" );

spice.kill();








