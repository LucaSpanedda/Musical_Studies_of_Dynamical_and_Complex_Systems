// Faust standard libraries
import("stdfaust.lib");

// Linear Congruential Generator
noise(initSeed) = LCG ~ _ : (_ / m)
with{
    // variables
    // initSeed = an initial seed value
    a = 18446744073709551557; // a large prime number, such as 18446744073709551557
    c = 12345; // a small prime number, such as 12345
    m = 2 ^ 31; // 2.1 billion
    // linear_congruential_generator
    LCG(seed) = ((a * seed + c) + (initSeed-initSeed') % m);
};


// Zavalishin's Onepole TPT Filter
onePoleTPT(cf, x) = loop ~ _ : ! , si.bus(3) // Outs: lp , hp , ap
with {
    g = tan(cf * ma.PI * ma.T);
    G = g / (1.0 + g);
    loop(s) = u , lp , hp , ap
    with {
        v = (x - s) * G; u = v + lp; lp = v + s; hp = x - lp; ap = lp - hp;
    };
};
// Lowpass TPT
LPTPT(cf, x) = onePoleTPT(cf, x) : (_ , ! , !);
// Highpass TPT
HPTPT(cf, x) = onePoleTPT(cf, x) : (! , _ , !);

// Fixed Peak Normalization
fixedNorm(x) = 1 / (x : loop ~ _) * x
with{
    loop(y,z) = ( (y, abs(z) ) : max);
};

// noise to nonperiodic osc
nonlinearity(seed, frequency) = noise(seed) : 
    LPTPT(frequency) : LPTPT(frequency) : fixedNorm; 
process = par(i, 10, nonlinearity( (i+1) * 469762049, 1 ) );

// input to nonperiodic osc
intononlinearity(frequency, x) = x + (ma.EPSILON-ma.EPSILON') : 
    LPTPT(frequency) : LPTPT(frequency) : fixedNorm; 
// process = intononlinearity(1,_), intononlinearity(1,_);