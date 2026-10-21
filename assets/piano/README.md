# Piano recordings

Thirteen notes (C2 to C5, a minor third apart) from the **Salamander Grand
Piano V3** by Alexander Holm, a Yamaha C5, in three velocity layers of the
sixteen recorded (5 soft, 8 normal, 11 firm), and the sound of the dampers
(`rel36` to `rel71`) for the keys Harmony plays.
The author released it into the public domain on 4 March 2022
(https://rytmenpinne.wordpress.com/sounds-and-such/salamander-grandpiano/);
the 48 kHz 24-bit edition was taken from
https://github.com/sfzinstruments/SalamanderGrandPiano.

Each file is one channel (`L` or `R`) of the stereo recording, 48 kHz 16-bit
FLAC, kept at the level it was recorded at: the normal layer cut to 10 s, the
soft and firm ones to 4 s, the dampers to 1 s, by `tool/prepare_piano.dart`,
which also measured the tuning and level corrections in
`PianoSamples.tuning` and `PianoSamples.levels`.
