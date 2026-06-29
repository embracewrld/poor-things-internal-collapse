(
s.options.numWireBufs = 1024;
s.options.numInputBusChannels = 0;
s.reboot;
)

OSCFunc.trace(false);

(
OSCdef(\test,{
    arg msg, time, addr, args;
    msg[1].postln;
    if(msg[2].isNumber){
        Synth(\tone, [freq:msg[2].clip(150, 12000)]);
    }
}, '/test');
)

~illia_osc = NetAddr("localhost", 57120);

~illia_osc.sendMsg('/test', rrand(1,100), 500);

(
    SynthDef(\tone, {
        var sig;
        sig = SinOsc.ar(440, 0, 0.1)!2;
        sig = Env.perc.kr * sig;
        Out.ar(0, sig);
    }).add;
)

Synth(\tone);
