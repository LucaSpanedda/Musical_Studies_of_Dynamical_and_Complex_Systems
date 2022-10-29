// import Standard Faust library
// https://github.com/grame-cncm/faustlibraries/
import("stdfaust.lib");

// Logistic Map - simple non-linear dynamical equation
// starting population (x) = number from 0. to 1.
// resources of the population (r) = number from 0. to 4.
// Faust standard libraries
import("stdfaust.lib");

// SVFTPT filter function
SVFTPT(K, Q, CF, x) = circuitout : !,!,_,_,_,_,_,_,_,_
    with{
        g = tan(CF * ma.PI / ma.SR);
        R = 1.0 / (2.0 * Q);
        G1 = 1.0 / (1.0 + 2.0 * R * g + g * g);
        G2 = 2.0 * R + g;

        circuit(s1, s2) = u1 , u2 , lp , hp , bp, notch, apf, ubp, peak, bshelf
            with{
                hp = (x - s1 * G2 - s2) * G1;
                v1 = hp * g;
                bp = s1 + v1;
                v2 = bp * g;
                lp = s2 + v2;
                u1 = v1 + bp;
                u2 = v2 + lp;
                notch = x - ((2*R)*bp);
                apf = x - ((4*R)*bp);
                ubp = ((2*R)*bp);
                peak = lp -hp;
                bshelf = x + (((2*K)*R)*bp);
            };
    // choose the output from the SVF Filter (ex. bshelf)
    circuitout = circuit ~ si.bus(2);
    };
// Filters Outs
LPsvf(CF, x) = SVFTPT(0 : ba.db2linear, 0 : ba.db2linear, CF, x) : _,!,!,!,!,!,!,!;
HPsvf(CF, x) = SVFTPT(0 : ba.db2linear, 0 : ba.db2linear, CF, x) : !,_,!,!,!,!,!,!;
BPsvftpt(BW, CF, x) = SVFTPT(1, Q, CF, x*(BW/CF)) : !,!,_,!,!,!,!,!
    with{
        Q = CF / BW;
        };

// Instrument Spectral Model (cello at 220Hz)
// F = Fundamental, N = Voices, Q = Filter Bandwidth
F = 40;
N = 8;
Q = 2;
// list: Frequencies, Amps
spectrefreq = (F *1, F *2, F *3, F *4, F *5, F *6, F *7, F *8, F *9, F *10);
spectreamps = (1.00, .498, .108, .401, .230, .295, .440, .398, .298, .1200);
// index
Flist(index) = ba.take(index + 1, spectrefreq);
Alist(index) = ba.take(index + 1, spectreamps);
// Bandpass Filter Banks
filterbanks(x) = x <: par(i, N, BPsvftpt(Q, Flist(i)) * Alist(i) / N) :> + ;

logisticmap(r, in) = mapfunc
with{
    lmap(y) = y * (1 / r) * (1 - y);
    mapfunc = in : abs / 2 * r : (+ : lmap : fi.dcblocker : filterbanks : ma.tanh)~ _;
    };
process =  _ <: (_*40 : logisticmap(100)), (_@ma.SR*40 : logisticmap(100));