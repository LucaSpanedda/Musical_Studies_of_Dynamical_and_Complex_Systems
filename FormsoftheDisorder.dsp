//---------------------------------------------------- FORMS OF THE DISORDER ---
// Faust standard libraries
import("stdfaust.lib");

FQ = hslider("freq",1,1,10000,1);
GN = hslider("gain",0,0,1,.001);
FC = nentry("Factor",2,1,100,1);

// generate a random number from a seed
random(seed) = abs((seed * 1103515245) / 2147483647.0);
// nonlinear Low Frequency oscillator based on arbritary Frequencies 
nonlinearosc(seed,slowFactor,voices) = 
    par(i, voices, sin(( (random(seed + (i * 1000))/ma.SR/slowFactor) : 
                         (+ : \(x).(x-int(x)) ) ~ _) * 2 * ma.PI)
        ) :> +/voices : _ + 1 : _ / 2;
// clip function
limit(maxl,minl,x) = x : max(minl, min(maxl));
// digital noise algorythm with internal recursive comb filter
fbNoise(seed,samps) = ( (seed) : (+ @(limit(ma.SR,0,samps)) ~ 
                        *(1103515245)) / 2147483647.0 );
// nonlinear circuit based on noise comb
circuit(F,seed,G) = \(FB).  ( (F/ma.SR) * (1 - G) : 
                                        (_ + FB : \(x).(x-int(x)) 
                                                : _ * fbNoise(seed,F) 
                                                * (1 + (G * 2))
                                        )
                                )~_ ;
// outs
process =   (   nonlinearosc(1266,1000,8) * 2000 @ma.SR,
                nonlinearosc(1300,1000,8) * .250 @ma.SR   
            ) : 
                    \(x,z).(    circuit(x,6122,z),
                                circuit(x,2211,z),
                                x,
                                z
                           );
