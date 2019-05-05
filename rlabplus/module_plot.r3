//
//
//

gnuwin (1);
gnulimits  (0,max(t),0, 1.2*vmax);
gnuxtics (t_end/10,5);
gnuytics (1,5);
gnuxlabel ("Time (s)");
gnuylabel ("Voltage (V) , Current (A)");
gnulegend (["Forward voltage", "Forward current"])
gnuformat ([...
    "with lines lt 1 lw 3 lc rgb 'blue'", ...
    "with lines lt 1 lw 3 lc rgb 'green'", ...
[]]);
if (exist(saveplot))
{
  _pn = saveplot + "-vi";
  gnuplot (<<a1=[t,v1];a2=[t,i1]>>, _pn + ".eps");
}
else
{
  gnuplot (<<a1=[t,v1];a2=[t, i1]>>);
}


gnuwin    (2);
gnulimits (0,max(t),TEMP,TEMP+1.1*max(v2));
gnuxlabel ("Time (s)");
gnuylabel ("Junction Temperature (deg C)");
gnuxtics (t_end/10,5);
gnuytics (1,10);
gnuformat ([...
    "axes x1y1 with lines lt 1 lw 3 lc rgb 'black'", ...
[]]);
if (exist(saveplot))
{
  _pn = saveplot + "-tj";
  gnuplot   ([t,v2] + [0,TEMP], _pn + ".eps");
}
else
{
  gnuplot   ([t,v2] + [0,TEMP]);
}
