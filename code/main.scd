(
s.options.numInputBusChannels = 0; // Полностью отключает аудиовход на сервере
s.options.outDevice = "WH-CH520";  // Оставляем только выход на наушники
s.boot;
)
s.quit;
s.reboot;

// (
// OSCdef(\touchDesigner_data, { |msg, time, addr, recvPort|

//     var address = msg; 
//     var value = msg[3]; 
    
//     // 1. Спектральная лепка: стираем частоты, опуская левое запястье
//     if(address == '/left_wrist:y', { 
//         ~synth.set(\y_pos, value); 
//     });
    
//     // 2. Иллюзия безумия: цифровой глитч от скорости запястья
//     // (если ты передаешь канал left_wrist_velocity из ноды math2)
//     if(address == '/left_wrist_velocity', { 
//         ~synth.set(\velocity, value); 
//     });

//     // 3. Пространственное раздвоение (дистанция между руками)
//     // (если передаешь канал hand_distance)
//     if(address == '/hand_distance', { 
//         ~synth.set(\hand_dist, value); 
//     });
 
// }, '/left_wrist:y', '/left_wrist_velocity', '/hand_distance');
// )

(
// 1. Слушаем высоту запястья (для спектральной лепки)
OSCdef(\wrist_y_listener, { |msg|
    var value = msg[1]; // Берем саму цифру из сообщения
    ~synth.set(\y_pos, value); // Отправляем в синтезатор
}, '/left_wrist:y'); 

// 2. Слушаем скорость (для цифрового глитча и иллюзии безумия)
OSCdef(\wrist_vel_listener, { |msg|
    var value = msg[1];
    ~synth.set(\velocity, value);
}, '/left_wrist_velocity');

// 3. Слушаем дистанцию (для пространственного раздвоения)
OSCdef(\distance_listener, { |msg|
    var value = msg[1];
    ~synth.set(\hand_dist, value);
}, '/hand_distance');
)

OSCFunc.trace(false);
(
SynthDef(\internal_decay,
{
    arg y_pos = 1.0, out = 0, amp = 0.2, hand_dist= 0.0, velocity = 0.0;
    var body_sound = SinOsc.ar() * 0.6;

    var shadow_sound = WhiteNoise.ar(0.2) + Saw.ar(440, 0.1);

    var cutoff = y_pos.linexp(0.0, 1.0, 8000, 150); // Map y_pos to a cutoff frequency range mean if the doll move down her hands sound will be more muffled and if she move up it will be more bright
    var molded_shadew = LPF.ar(shadow_sound, cutoff);

    var glitch_rate = velocity.linexp(0.0, 1.0, 1, 50);
    var glitch = molded_shadew * LFPulse.kr(glitch_rate, 0, 0.5); // if the doll move her hands fast the glitch will be more frequent and if she move her hands slow it will be less frequent

    var pan_spread = hand_dist.linlin(0.0, 1.0, 0.0, 1.0);
    var panned_body = Pan2.ar(body_sound, 0);
    var panned_shadow = Pan2.ar(glitch, pan_spread); // if hands near each other the sound will be more centered and if they are far apart it will be more spread out

    var final_mix = panned_body + panned_shadow;

    Out.ar(out, final_mix * amp);

}).add;
)

~synth = Synth(\internal_decay);