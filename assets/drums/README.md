# Drum recordings

Six short strokes for the metronome (`lib/audio/drum_kit.dart`), taken from
the **Versilian Community Sample Library (VCSL)** by Versilian Studios LLC,
released under **Creative Commons CC0 1.0 Universal** (public domain; the
licence text is in the repository: https://github.com/sgossner/VCSL).

| File | Source (in the VCSL repository, under `Idiophones/Struck Idiophones` or `Membranophones/Struck Membranophones`) |
| --- | --- |
| `ride.wav`, `ghost.wav` | Suspended Cymbal 1 / `susCymb1_hit_stick_mp1.wav` (stick on the cymbal) |
| `bell.wav` | Suspended Cymbal 1 / `susCymb1_hit_bell_mf1.wav` (the bell) |
| `kick.wav` | Bass Drum 1 / `BDrumNew_hit_v2_rr1_Sum.wav` |
| `snare.wav` | Snare Drum, Modern 1 / `Snare2_HitSN_v3_rr1_Mid.wav` |
| `chick.wav` | Hi-Hat Cymbal / `HiHat_Close_rr1_Mid.wav` (closing with the foot) |

They are cut from the attack, mixed to mono, faded and levelled to the same
peak by `tool/prepare_drums.dart` (44.1 kHz, 16 bit, about 135 kB in all).
