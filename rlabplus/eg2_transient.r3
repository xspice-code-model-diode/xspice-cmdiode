//
//
//

// spice.init(stderr());
spice.init(stderr());

gnuwins (2);

// constants
usec = 1e-6;
nsec = 1e-9;
msec = 1e-3;
uF = 1e-6;
mohm = 1e-3;
Mohm = 1e6;

ckt0 = [ ...
  "XLAMP XP E/G - LED WITH FIXED VOLTAGE SUPPLY", ...
  "* PARAMETERS", ...
  "v1 1 0 DC 0 PULSE(0 50 1e-7 1e-7 1e-7 50e-6 100e-6)", ...
  "vtja   2 0   ${temp}", ...
  "r1     1 3 1k", ...
  "a1     3 0 2 xpe", ...
  ".MODEL xpe cmdiode(RS=0.43895 IS=520.88E-12 N=5.7846 XTI=62.500 EG=2.5000 RP=1e10 TAMB=0)", ...
  ".options method=gear abstol=1e-6 trtol=2", ...
  ".tran 1e-6 1e-2", ...
  ".end", ...
[]];

TEMP = 50;
data = <<>>;

if (1)
{
  ckt1 = ckt0;

  // temp
  ckt1 = gsub(text(TEMP), "${temp}", ckt1).string;

  spice.runckt(ckt1);
  while(spice.isrunning())
  { sleep(0.01); }
  all_vals = spice.getvals();
}

spice.kill();

t = all_vals.data.time;
v1 =  all_vals.data.v_1;
i1 = -all_vals.data.i_v1;
_idx_nan = find(isnan(i1));
i1[_idx_nan] = zeros(_idx_nan);

gnuwin (1);
gnulimits (,,,);
gnuplot ([t,v1]);

gnuwin (2);
gnulimits (,,,);
gnuplot ([t,i1]);







