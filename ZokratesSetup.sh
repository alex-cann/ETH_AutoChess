zokrates.exe compile -i main.zok -o main --light --stdlib-path "..\zokrates\zokrates_stdlib"
zokrates.exe setup -i main --light
zokrates.exe export-verifier 