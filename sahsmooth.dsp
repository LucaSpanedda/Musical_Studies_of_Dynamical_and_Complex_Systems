// THIS library
import("stdfaust.lib");

// SAH with internal trigger
SAHsmooth(f, w) = w : sample ~ _ : onepoletau(1/f)
with{
    // binary selector 0 - 1
    selector(sel, x, y) = (x * (1-sel) + y * (sel));
    // SAH Loop
    sample(fb, y) = (phasor(f) : trigger, fb, y) : selector;
    // PH to trigger
    trigger(x) =  x < x';
    // classic phasor
    phasor(f) = (f/ma.SR):(+ :\(x).(selector(0, x, 0)) : \(x).(x - int(x))) ~ _;
    
    onepoletau(tau, x) = fb ~ _ 
    with {  
        fb(y) = (1.0 - s) * x + s * y; 
        s = exp(-1.0/(tau * ma.SR));
        //   tau = desired smoothing time constant in seconds
        };
};

process = par(i, 8, SAHsmooth(1+(i*1.1234), no.noise));