/* Progetto Computer Music A.A. 2015/2016 */
/* Jacopo Lovatello -- M.862780 -- CP.10546576 */

/* ---- Synth Definitions ---- */
/* -- Harmony ---------------------------------------------------------------------------------------------------- */
(
SynthDef(\harmony, {

	arg outBus=0, pan=0, first=0, third=0,
		fifth=0, seventh=0, amp=0.5, attack = 0.7,
		decay = 5, dur=0.9, detune=0.5, t_trig=0;

	var signal, freq, env, dets, cutoff;

	freq = [first, third, fifth, seventh].midicps;
	dets = [0, detune, detune, detune];
	cutoff = (first + 24).midicps;

	env = EnvGen.ar(Env.perc(attack*dur, decay*dur), gate:t_trig);

	signal = Mix.fill(4, {|cnt|
		LFSaw.ar(freq[cnt]+dets[cnt], 0, amp*env);
	});
	signal = LPF.ar(signal, cutoff);

	Out.ar(outBus, Pan2.ar(signal, pan));
}).add;


/* -- Melody ----------------------------------------------------------------------------------------------------- */
SynthDef(\melody, {

	arg outBus=0, pan=0, midi=0, amp=0.4,
		attack = 0.2, decay = 0.9, dur=0.6,
		detune=0.5, t_trig=0;

	var signal, freq, env, dets, cutoff;

	freq = [midi, midi, midi].midicps;
	dets = [0, detune, detune];
	cutoff = (midi + 36).midicps;

	env = EnvGen.ar(Env.perc(attack*dur, decay*dur), gate:t_trig);

	signal = Mix.fill(3, {|cnt|
		LFSaw.ar(freq[cnt]+dets[cnt], 0, amp*env);
	});
	signal = LPF.ar(signal, cutoff);

	Out.ar(outBus, Pan2.ar(signal, pan));
}).add;


/* -- Distorsion Effect ------------------------------------------------------------------------------------------ */
SynthDef(\distorsion, {
	arg toRev=0, inBus, outBus=0, dry=0.5,
		clip=5, wet=0.2, pan=0;

	var signal;

	signal = In.ar(inBus, 1);
	signal = signal.distort;
	signal = Mix.ar((dry*signal) + (wet*((clip*signal).softclip))); 			// Distorsion

	Out.ar(outBus, Pan2.ar(signal, pan));
}).add;


/* -- Reverb Effect ---------------------------------------------------------------------------------------------- */
SynthDef(\reverb, {
	arg room=0.5, damp=0.5, inBus, outBus=0,
		pan=0, cutoff=600, qF = 10,  mix = 0.5;

	var signal;

	signal = In.ar(inBus, 1);
	signal = BPF.ar(signal, cutoff, qF);
	signal = FreeVerb.ar(signal, mix:mix, room:room, damp:damp);			// Reverb Effect

	Out.ar(outBus, Pan2.ar(signal, pan))
}).add;
)


/* ---- Main ---- */
/* -- Inizialization --------------------------------------------------------------------------------------------- */
(

var lydian = 		[0, 2, 4, 6, 7, 9, 11, 12, 14, 16, 18, 19, 21, 23, 24, 26, 28, 30, 31, 33, 35, 36];
var ionian = 		[0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24, 26, 28, 29, 31, 33, 35, 36];
var mixolidian =	[0, 2, 4, 5, 7, 9, 10, 12, 14, 16, 17, 19, 21, 22, 24, 26, 28, 29, 31, 33, 34, 36];
var dorian = 		[0, 2, 3, 5, 7, 9, 10, 12, 14, 15, 17, 19, 21, 22, 24, 26, 27, 29, 31, 33, 34, 36];
var eolian = 		[0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24, 26, 27, 29, 31, 32, 34, 36];
var frigian = 		[0, 1, 3, 5, 7, 8, 10, 12, 13, 15, 17, 19, 20, 22, 24, 25, 27, 29, 31, 32, 34, 36];
var locrian = 		[0, 1, 3, 5, 6, 8, 10, 12, 13, 15, 17, 18, 20, 22, 24, 25, 27, 29, 30, 32, 34, 36];

var saAmp = 1, saProb=0, saState=1, saOutput, saCnt=1, saPattern = [4,-1, 3, 1, 4,0]; 	// Stoch Automata vars

var saNextState, saCurrentOutput;

var scale=dorian, tonic=0, scaleIdx=0, toSynth=0;				// Routine vars

var performance, tatum = 1, harmCnt = 0, harmProb = 0;			// Performance vars

var toDist, toRev, dist, rev, mel, harm, bord;					// Sound vars

var w, btnOn, va, tonicMenu; 									// GUI vars

toDist = Bus.audio(s, 1); 										// Sources-to-Distorsion Bus
toRev = Bus.audio(s, 1); 										// Distorsion-to-Reverb Bus

dist = Synth(\distorsion, [\inBus, toDist, \outBus, toRev]);	// Distorsion Effect Instance
rev = Synth.after(dist, \reverb, [\inBus, toRev]);				// Reverb Effet Instance

mel = Synth.before(dist, \melody, [\outBus, toDist]);			// Lead Synth Instance
harm = Synth.before(dist, \harmony, [\outBus, toDist]);			// Harmony Synth Instance
bord = Synth.before(dist, \melody, [\outBus, toDist]);			// Bordone


/* -- Stochastic Automata ---------------------------------------------------------------------------------------- */
saNextState =
{arg state, prob;
var nextState;

nextState = switch (state)
	{1} {
			if(prob < 0.5)
				{2} {
				if(prob < 0.7)
					{1} {6}};
		}

	  {2} {
			if(prob < 0.1)
				{1} {
				if(prob < 0.6)
					{3} {
					if(prob < 0.8)
						{5} {6}}};
		}

	  {3} {
			if(prob < 0.8)
				{4} {6};
		}

	  {4} {
			if(prob < 0.6)
				{5} {
				if(prob < 0.8)
					{1} {6}};
		}

	  {5} {
			if(prob < 0.5)
				{1} {
				if(prob < 0.7)
					{2} {
					if(prob < 0.8)
						{4}{6}}};
		}

	  {6} {
			if(prob < 0.2)
				{1} {
				if(prob < 0.4)
					{2} {
					if(prob < 0.6)
						{3} {
						if(prob < 0.8)
							{4} {
							if(prob < 0.9)
								{5} {6}}}}};
		};

	nextState;
};

saCurrentOutput =
{ arg state, no=1, pat;
	var amp;
	var res = switch (state)
	{1} {no = no+pat[1]; amp=1;}
	{2} {no = no+pat[2]; amp=1;}
	{3} {no = no+pat[3]; amp=1;}
	{4} {no = no+pat[4]; amp=1;}
	{5} {no = no+pat[5]; amp=1;}
	{6} {no = no+pat[5]; amp=0;};

	[no, amp];
};


/* -- GUI Declaration -------------------------------------------------------------------------------------------- */
w = Window.new("GUI", Rect(500, 300, 610, 500));
btnOn = Button.new(w, Rect(20, 20, 50, 30)).states_([["Play"],["Stop"]]);	// Play/Stop
va = Slider2D.new(w, Rect(110, 30, 400, 400)).x_(0.5).y_(0.5);				// V-A
tonicMenu = PopUpMenu.new(w, Rect(20, 60, 50, 30));							// Tonic
tonicMenu.items = [
 "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
];
StaticText.new(w, Rect(275, 10, 70, 20)).string_("Valence");
StaticText.new(w, Rect(90, 150, 20, 150)).string_("A
r
o
u
s
a
l
");
w.front;


/* -- Perform ---------------------------------------------------------------------------------------------------- */

performance = Task({
    {
		/* Stoch Automata */
		saProb = 1.0.linrand;
		saOutput = saCurrentOutput.value(saState,scaleIdx,saPattern);
		scaleIdx = saOutput[0]%20;
		saAmp = saOutput[1];
		saState = saNextState.value(saState, saProb);

		toSynth = 48 + tonic + scale[scaleIdx];					// Midi value to Synth

		harmProb = 1.0.linrand;


		/* Sending MIDI and trigger to Synths */
		mel.set(\midi, toSynth,
			\amp, saAmp*0.4,
			\t_trig, 1);


		if(harmCnt%4 == 0) {									// Harmonic Synth trigger
			if(harmProb < 0.4){
				harm.set(\first, toSynth%12 + 48,
					\third, toSynth%12 + 48 + scale[(scaleIdx+2)%12],
					\fifth, toSynth%12 + 48 + scale[(scaleIdx+4)%12],
					\seventh, toSynth%12 + 48 + scale[(scaleIdx+6)%12],
					\t_trig, 1);
			}
			{
				if(harmProb < 0.6){
					harm.set(\third, toSynth%12 + 48,
						\fifth, toSynth%12 + 48 + scale[(scaleIdx+2)%12],
						\seventh, toSynth%12 + 48 + scale[(scaleIdx+4)%12],
						\first, toSynth%12 + 48 + scale[(scaleIdx+5)%12],
						\t_trig, 1);
				}
				{
					if(harmProb < 0.9){
						harm.set(\fifth, toSynth%12 + 48,
							\seventh, toSynth%12 + 48 + scale[(scaleIdx+2)%12],
							\first, toSynth%12 + 48 + scale[(scaleIdx+3)%12],
							\third, toSynth%12 + 48 + scale[(scaleIdx+5)%12],
							\t_trig, 1);
					}
					{
						if(harmProb < 1){
							harm.set(\seventh, toSynth%12 + 48,
								\first, toSynth%12 + 48 + scale[(scaleIdx+1)%12],
								\third, toSynth%12 + 48 + scale[(scaleIdx+3)%12],
								\fifth, toSynth%12 + 48 + scale[(scaleIdx+5)%12],
								\t_trig, 1);

						}
					}
				}
			}
		};
		bord.set(\midi, tonic+36, \amp, 0.4, \t_trig, 1);

		harmCnt = harmCnt + 1;

		tatum.wait;

	}.loop;

	harm.free;
	mel.free;
	dist.free;
	rev.free;

});

/* -- GUI Actions -------------------------------------------------------------------------------------------------*/

btnOn.action_({arg butt;			// Start-Stop
	if(butt.value.asBoolean)
	{
		performance.play;
		harm.set(\trig, 1);
		mel.set(\trig, 1);
	}

	{
		performance.stop;
		harm.set(\trig, 0);
		mel.set(\trig, 0);
	};
});

va.action_({|sl|

	rev.set(
		\cutoff, ((((sl.x).pow(2))*925)+75),
		\room, ((1-sl.x)*0.2)+0.5,
		\mix, 0.5 - (0.3*sl.x));

	dist.set(
		\wet, ((1-sl.x).pow(2)),
		\clip, (1-sl.x)*20,
		\dry, ((sl.x).pow(2)));


	mel.set(
		\detune, sl.y*1,
		\attack, (1-sl.y)*tatum/4+0.1,
		\decay, (1-sl.y)*tatum+0.8,
		\dur, (1-sl.y)*tatum+0.1,
		);

	bord.set(
		\attack, (1-sl.y)*tatum/4+0.1,
		\decay, (1-sl.y)*tatum+0.8,
		\dur, (1-sl.y)*tatum+0.1,
		);

	harm.set(
		\detune, sl.y*1,
		\attack, (1-sl.y)*tatum+0.2,
		\decay, (1-sl.y)*tatum*8+1,
		\dur, (1-sl.y)*tatum+0.4);

	tatum = 1-sl.y+0.2;


	// Modal Envelope
	if(sl.x < (1/7))
		{scale = locrian};

	if((sl.x >= (1/7)) && (sl.x < (2/7)))
		{scale = frigian};

	if((sl.x >= (2/7)) && (sl.x < (3/7)))
		{scale = eolian};

	if((sl.x >= (3/7)) && (sl.x < (4/7)))
		{scale = dorian};

	if((sl.x >= (4/7)) && (sl.x < (5/7)))
		{scale = mixolidian};

	if((sl.x >= (5/7)) && (sl.x < (6/7)))
		{scale = ionian};

	if(sl.x >= (6/7))
		{scale = lydian};

});

tonicMenu.action = {arg menu;		// Key
	tonic = menu.value;
};


)