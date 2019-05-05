//
//
//

// spice.init(stderr());
spice.init(stderr());

gnuwins (3);

// constants
usec = 1e-6;
nsec = 1e-9;
msec = 1e-3;
uF = 1e-6;
mohm = 1e-3;
Mohm = 1e6;

imax = 1;
vmax = 4;

t_end = 5 * msec;

ckt0 = [ ...
  "XLAMP XP E/G - LED WITH PULSED CURRENT SOURCE", ...
  "* PARAMETERS", ...
  "i1 0 3 DC 0 PULSE(0 "+num2str(imax)+" 1e-7 1e-7 1e-7 50e-6 100e-6)", ...
  "rth    2 0 5", ...
  "cth    2 0 1e-5", ...
  "v1     3 1 DC 0 AC 0", ...
  "a1     1 0 2 xpe", ...
  "rp     1 0 1e12", ...
  ".MODEL xpe cmdiode(RS=0.43895 IS=520.88E-12 N=5.7846 XTI=62.500 EG=2.5000", ...
  "+  ETA0=0.3 ETAI=-1e-1 ETAT=-1e-2 CP=1e-12 TAMB=${temp})", ...
  ".options method=gear abstol=1e-6 trtol=2", ...
  ".tran 1e-6 " + num2str(t_end), ...
  ".end", ...
[]];

TEMP = 50;
data = <<>>;

if (1)
{
  ckt1 = ckt0;

  // temp
  ckt1 = gsub(num2str(TEMP), "${temp}", ckt1).string;

  spice.runckt(ckt1);
  while(spice.isrunning())
  { sleep(0.01); }
  all_vals = spice.getvals();
}

spice.kill();

t = all_vals.data.time;
v1 = all_vals.data.v_1;
if (exist(all_vals.data.i_v1))
{
  i1 = -all_vals.data.i_v1;
}
v2 = all_vals.data.v_2;
_idx_nan = find(isnan(i1));
i1[_idx_nan] = zeros(_idx_nan);

saveplot = "./fig/xpe-i_fixed";
rfile module_plot





