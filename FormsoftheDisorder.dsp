//-------------------------------------------------- FORMS FROM THE DISORDER ---
// Faust standard libraries
import("stdfaust.lib");
FQ = hslider("freq",1,1,10000,1);
GN = hslider("gain",0,0,1,.001);
FC = nentry("Factor",2,1,100,1);
onePoleTPT(cf, x) = loop ~ _ : ! , si.bus(3)
    with {
        g = tan(cf * ma.PI * ma.T);
        G = g / (1.0 + g);
        loop(s) = u , lp , hp , ap
            with {
            v = (x - s) * G; u = v + lp; lp = v + s; hp = x - lp; ap = lp - hp;
            };
    };
LPTPT(cf, x) = onePoleTPT(cf, x) : (_ , ! , !);
limit(maxl,minl,x) = x : max(minl, min(maxl));
fbNoise(seed,samps) = ( (seed) : (+ @(limit(ma.SR,0,samps)) ~ *(1103515245)) 
                                                            / 2147483647.0);
walkNoise(seed) = (fbNoise(seed,0) : seq(i,4,LPTPT(.01)) * 100 + 1) / 2;
datamoshosc(F,seed,G) = \(FB).  ( (F/ma.SR) * (1 - G) : 
                                        (_ + FB : \(x).(x-int(x)) 
                                                : _ * fbNoise(seed,F) 
                                                * (1 + (G * 2))
                                        )
                                )~_ ;
process =   (   walkNoise(1243) * 1000 @1000,
                walkNoise(4397) * .5 @1000    ) : 
                    \(x,z).(    datamoshosc(x,1122,z),
                                datamoshosc(x,3211,z),(x,z) );
