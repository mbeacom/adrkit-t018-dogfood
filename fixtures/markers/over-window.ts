// @adr 0011
//
// Truncation fixture: a file whose header declares a decision and whose body
// runs past the 8192-byte marker window.
//
// This is the case the v0.6.0 `scannedBytes` / `fileBytes` fields were added
// for, and the one this repository previously could not measure. The window
// constant alone does not answer "how much was left unread": the scan stops at
// the last COMPLETE line inside the window, so the extent is not
// `min(fileBytes, 8192)` and the remainder is not `fileBytes - 8192`.
//
// Four properties are asserted against this file, as `TRUNC-1` through
// `TRUNC-5` — the first is split across two assertions, because the truncation
// flag and the byte comparison behind it are worth failing independently:
//
//   * `truncated` is true, and `scannedBytes < fileBytes`.
//   * `scannedBytes` is strictly less than the 8192 window constant, because
//     the cut falls back to a line boundary. Asserting `< windowBytes` rather
//     than a literal is deliberate: the exact extent depends on where this
//     file's line breaks land, and pinning the literal would make an unrelated
//     edit to the padding below look like an adrkit regression.
//   * `fileBytes` equals the real on-disk size, cross-checked against `wc -c`
//     rather than trusted from the tool that reported it.
//   * The header marker still resolves. Truncation must not lose a declaration
//     that was inside the window, which is the whole reason the window exists.
//
// The padding below is inert filler. It carries no marker, and a marker placed
// past the window would not be found anyway — which is the documented cost of
// bounding the scan, not a defect.

export const truncationFixture = true;

// padding line 000 — inert filler that pushes this file past the marker window.
// padding line 001 — inert filler that pushes this file past the marker window.
// padding line 002 — inert filler that pushes this file past the marker window.
// padding line 003 — inert filler that pushes this file past the marker window.
// padding line 004 — inert filler that pushes this file past the marker window.
// padding line 005 — inert filler that pushes this file past the marker window.
// padding line 006 — inert filler that pushes this file past the marker window.
// padding line 007 — inert filler that pushes this file past the marker window.
// padding line 008 — inert filler that pushes this file past the marker window.
// padding line 009 — inert filler that pushes this file past the marker window.
// padding line 010 — inert filler that pushes this file past the marker window.
// padding line 011 — inert filler that pushes this file past the marker window.
// padding line 012 — inert filler that pushes this file past the marker window.
// padding line 013 — inert filler that pushes this file past the marker window.
// padding line 014 — inert filler that pushes this file past the marker window.
// padding line 015 — inert filler that pushes this file past the marker window.
// padding line 016 — inert filler that pushes this file past the marker window.
// padding line 017 — inert filler that pushes this file past the marker window.
// padding line 018 — inert filler that pushes this file past the marker window.
// padding line 019 — inert filler that pushes this file past the marker window.
// padding line 020 — inert filler that pushes this file past the marker window.
// padding line 021 — inert filler that pushes this file past the marker window.
// padding line 022 — inert filler that pushes this file past the marker window.
// padding line 023 — inert filler that pushes this file past the marker window.
// padding line 024 — inert filler that pushes this file past the marker window.
// padding line 025 — inert filler that pushes this file past the marker window.
// padding line 026 — inert filler that pushes this file past the marker window.
// padding line 027 — inert filler that pushes this file past the marker window.
// padding line 028 — inert filler that pushes this file past the marker window.
// padding line 029 — inert filler that pushes this file past the marker window.
// padding line 030 — inert filler that pushes this file past the marker window.
// padding line 031 — inert filler that pushes this file past the marker window.
// padding line 032 — inert filler that pushes this file past the marker window.
// padding line 033 — inert filler that pushes this file past the marker window.
// padding line 034 — inert filler that pushes this file past the marker window.
// padding line 035 — inert filler that pushes this file past the marker window.
// padding line 036 — inert filler that pushes this file past the marker window.
// padding line 037 — inert filler that pushes this file past the marker window.
// padding line 038 — inert filler that pushes this file past the marker window.
// padding line 039 — inert filler that pushes this file past the marker window.
// padding line 040 — inert filler that pushes this file past the marker window.
// padding line 041 — inert filler that pushes this file past the marker window.
// padding line 042 — inert filler that pushes this file past the marker window.
// padding line 043 — inert filler that pushes this file past the marker window.
// padding line 044 — inert filler that pushes this file past the marker window.
// padding line 045 — inert filler that pushes this file past the marker window.
// padding line 046 — inert filler that pushes this file past the marker window.
// padding line 047 — inert filler that pushes this file past the marker window.
// padding line 048 — inert filler that pushes this file past the marker window.
// padding line 049 — inert filler that pushes this file past the marker window.
// padding line 050 — inert filler that pushes this file past the marker window.
// padding line 051 — inert filler that pushes this file past the marker window.
// padding line 052 — inert filler that pushes this file past the marker window.
// padding line 053 — inert filler that pushes this file past the marker window.
// padding line 054 — inert filler that pushes this file past the marker window.
// padding line 055 — inert filler that pushes this file past the marker window.
// padding line 056 — inert filler that pushes this file past the marker window.
// padding line 057 — inert filler that pushes this file past the marker window.
// padding line 058 — inert filler that pushes this file past the marker window.
// padding line 059 — inert filler that pushes this file past the marker window.
// padding line 060 — inert filler that pushes this file past the marker window.
// padding line 061 — inert filler that pushes this file past the marker window.
// padding line 062 — inert filler that pushes this file past the marker window.
// padding line 063 — inert filler that pushes this file past the marker window.
// padding line 064 — inert filler that pushes this file past the marker window.
// padding line 065 — inert filler that pushes this file past the marker window.
// padding line 066 — inert filler that pushes this file past the marker window.
// padding line 067 — inert filler that pushes this file past the marker window.
// padding line 068 — inert filler that pushes this file past the marker window.
// padding line 069 — inert filler that pushes this file past the marker window.
// padding line 070 — inert filler that pushes this file past the marker window.
// padding line 071 — inert filler that pushes this file past the marker window.
// padding line 072 — inert filler that pushes this file past the marker window.
// padding line 073 — inert filler that pushes this file past the marker window.
// padding line 074 — inert filler that pushes this file past the marker window.
// padding line 075 — inert filler that pushes this file past the marker window.
// padding line 076 — inert filler that pushes this file past the marker window.
// padding line 077 — inert filler that pushes this file past the marker window.
// padding line 078 — inert filler that pushes this file past the marker window.
// padding line 079 — inert filler that pushes this file past the marker window.
// padding line 080 — inert filler that pushes this file past the marker window.
// padding line 081 — inert filler that pushes this file past the marker window.
// padding line 082 — inert filler that pushes this file past the marker window.
// padding line 083 — inert filler that pushes this file past the marker window.
// padding line 084 — inert filler that pushes this file past the marker window.
// padding line 085 — inert filler that pushes this file past the marker window.
// padding line 086 — inert filler that pushes this file past the marker window.
// padding line 087 — inert filler that pushes this file past the marker window.
// padding line 088 — inert filler that pushes this file past the marker window.
// padding line 089 — inert filler that pushes this file past the marker window.
// padding line 090 — inert filler that pushes this file past the marker window.
// padding line 091 — inert filler that pushes this file past the marker window.
// padding line 092 — inert filler that pushes this file past the marker window.
// padding line 093 — inert filler that pushes this file past the marker window.
// padding line 094 — inert filler that pushes this file past the marker window.
// padding line 095 — inert filler that pushes this file past the marker window.
// padding line 096 — inert filler that pushes this file past the marker window.
// padding line 097 — inert filler that pushes this file past the marker window.
// padding line 098 — inert filler that pushes this file past the marker window.
// padding line 099 — inert filler that pushes this file past the marker window.
// padding line 100 — inert filler that pushes this file past the marker window.
// padding line 101 — inert filler that pushes this file past the marker window.
// padding line 102 — inert filler that pushes this file past the marker window.
// padding line 103 — inert filler that pushes this file past the marker window.
// padding line 104 — inert filler that pushes this file past the marker window.
// padding line 105 — inert filler that pushes this file past the marker window.
// padding line 106 — inert filler that pushes this file past the marker window.
// padding line 107 — inert filler that pushes this file past the marker window.
// padding line 108 — inert filler that pushes this file past the marker window.
// padding line 109 — inert filler that pushes this file past the marker window.
// padding line 110 — inert filler that pushes this file past the marker window.
// padding line 111 — inert filler that pushes this file past the marker window.
// padding line 112 — inert filler that pushes this file past the marker window.
// padding line 113 — inert filler that pushes this file past the marker window.
// padding line 114 — inert filler that pushes this file past the marker window.
// padding line 115 — inert filler that pushes this file past the marker window.
// padding line 116 — inert filler that pushes this file past the marker window.
// padding line 117 — inert filler that pushes this file past the marker window.
// padding line 118 — inert filler that pushes this file past the marker window.
// padding line 119 — inert filler that pushes this file past the marker window.
// padding line 120 — inert filler that pushes this file past the marker window.
// padding line 121 — inert filler that pushes this file past the marker window.
// padding line 122 — inert filler that pushes this file past the marker window.
// padding line 123 — inert filler that pushes this file past the marker window.
// padding line 124 — inert filler that pushes this file past the marker window.
// padding line 125 — inert filler that pushes this file past the marker window.
// padding line 126 — inert filler that pushes this file past the marker window.
// padding line 127 — inert filler that pushes this file past the marker window.
// padding line 128 — inert filler that pushes this file past the marker window.
// padding line 129 — inert filler that pushes this file past the marker window.
// padding line 130 — inert filler that pushes this file past the marker window.
// padding line 131 — inert filler that pushes this file past the marker window.
// padding line 132 — inert filler that pushes this file past the marker window.
// padding line 133 — inert filler that pushes this file past the marker window.
// padding line 134 — inert filler that pushes this file past the marker window.
// padding line 135 — inert filler that pushes this file past the marker window.
// padding line 136 — inert filler that pushes this file past the marker window.
// padding line 137 — inert filler that pushes this file past the marker window.
// padding line 138 — inert filler that pushes this file past the marker window.
// padding line 139 — inert filler that pushes this file past the marker window.
// padding line 140 — inert filler that pushes this file past the marker window.
// padding line 141 — inert filler that pushes this file past the marker window.
// padding line 142 — inert filler that pushes this file past the marker window.
// padding line 143 — inert filler that pushes this file past the marker window.
// padding line 144 — inert filler that pushes this file past the marker window.
// padding line 145 — inert filler that pushes this file past the marker window.
// padding line 146 — inert filler that pushes this file past the marker window.
// padding line 147 — inert filler that pushes this file past the marker window.
// padding line 148 — inert filler that pushes this file past the marker window.
// padding line 149 — inert filler that pushes this file past the marker window.
// padding line 150 — inert filler that pushes this file past the marker window.
// padding line 151 — inert filler that pushes this file past the marker window.
// padding line 152 — inert filler that pushes this file past the marker window.
// padding line 153 — inert filler that pushes this file past the marker window.
// padding line 154 — inert filler that pushes this file past the marker window.
// padding line 155 — inert filler that pushes this file past the marker window.
// padding line 156 — inert filler that pushes this file past the marker window.
// padding line 157 — inert filler that pushes this file past the marker window.
// padding line 158 — inert filler that pushes this file past the marker window.
// padding line 159 — inert filler that pushes this file past the marker window.
// padding line 160 — inert filler that pushes this file past the marker window.
// padding line 161 — inert filler that pushes this file past the marker window.
// padding line 162 — inert filler that pushes this file past the marker window.
// padding line 163 — inert filler that pushes this file past the marker window.
// padding line 164 — inert filler that pushes this file past the marker window.
// padding line 165 — inert filler that pushes this file past the marker window.
// padding line 166 — inert filler that pushes this file past the marker window.
// padding line 167 — inert filler that pushes this file past the marker window.
// padding line 168 — inert filler that pushes this file past the marker window.
// padding line 169 — inert filler that pushes this file past the marker window.
// padding line 170 — inert filler that pushes this file past the marker window.
// padding line 171 — inert filler that pushes this file past the marker window.
// padding line 172 — inert filler that pushes this file past the marker window.
// padding line 173 — inert filler that pushes this file past the marker window.
// padding line 174 — inert filler that pushes this file past the marker window.
// padding line 175 — inert filler that pushes this file past the marker window.
// padding line 176 — inert filler that pushes this file past the marker window.
// padding line 177 — inert filler that pushes this file past the marker window.
// padding line 178 — inert filler that pushes this file past the marker window.
// padding line 179 — inert filler that pushes this file past the marker window.
// padding line 180 — inert filler that pushes this file past the marker window.
// padding line 181 — inert filler that pushes this file past the marker window.
// padding line 182 — inert filler that pushes this file past the marker window.
// padding line 183 — inert filler that pushes this file past the marker window.
// padding line 184 — inert filler that pushes this file past the marker window.
// padding line 185 — inert filler that pushes this file past the marker window.
// padding line 186 — inert filler that pushes this file past the marker window.
// padding line 187 — inert filler that pushes this file past the marker window.
// padding line 188 — inert filler that pushes this file past the marker window.
// padding line 189 — inert filler that pushes this file past the marker window.
// padding line 190 — inert filler that pushes this file past the marker window.
// padding line 191 — inert filler that pushes this file past the marker window.
// padding line 192 — inert filler that pushes this file past the marker window.
// padding line 193 — inert filler that pushes this file past the marker window.
// padding line 194 — inert filler that pushes this file past the marker window.
// padding line 195 — inert filler that pushes this file past the marker window.
// padding line 196 — inert filler that pushes this file past the marker window.
// padding line 197 — inert filler that pushes this file past the marker window.
// padding line 198 — inert filler that pushes this file past the marker window.
// padding line 199 — inert filler that pushes this file past the marker window.
// padding line 200 — inert filler that pushes this file past the marker window.
// padding line 201 — inert filler that pushes this file past the marker window.
// padding line 202 — inert filler that pushes this file past the marker window.
// padding line 203 — inert filler that pushes this file past the marker window.
// padding line 204 — inert filler that pushes this file past the marker window.
// padding line 205 — inert filler that pushes this file past the marker window.
// padding line 206 — inert filler that pushes this file past the marker window.
// padding line 207 — inert filler that pushes this file past the marker window.
// padding line 208 — inert filler that pushes this file past the marker window.
// padding line 209 — inert filler that pushes this file past the marker window.
// padding line 210 — inert filler that pushes this file past the marker window.
// padding line 211 — inert filler that pushes this file past the marker window.
// padding line 212 — inert filler that pushes this file past the marker window.
// padding line 213 — inert filler that pushes this file past the marker window.
// padding line 214 — inert filler that pushes this file past the marker window.
// padding line 215 — inert filler that pushes this file past the marker window.
// padding line 216 — inert filler that pushes this file past the marker window.
// padding line 217 — inert filler that pushes this file past the marker window.
// padding line 218 — inert filler that pushes this file past the marker window.
// padding line 219 — inert filler that pushes this file past the marker window.
// padding line 220 — inert filler that pushes this file past the marker window.
// padding line 221 — inert filler that pushes this file past the marker window.
// padding line 222 — inert filler that pushes this file past the marker window.
// padding line 223 — inert filler that pushes this file past the marker window.
// padding line 224 — inert filler that pushes this file past the marker window.
// padding line 225 — inert filler that pushes this file past the marker window.
// padding line 226 — inert filler that pushes this file past the marker window.
// padding line 227 — inert filler that pushes this file past the marker window.
// padding line 228 — inert filler that pushes this file past the marker window.
// padding line 229 — inert filler that pushes this file past the marker window.
// padding line 230 — inert filler that pushes this file past the marker window.
// padding line 231 — inert filler that pushes this file past the marker window.
// padding line 232 — inert filler that pushes this file past the marker window.
// padding line 233 — inert filler that pushes this file past the marker window.
// padding line 234 — inert filler that pushes this file past the marker window.
// padding line 235 — inert filler that pushes this file past the marker window.
// padding line 236 — inert filler that pushes this file past the marker window.
// padding line 237 — inert filler that pushes this file past the marker window.
// padding line 238 — inert filler that pushes this file past the marker window.
// padding line 239 — inert filler that pushes this file past the marker window.
// padding line 240 — inert filler that pushes this file past the marker window.
// padding line 241 — inert filler that pushes this file past the marker window.
// padding line 242 — inert filler that pushes this file past the marker window.
// padding line 243 — inert filler that pushes this file past the marker window.
// padding line 244 — inert filler that pushes this file past the marker window.
// padding line 245 — inert filler that pushes this file past the marker window.
// padding line 246 — inert filler that pushes this file past the marker window.
// padding line 247 — inert filler that pushes this file past the marker window.
// padding line 248 — inert filler that pushes this file past the marker window.
// padding line 249 — inert filler that pushes this file past the marker window.
// padding line 250 — inert filler that pushes this file past the marker window.
// padding line 251 — inert filler that pushes this file past the marker window.
// padding line 252 — inert filler that pushes this file past the marker window.
// padding line 253 — inert filler that pushes this file past the marker window.
// padding line 254 — inert filler that pushes this file past the marker window.
// padding line 255 — inert filler that pushes this file past the marker window.
// padding line 256 — inert filler that pushes this file past the marker window.
// padding line 257 — inert filler that pushes this file past the marker window.
// padding line 258 — inert filler that pushes this file past the marker window.
// padding line 259 — inert filler that pushes this file past the marker window.
