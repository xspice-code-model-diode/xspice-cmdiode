#include <math.h>
#include <stdlib.h>

#define T_NOM_K         300.0
#define T_ZERO_DEG_C_K  273.15

#include <gsl/gsl_const_mksa.h>
#include <gsl/gsl_const_num.h>

#define ABS(x)    ((x) >= 0  ? (x) : -(x))

#define MODEL_NAME "ucm_diode"

// #define DEBUG

void ucm_cmdiode (ARGS)
{
  // parameters:
  double DIOemissionCoeff     = PARAM(n);           // forward emission coefficient parameter
  double DIOsatCur            = PARAM(is);          // saturation current parameter
  double t_nom_k              = PARAM(tnom);        // nominal temperature in deg K
  double t_amb_c              = PARAM(tamb);        // ambient temperature in deg C
  double r_ser                = PARAM(rs);          // series resistance
  double r_par                = PARAM(rp);          // parallel resistance
  double c_par                = PARAM(cp);          // parallel capacitance
  double c_over_dt=0.0; 
  double EG                   = PARAM(eg);          // Energy Gap
  double XTI                  = PARAM(xti);         // saturation current temperature exponent
  double eta                  = PARAM(eta);

  // input/output
  double v_in                 = INPUT(d);           // potential across diode
  double temp_ja_c=0.0;
  Mif_Complex_t ac_gain;  /* AC gain  */

  double dex, vt, vt_nom, i_diode=0.0, deriv_i_diode_v_d, *v_d_old=0;
  double DIOnomTemp, logfactor, DIOtsatCur, DIOambTemp, DIOtemp, i_out, d_i_out_v_in;

#ifdef DEBUG
  FILE * fp = fopen ("ngspice-" MODEL_NAME ".log", "a");
#endif

#ifdef DEBUG
  fprintf(fp, MODEL_NAME ": t_amb_c,t_nom_k,temp_ja_c=%g,%g,%g\n",t_amb_c, t_nom_k, temp_ja_c);
#endif

  //
  // figure out:
  //    DIOnomTemp
  //    DIOtemp,    the junction temperature
  //
  // all parameters are specified at nominal temperature
  if (! PORT_NULL(vtih))
  {
    temp_ja_c = INPUT(vtih); // volt as junction temperature kelvin difference between ambient and junction
  }

  // nominal temperature:
  DIOnomTemp = t_nom_k > 0 ? t_nom_k : T_NOM_K;

  // diode ambient temperature:
  //    if not provided take the global temperature
  if (t_amb_c < (-T_ZERO_DEG_C_K))
  {
    DIOambTemp = T_ZERO_DEG_C_K + TEMPERATURE;
  }
  else
    DIOambTemp = T_ZERO_DEG_C_K + t_amb_c;

  // if diode junction temperature is not specified through input terminal,
  // then it is the same as the ambient temperature
  DIOtemp = DIOambTemp + temp_ja_c;

#ifdef DEBUG
  fprintf(fp, MODEL_NAME ": DIOtemp,DIOambTemp,DIOnomTemp=%g,%g,%g\n",DIOtemp, DIOambTemp, DIOnomTemp);
#endif

  if (ANALYSIS != AC && c_par>0)
  {
    if (INIT==1)
    {
      cm_analog_alloc(TRUE,sizeof(double));
    }
    v_d_old  = (double *) cm_analog_get_ptr(TRUE,1);

    if (TIME == 0.0)
    {
      c_over_dt = 0;
      *v_d_old = v_in;
    }
    else
    {
      if (TIME > T(1))
        c_over_dt = c_par / (TIME - T(1));
    }
  }

  vt = GSL_CONST_MKSA_BOLTZMANN * DIOtemp / GSL_CONST_MKSA_ELECTRON_VOLT;
  vt_nom = GSL_CONST_MKSA_BOLTZMANN * DIOnomTemp / GSL_CONST_MKSA_ELECTRON_VOLT;

  logfactor = EG / vt_nom - EG / vt + XTI * log(DIOtemp / DIOnomTemp);
  DIOtsatCur = DIOsatCur * exp(logfactor / DIOemissionCoeff);

  if (v_in > 0)
  {
    //  we have to find junction voltage from v_in
    double v_d_0=0, v_d_1=v_in, eps=1e-9, rho=0;
    int max_count = 2000, j=0;
    rho = r_ser / r_par;

#ifdef DEBUG
    fprintf(fp, MODEL_NAME ": rser,rpar,rho=%g,%g,%g\n",r_ser, r_par, rho);
#endif

    // consistently calculate diode current only if r_ser > 0
    if (rho > 0)
    {
      while (ABS(v_d_0 - v_d_1) > eps && j<max_count)
      {
        v_d_0 = v_d_1;

        dex = v_d_0 / (DIOemissionCoeff * vt);
        dex = dex >  100.0 ?  100.0 : dex;
        dex = dex < -100.0 ? -100.0 : dex;
        dex = exp(dex);
        deriv_i_diode_v_d   = DIOtsatCur * dex / (DIOemissionCoeff * vt);
        i_diode             = DIOtsatCur * (dex - 1.0);

        // Newton algorhythm should converge here
        if (v_d_old && c_over_dt>0)
        {
          v_d_1 = v_d_0 - (r_ser * i_diode + (1+rho)*v_d_0 + c_over_dt*(v_d_0 - *v_d_old) - v_in)
                      / (1 + rho + r_ser * deriv_i_diode_v_d + r_ser * c_over_dt);
        }
        else
        {
          v_d_1 = v_d_0 - (r_ser * i_diode + (1+rho)*v_d_0 - v_in)
                      / (1 + rho + r_ser * deriv_i_diode_v_d);
        }
#ifdef DEBUG
        fprintf(fp, MODEL_NAME ": temp_ja_c,vd1,vd2=%g,%g,%g\n",temp_ja_c, v_d_1, v_d_0);
#endif
        j++;
      }
    }

    // i_out comprises i_diode and current through r_par
    i_out         = i_diode + v_d_0 / r_par;
    if (v_d_old && c_over_dt>0)
    {
      i_out         = i_out + c_over_dt*(v_d_0 - *v_d_old);
      *v_d_old      = v_d_0;  // store diode voltage for the next call
      d_i_out_v_in  = (deriv_i_diode_v_d + 1 / r_par + c_over_dt)
                      / (1 + rho + r_ser * deriv_i_diode_v_d + r_ser * c_over_dt);
    }
    else
    {
      d_i_out_v_in  = (deriv_i_diode_v_d + 1 / r_par)
                      / (1 + rho + r_ser * deriv_i_diode_v_d);
    }
  }
  else
  {
    // for v_in < 0 no current flows
    i_out         = 0.0;
    d_i_out_v_in  = 0.0;
  }

#ifdef DEBUG
  fprintf(fp, MODEL_NAME ": TEMP=%g\n", TEMPERATURE);
  fprintf(fp, MODEL_NAME ": %g,%g\n", v_in, i_out);
  fclose(fp);
#endif

  switch (ANALYSIS)
  {
    case AC:
      /* Output AC Gain */
      ac_gain.real  = d_i_out_v_in;
      ac_gain.imag  = 0.0;
      AC_GAIN(d,d)  = ac_gain;
      break;

    default:
      /* Output DC & Transient Values */
      OUTPUT (d)            = i_out;
      PARTIAL(d,d)          = d_i_out_v_in;
      PARTIAL(d,vtih)       = 0;
      OUTPUT (vtih)         = -(1-eta) *  v_in * i_out;
      PARTIAL(vtih,d)       = (1-eta) * (v_in * d_i_out_v_in + i_out);
      PARTIAL(vtih,vtih)    = 0;
  }
}




