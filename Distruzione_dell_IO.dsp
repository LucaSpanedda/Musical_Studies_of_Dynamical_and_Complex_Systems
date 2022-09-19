// FAUST standard library
import("stdfaust.lib");
// Complex Adaptive Systems library
import("CAS.lib");

process = _ <: chunkGrains(8, 4, 1, 8, .1);